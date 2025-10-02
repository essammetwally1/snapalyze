import 'package:flutter/material.dart';

class ImageItem extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;

  const ImageItem({super.key, required this.imagePath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Ink.image(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
    );
  }
}
