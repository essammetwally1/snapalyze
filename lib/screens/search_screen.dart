import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:snapalyze/components/photo_item.dart';
import 'package:snapalyze/models/photo_model.dart';
import 'package:snapalyze/providers/pexels_provider.dart';
import 'package:snapalyze/services/pexels_service.dart';
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

  bool loadMore = false;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _deb?.cancel();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _clear() {
    controller.clear();
    setState(() {});
  }

  void onChange(String value) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 400), () {
      final PexelsProvider pexelsProvider = Provider.of<PexelsProvider>(
        context,
        listen: false,
      );
      pexelsProvider.search(value);
    });
    if (controller.text.length == 1 || controller.text.isEmpty) {
      setState(() {}); // keep your UI refresh behavior
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >
        scrollController.position.maxScrollExtent - 400) {
      final PexelsProvider pexelsProvider = Provider.of<PexelsProvider>(
        context,
        listen: false,
      );
      pexelsProvider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PexelsProvider pexelsProvider = Provider.of<PexelsProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Header with rounded bottom corners (kept from your code)
          Container(
            padding: EdgeInsets.only(bottom: 8),
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
                    onPressed: () => {
                      ScaffoldMessenger.of(context).clearSnackBars(),
                      Navigator.of(context).pop(),
                    },
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
                      focusNode: focus,
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

          if (pexelsProvider.isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const LinearProgressIndicator(color: AppTheme.primary),
            ),

          // Error / Empty
          if (pexelsProvider.errorMessage != null)
            Utilis.showErrorMessage(pexelsProvider.errorMessage)
          else if (!pexelsProvider.isLoading && pexelsProvider.photos.isEmpty)
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
              itemCount:
                  pexelsProvider.photos.length +
                  (pexelsProvider.isLoadingMore ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= pexelsProvider.photos.length) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final PhotoModel pexelItem = pexelsProvider.photos[index];
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
                  fontSize: 12,
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
