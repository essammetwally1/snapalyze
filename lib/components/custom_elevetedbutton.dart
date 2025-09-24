import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snapalyze/app_theme.dart';

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
        fixedSize: Size(width ?? size.width, height ?? size.width / 8),
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        elevation: 0,
        shadowColor: isGoogleButton
            ? AppTheme.grey.withValues(alpha: .4)
            : null,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2))
          : isGoogleButton
          ? _buildGoogleButtonContent(context)
          : Text(
              text,
              style: textStyle ?? Theme.of(context).textTheme.titleMedium,
            ),
    );
  }

  Widget _buildGoogleButtonContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google "G" logo with better styling
        SvgPicture.asset(
          'assets/google.svg',
          width: 24,
          height: 24,
          fit: BoxFit.cover,
        ),
        SizedBox(width: 12),
        Text(text, style: textStyle ?? Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
