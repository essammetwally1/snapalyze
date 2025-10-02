import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:snapalyze/shared/app_theme.dart';
import 'package:snapalyze/models/pickedimage_model.dart';

class AnalysisScreen extends StatefulWidget {
  static const String routeName = '/analysis';

  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Future<Size> getImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final fi = await codec.getNextFrame();
    return Size(fi.image.width.toDouble(), fi.image.height.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final PickedimageModel image =
        ModalRoute.of(context)!.settings.arguments as PickedimageModel;
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
          "Analysis Results",
          style: textTheme.titleLarge?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image Section
            FutureBuilder<Size>(
              future: getImageSize(image.pickedImage),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return SizedBox(
                    width: size.width * 0.7,
                    height: size.height * 0.4,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                final ar = snap.data!.width / snap.data!.height;

                return Container(
                  width: size.width * 0.7,
                  // height scales automatically from AspectRatio
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
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: AspectRatio(
                      aspectRatio: ar,
                      child: Image.file(
                        image.pickedImage,
                        fit: BoxFit.contain,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 250),
                                child: frame == null
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : child,
                              );
                            },
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(
                            'Failed to load image',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppTheme.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Results Section
            _buildResultsSection(image, textTheme, size),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(
    PickedimageModel image,
    TextTheme textTheme,
    Size size,
  ) {
    if (image.results.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No analysis results available',
            style: textTheme.bodyLarge?.copyWith(color: AppTheme.black),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analysis Data Card
        _buildAnalysisCard(image.results['analysis'], textTheme),
        const SizedBox(height: 20),

        // Suggestions Card
        if (image.results['suggestions'] != null)
          _buildSuggestionsCard(image.results['suggestions'], textTheme),

        // Add some bottom padding for better scrolling
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAnalysisCard(
    Map<String, dynamic>? analysis,
    TextTheme textTheme,
  ) {
    if (analysis == null) return const SizedBox();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: BoxBorder.all(color: AppTheme.primary, width: 1),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Technical Analysis',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...analysis.entries.map(
              (entry) => _buildAnalysisRow(
                entry.key,
                entry.value.toString(),
                textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String title, String value, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatTitle(title),
              style: textTheme.titleMedium?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: AppTheme.primary, blurRadius: 1)],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary),
              ),
              child: Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(
    List<dynamic>? suggestions,
    TextTheme textTheme,
  ) {
    if (suggestions == null || suggestions.isEmpty) return const SizedBox();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: BoxBorder.all(color: AppTheme.primary, width: 1),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Suggestions & Tips',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: suggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final suggestion = entry.value.toString();
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: BoxBorder.all(
                              color: AppTheme.primary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            suggestion,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppTheme.black,
                              shadows: [
                                Shadow(color: AppTheme.primary, blurRadius: 1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTitle(String title) {
    return title
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
