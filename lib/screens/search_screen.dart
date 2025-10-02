import 'package:flutter/material.dart';
import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/components/custom_textfeild.dart';

import '../components/image_item.dart';

class SearchScreen extends StatefulWidget {
  static const String routeName = '/searchscreen';
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // autofocus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    controller.clear();
    setState(() {});
    // _focus.requestFocus();
  }

  void onChange(value) => {
    if (controller.text.length == 1) {setState(() {})},
    if (controller.text.isEmpty) setState(() {}),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with rounded bottom corners
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
                  SizedBox(width: 20),
                ],
              ),
            ),
          ),

          // Grid body
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // two per row
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1, // square tiles
              ),
              itemCount: 100, // show any count you like
              itemBuilder: (context, index) {
                return ImageItem(
                  imagePath: 'assets/image.jpg',
                  onTap: () {
                    // TODO: handle open details / preview
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
