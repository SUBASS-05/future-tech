import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

class FTCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  
  const FTCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FTSpacing.md),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FTRadius.large),
        side: const BorderSide(color: FTColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FTRadius.large),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
