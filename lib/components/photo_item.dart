import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:snapalyze/models/photo_model.dart';
import 'package:snapalyze/shared/app_theme.dart';
import 'package:snapalyze/shared/utilis.dart';
import 'package:url_launcher/url_launcher.dart';

class PhotoItem extends StatelessWidget {
  final PhotoModel photo;
  final String imageUrl;
  const PhotoItem({super.key, required this.photo, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.fill,
            placeholder: (c, _) =>
                Container(color: _parseColor(photo.avgColor)),
            errorWidget: (c, _, __) => const Icon(Icons.broken_image_rounded),
          ),

          // credit overlay bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse(photo.url),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ph : ${photo.photographer}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: AppTheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: AppTheme.primary,
                      shadows: [Shadow(color: AppTheme.white, blurRadius: 10)],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // save button (top-right)
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              onTap: () => _showSaveSnackBar(context),
              child: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.save_alt_outlined,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI: primary-styled SnackBar with size options ----------
  void _showSaveSnackBar(BuildContext context) {
    final choices = <_Choice>[
      _Choice('Original', photo.src.original),
      _Choice('Large2x', photo.src.large2x),
      _Choice('Large', photo.src.large),
      _Choice('Medium', photo.src.medium),
      _Choice('Small', photo.src.small),
      _Choice('Portrait', photo.src.portrait),
      _Choice('Landscape', photo.src.landscape),
      _Choice('Tiny', photo.src.tiny),
    ].where((c) => c.url.isNotEmpty).toList();

    if (choices.isEmpty) {
      Utilis.showErrorMessage('No downloadable sizes found');
      return;
    }

    final bar = SnackBar(
      duration: const Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.primary,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Save image as…',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                },
                icon: Icon(Icons.close_rounded, color: AppTheme.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: choices.map((c) {
              return OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: const StadiumBorder(),
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  final fileName =
                      'pexels_${photo.id}_${c.label.toLowerCase()}';
                  await _saveFromUrl(context, c.url, filename: fileName);
                },
                child: Text(
                  c.label,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(bar);
  }

  // ---------- Download + Save ----------
  Future<void> _saveFromUrl(
    BuildContext context,
    String url, {
    required String filename,
  }) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw 'Download failed (${res.statusCode})';

      final Uint8List bytes = res.bodyBytes;

      // choose an extension (helps gallery preview); fallback jpg
      final ext =
          _detectExtFromUrl(url) ?? _detectExtFromHeaders(res.headers) ?? 'jpg';

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 95,
        name: '$filename.$ext',
      );

      final ok =
          (result is Map &&
          (result['isSuccess'] == true || result['filePath'] != null));
      if (ok) {
        Utilis.showSuccessMessage('Saved to gallery');
      } else {
        Utilis.showErrorMessage('Save failed');
      }
    } catch (_) {
      Utilis.showErrorMessage('Save failed');
    }
  }

  String? _detectExtFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.png')) return 'png';
    if (lower.contains('.webp')) return 'webp';
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return 'jpg';
    return null;
  }

  String? _detectExtFromHeaders(Map<String, String> h) {
    final ct = h['content-type']?.toLowerCase();
    if (ct == null) return null;
    if (ct.contains('png')) return 'png';
    if (ct.contains('webp')) return 'webp';
    if (ct.contains('jpeg') || ct.contains('jpg')) return 'jpg';
    return null;
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return Colors.grey.shade300;
  }
}

class _Choice {
  final String label;
  final String url;
  const _Choice(this.label, this.url);
}
