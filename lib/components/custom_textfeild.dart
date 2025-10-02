import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snapalyze/shared/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String? hintText;
  final String? iconPathName;
  final TextEditingController? controller;
  final void Function(String)? onChange;
  final VoidCallback? onPressed;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool isPassword;
  final bool isEmail;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    this.hintText,
    this.iconPathName,
    this.controller,
    this.onChange,
    this.maxLines = 1,
    this.validator,
    this.onPressed,
    this.onTap,
    this.readOnly = false,
    this.isPassword = false,
    this.isEmail = false,
    this.suffixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _showPassword = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.grey.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextFormField(
          validator: widget.validator,
          maxLines: widget.maxLines,
          controller: widget.controller,
          obscureText: widget.isPassword ? _showPassword : false,
          keyboardType: widget.isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          onChanged: widget.onChange,
          onTap: widget.onTap,
          onTapOutside: (_) {
            _focusNode.unfocus();
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          cursorColor: AppTheme.white,
          style: Theme.of(context).textTheme.titleMedium,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: widget.hintText,

            contentPadding: EdgeInsets.symmetric(
              vertical: size.width / 24,
              horizontal: 12,
            ),

            suffixIcon: widget.isPassword
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      icon: _showPassword
                          ? Icon(
                              Icons.visibility_off_outlined,
                              color: AppTheme.white.withValues(alpha: .7),
                              size: 20,
                            )
                          : Icon(
                              Icons.visibility_outlined,
                              color: AppTheme.white.withValues(alpha: .7),
                              size: 20,
                            ),
                    ),
                  )
                : widget.suffixIcon,

            prefixIcon: widget.iconPathName == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: SvgPicture.asset(
                      'assets/icons/${widget.iconPathName}.svg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.scaleDown,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
