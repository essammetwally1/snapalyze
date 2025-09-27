import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/components/home_drawer.dart';
import 'package:snapalyze/models/pickedimage_model.dart';
import 'package:snapalyze/models/user_model.dart';
import 'package:snapalyze/providers/user_provider.dart';
import 'package:snapalyze/screens/analysis_screen.dart';
import 'package:snapalyze/services/analysis_service.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? analysisResults;
  File? _pickedImage;
  bool isLoading = false;

  Future<void> _analyzeImage(File pickedImage) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      analysisResults = null; // clear old
      final results = await AnalysisService.analyzeImage(pickedImage);

      final pickedimageModel = PickedimageModel(
        pickedImage: pickedImage,
        results: results, // still a Map<String, dynamic>
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamed(AnalysisScreen.routeName, arguments: pickedimageModel);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to analyze image: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel user = Provider.of<UserProvider>(context).currentUser!;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: HomeDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: size.height * 0.1,
        title: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Row(
                children: [
                  CircleAvatar(
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
                ],
              ),
            );
          },
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
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary, width: 3),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: .2),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppTheme.black.withValues(alpha: .1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    color: const Color.fromARGB(195, 201, 222, 240),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedImage == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 📂 Gallery Button
                              SizedBox(
                                width: size.width * .6,
                                height: 55,
                                child: _elevetedButton(
                                  text: "Pick from Gallery",
                                  icon: Icon(Icons.photo_library),
                                  textTheme: textTheme,
                                  onPressed: () =>
                                      pickImage(ImageSource.gallery),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 📷 Camera Button
                              SizedBox(
                                width: size.width * .6,
                                height: 55,
                                child: _elevetedButton(
                                  text: "Take a Photo",
                                  icon: Icon(Icons.camera_alt),
                                  textTheme: textTheme,
                                  onPressed: () =>
                                      pickImage(ImageSource.camera),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.file(
                            _pickedImage!,
                            fit: BoxFit.fill,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _pickedImage != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: _elevetedButton(
                            text: 'Gallery',
                            icon: Icon(
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
                            icon: Icon(
                              Icons.camera_alt,
                              color: AppTheme.primary,
                            ),
                            onPressed: () => pickImage(ImageSource.camera),
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox(),

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
                          onPressed: () {
                            _analyzeImage(_pickedImage!);
                          },
                          text: 'Analyze Image',
                          icon: Icon(
                            Icons.analytics,
                            size: 32,
                            color: AppTheme.white,
                          ),
                        ),
                        _serviceButton(
                          textTheme: textTheme,
                          onPressed: () {},
                          text: 'Find Similar',
                          icon: Icon(
                            Icons.search,
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
    required final VoidCallback onPressed,
    required final String text,
    required final Icon icon,
  }) {
    return Expanded(
      child: Container(
        height: 120,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: AppTheme.black, blurRadius: 5)],
        ),
        child: InkWell(
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(height: 8),
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
