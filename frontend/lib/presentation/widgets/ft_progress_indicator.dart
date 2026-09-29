import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

class FTProgressIndicator extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;

  const FTProgressIndicator({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: backgroundColor ?? FTColors.border,
      color: color ?? FTColors.primary,
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
