import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

class FTAvatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final Widget? fallbackIcon;

  const FTAvatar({
    super.key,
    this.radius = 50,
    this.imageUrl,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: FTColors.primaryLight,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null 
          ? (fallbackIcon ?? const Icon(Icons.person, color: FTColors.primary)) 
          : null,
    );
  }
}
