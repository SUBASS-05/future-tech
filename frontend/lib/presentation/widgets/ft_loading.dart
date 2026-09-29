import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

class FTLoading extends StatelessWidget {
  final Color? color;
  const FTLoading({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? FTColors.primary,
      ),
    );
  }
}
