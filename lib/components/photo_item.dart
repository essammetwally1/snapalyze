import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:snapalyze/models/photo_model.dart';
import 'package:snapalyze/shared/app_theme.dart';
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
            fit: BoxFit.cover,
            placeholder: (c, _) =>
                Container(color: _parseColor(photo.avgColor)),
            errorWidget: (c, _, __) => const Icon(Icons.broken_image_rounded),
          ),
          // credit overlay bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ph :${photo.photographer}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall!.copyWith(color: AppTheme.primary),
                    ),
                  ),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(photo.url),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: AppTheme.primary,
                      shadows: [Shadow(color: AppTheme.white, blurRadius: 10)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: InkWell(
                onTap: () => {},
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

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return Colors.grey.shade300;
  }
}
