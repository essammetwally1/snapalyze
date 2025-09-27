import 'dart:io';
import 'package:flutter/material.dart';
import 'package:snapalyze/app_theme.dart';

class AnalysisScreen extends StatelessWidget {
  static const String routeName = '/analysis';
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final File pickedImage = ModalRoute.of(context)!.settings.arguments as File;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Analysis",
          style: textTheme.titleLarge?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 4,
      ),

      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20), // spacing from AppBar
          Center(
            child: Container(
              width: size.width * 0.7,
              height: size.height * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 100,
                  ),
                  BoxShadow(
                    color: AppTheme.black.withValues(alpha: 0.4),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.file(
                  pickedImage,
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
