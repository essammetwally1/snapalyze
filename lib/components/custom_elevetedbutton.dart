import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final bool isGoogleButton;

  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.textStyle,
    this.width,
    this.height,
    this.borderRadius,
    this.isGoogleButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor.withValues(alpha: .05),
        foregroundColor: foregroundColor.withValues(alpha: .8),
        fixedSize: Size(width ?? size.width, height ?? 55),
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Text(
              text,
              style: textStyle ?? Theme.of(context).textTheme.titleMedium,
            ),
    );
  }
}
