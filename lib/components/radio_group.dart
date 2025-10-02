// ===== RadioGroup shim (no deprecated APIs; same visual style) =====
import 'package:flutter/material.dart';
import 'package:snapalyze/shared/app_theme.dart';

class RadioOption<T> {
  final T value;
  final Widget label;
  const RadioOption({required this.value, required this.label});
}

class RadioGroup<T> extends StatelessWidget {
  final T value;
  final ValueChanged<T?>? onChanged;
  final List<RadioOption<T>> children;

  const RadioGroup.row({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: children.map((opt) {
        final selected = opt.value == value;
        final disabled = onChanged == null;

        final tile = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: disabled ? theme.disabledColor : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            DefaultTextStyle.merge(
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
              child: opt.label,
            ),
          ],
        );

        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: disabled ? null : () => onChanged?.call(opt.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: tile,
            ),
          ),
        );
      }).toList(),
    );
  }
}
