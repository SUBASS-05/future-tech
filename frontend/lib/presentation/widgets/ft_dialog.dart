import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

class FTDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const FTDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FTColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FTRadius.large),
      ),
      title: Text(
        title,
        style: FTTypography.heading3,
      ),
      content: content,
      actions: actions,
    );
  }
}
