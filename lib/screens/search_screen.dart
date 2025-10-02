import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snapalyze/components/photo_item.dart';
import 'package:snapalyze/models/photo_model.dart';
import 'package:snapalyze/services/pixils_service.dart';
import 'package:snapalyze/shared/app_theme.dart';
import 'package:snapalyze/components/custom_textfeild.dart';
import 'package:snapalyze/shared/utilis.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  static const String routeName = '/searchscreen';
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focus = FocusNode();
  final ScrollController scrollController = ScrollController();
  final PexelsService pexelsService = PexelsService();

  Timer? _deb;

  bool _loading = false;
  bool loadMore = false;
  String? _error;
  String _query = '';
  int _page = 1;
  bool _hasNext = true;

  final List<PhotoModel> pexelsItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focus.requestFocus();
      _loadCurated();
    });
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _deb?.cancel();
    controller.dispose();
    focus.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _clear() {
    controller.clear();
    setState(() {});
    _search(''); // back to curated
  }

  void onChange(String value) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 400), () {
      _search(value.trim());
    });
    if (controller.text.length == 1 || controller.text.isEmpty) {
      setState(() {}); // keep your UI refresh behavior
    }
  }

  Future<void> _loadCurated() async {
    setState(() {
      _loading = true;
      _error = null;
      pexelsItems.clear();
      _page = 1;
      _hasNext = true;
      _query = '';
    });
    try {
      final PexelsSearchResponse response = await pexelsService.curated(
        page: 1,
        perPage: 40,
      );
      setState(() {
        pexelsItems.addAll(response.photos);
        _page = response.page;
        _hasNext = (response.nextPage != null) && response.photos.isNotEmpty;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load photos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return _loadCurated();

    setState(() {
      _loading = true;
      _error = null;
      pexelsItems.clear();
      _page = 1;
      _hasNext = true;
      _query = query;
    });
    try {
      final res = await pexelsService.search(query, page: 1, perPage: 40);
      setState(() {
        pexelsItems.addAll(res.photos);
        _page = res.page;
        _hasNext = (res.nextPage != null) && res.photos.isNotEmpty;
      });
    } catch (e) {
      setState(() => _error = 'Search failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (loadMore || !_hasNext) return;
    setState(() => loadMore = true);
    try {
      final next = _page + 1;
      final res = _query.isEmpty
          ? await pexelsService.curated(page: next, perPage: 40)
          : await pexelsService.search(_query, page: next, perPage: 40);
      setState(() {
        pexelsItems.addAll(res.photos);
        _page = res.page;
        _hasNext = (res.nextPage != null) && res.photos.isNotEmpty;
      });
    } catch (_) {
      // swallow or show a toast
    } finally {
      if (mounted) setState(() => loadMore = false);
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >
        scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with rounded bottom corners (kept from your code)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppTheme.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: controller,
                      iconPathName: 'search',
                      hintText: 'Search...',
                      onChange: onChange,
                      suffixIcon: (controller.text.isNotEmpty)
                          ? IconButton(
                              onPressed: _clear,
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),

          if (_loading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const LinearProgressIndicator(color: AppTheme.primary),
            ),

          // Error / Empty
          if (_error != null)
            Utilis.showErrorMessage(_error)
          else if (!_loading && pexelsItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 100,
              ),
              child: SvgPicture.asset(
                fit: BoxFit.cover,
                'assets/icons/noImage.svg',
                width: 150,
                height: 150,
                colorFilter: const ColorFilter.mode(
                  AppTheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),

          // Grid body (2 images per row)
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 6,
                childAspectRatio: .6,
              ),
              itemCount: pexelsItems.length + (loadMore ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= pexelsItems.length) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final PhotoModel pexelItem = pexelsItems[index];
                final imageUrl = pexelItem.src.medium.isNotEmpty
                    ? pexelItem.src.medium
                    : (pexelItem.src.small.isNotEmpty
                          ? pexelItem.src.small
                          : pexelItem.src.tiny);
                return PhotoItem(photo: pexelItem, imageUrl: imageUrl);
              },
            ),
          ),

          // Required attribution (Pexels guideline)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://www.pexels.com'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                'Photos provided by Pexels',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: AppTheme.primary,
                  decoration:
                      TextDecoration.underline, // underline for link style
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
