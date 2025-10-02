import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/components/home_drawer.dart';
import 'package:snapalyze/models/pickedimage_model.dart';
import 'package:snapalyze/models/user_model.dart';
import 'package:snapalyze/providers/user_provider.dart';
import 'package:snapalyze/screens/analysis_screen.dart';
import 'package:snapalyze/screens/resize_screen.dart';
import 'package:snapalyze/screens/search_screen.dart';
import 'package:snapalyze/services/analysis_service.dart';
import 'package:snapalyze/utilis.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? analysisResults;
  File? _pickedImage;
  Size? _pickedImageSize; // cache intrinsic size once
  bool isLoadingAnalyze = false;
  bool isLoadingResize = false;

  Future<void> _analyzeImage(File pickedImage) async {
    if (isLoadingAnalyze) return;
    setState(() => isLoadingAnalyze = true);
    try {
      analysisResults = null;
      final results = await AnalysisService.analyzeImage(pickedImage);
      final pickedimageModel = PickedimageModel(
        pickedImage: pickedImage,
        results: results,
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamed(AnalysisScreen.routeName, arguments: pickedimageModel);
    } catch (e) {
      if (!mounted) return;
      Utilis.showErrorMessage('Failed to analyze image: $e');
    } finally {
      if (mounted) setState(() => isLoadingAnalyze = false);
    }
  }

  Future<void> _resizeImage(File pickedImage) async {
    setState(() {
      isLoadingResize = true;
    });
    final results = await AnalysisService.analyzeImage(_pickedImage!);
    final pickedimageModel = PickedimageModel(
      pickedImage: _pickedImage!,
      results: results,
    );
    if (!mounted) return;
    setState(() {
      isLoadingResize = false;
      Navigator.of(
        context,
      ).pushNamed(ResizeScreen.routeName, arguments: pickedimageModel);
    });
  }

  Future<Size> _decodeImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final fi = await codec.getNextFrame();
    return Size(fi.image.width.toDouble(), fi.image.height.toDouble());
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      // decode once and cache
      final size = await _decodeImageSize(file);
      if (!mounted) return;
      setState(() {
        _pickedImage = file;
        _pickedImageSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = Provider.of<UserProvider>(context).currentUser;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Size size = MediaQuery.of(context).size;

    if (user == null) {
      // Show a loading indicator or redirect to login screen
      return const Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      drawer: const HomeDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: size.height * 0.1,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Builder(
                builder: (context) => InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.white,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: AssetImage(
                        'assets/avatar/${user.gender}.png',
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'snapalyze',
                    style: textTheme.labelSmall!.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'FjallaOne',
                      decorationColor: AppTheme.primary,
                      shadows: [
                        Shadow(color: AppTheme.white, blurRadius: 40),
                        Shadow(color: AppTheme.white, blurRadius: 10),
                        Shadow(color: AppTheme.white, blurRadius: 10),
                        Shadow(color: AppTheme.white, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () =>
                    Navigator.of(context).pushNamed(SearchScreen.routeName),
                child: SvgPicture.asset('assets/icons/search.svg'),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 📸 Image Section (60%)
            Expanded(
              flex: 6,
              child: Center(
                child: Container(
                  height: size.height * 0.6,
                  margin: const EdgeInsets.all(16),
                  // Use outer container only for spacing/background if you like
                  // No border/shadow here, the frame will be drawn around the image exactly
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _pickedImage == null
                        ? const Color.fromARGB(195, 201, 222, 240)
                        : Colors.transparent,

                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _pickedImage == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: size.width * .6,
                                height: 55,
                                child: _elevetedButton(
                                  text: "Pick from Gallery",
                                  icon: const Icon(Icons.photo_library),
                                  textTheme: textTheme,
                                  onPressed: () =>
                                      pickImage(ImageSource.gallery),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: size.width * .6,
                                height: 55,
                                child: _elevetedButton(
                                  text: "Take a Photo",
                                  icon: const Icon(Icons.camera_alt),
                                  textTheme: textTheme,
                                  onPressed: () =>
                                      pickImage(ImageSource.camera),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: _framedImageFitted(
                            file: _pickedImage!,
                            imageSize: _pickedImageSize,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (_pickedImage != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: _elevetedButton(
                        text: 'Gallery',
                        icon: const Icon(
                          Icons.photo_library,
                          color: AppTheme.primary,
                        ),
                        onPressed: () => pickImage(ImageSource.gallery),
                        textTheme: textTheme,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: _elevetedButton(
                        textTheme: textTheme,
                        text: 'Camera',
                        icon: const Icon(
                          Icons.camera_alt,
                          color: AppTheme.primary,
                        ),
                        onPressed: () => pickImage(ImageSource.camera),
                      ),
                    ),
                  ),
                ],
              ),

            // 👋 Content Section (40%)
            Expanded(
              flex: 3,
              child: _pickedImage == null
                  ? Center(
                      child: Text(
                        'Pick an image to get started',
                        style: textTheme.titleLarge!.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: AppTheme.black, blurRadius: 2),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        _serviceButton(
                          textTheme: textTheme,
                          isLoading: isLoadingAnalyze,
                          onPressed: () => _analyzeImage(_pickedImage!),
                          text: 'Analyze Image',
                          icon: const Icon(
                            Icons.analytics,
                            size: 32,
                            color: AppTheme.white,
                          ),
                        ),
                        _serviceButton(
                          isLoading: isLoadingResize,
                          textTheme: textTheme,
                          onPressed: () => _resizeImage(_pickedImage!),
                          text: 'Resize Image',
                          icon: const Icon(
                            Icons.aspect_ratio,
                            size: 32,
                            color: AppTheme.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// One framed container that hugs the image’s displayed size (no nested borders).
  /// - Respects aspect ratio (scale = min(maxW/imgW, maxH/imgH))
  /// - Smooth first-frame fade-in
  Widget _framedImageFitted({required File file, required Size? imageSize}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (imageSize == null) {
          // Defensive: in the tiny window before _pickedImageSize is set
          return const Center(child: CircularProgressIndicator());
        }

        final imgW = imageSize.width;
        final imgH = imageSize.height;
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // scale to fit container while preserving aspect ratio
        final scale = (maxW / imgW < maxH / imgH)
            ? (maxW / imgW)
            : (maxH / imgH);
        final displayW = imgW * scale;
        final displayH = imgH * scale;

        return Center(
          child: Container(
            width: displayW,
            height: displayH,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary, width: 3),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: .5),
                  blurRadius: 100,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.file(
                file,
                fit: BoxFit.fill, // box already matches the aspect ratio
                filterQuality: FilterQuality.medium,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: frame == null
                        ? const Center(child: CircularProgressIndicator())
                        : child,
                  );
                },
                errorBuilder: (context, error, stack) => Center(
                  child: Text(
                    'Failed to load image',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppTheme.red),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _elevetedButton({
    required String text,
    required Icon icon,
    required TextTheme textTheme,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.primary, width: 3),
        ),
      ),
      icon: icon,
      label: Text(
        text,
        style: textTheme.titleMedium!.copyWith(color: AppTheme.primary),
      ),
      onPressed: onPressed,
    );
  }

  Widget _serviceButton({
    required TextTheme textTheme,
    required VoidCallback onPressed,
    required String text,
    required Icon icon,
    required bool isLoading,
  }) {
    return Expanded(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [BoxShadow(color: AppTheme.black, blurRadius: 5)],
        ),
        child: isLoading
            ? CircularProgressIndicator(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              )
            : InkWell(
                onTap: onPressed,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        color: AppTheme.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
