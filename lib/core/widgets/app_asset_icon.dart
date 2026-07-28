import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Modern Icons8 Asset Widget with Tinting and Fallback
class AppAssetIcon extends StatelessWidget {
  final String iconName;
  final IconData fallbackIcon;
  final double? size;
  final Color? color;
  final BoxFit fit;

  const AppAssetIcon({
    super.key,
    required this.iconName,
    required this.fallbackIcon,
    this.size,
    this.color,
    this.fit = BoxFit.contain,
  });

  String get assetPath => 'assets/icons/$iconName.png';

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 22.r;

    return Image.asset(
      assetPath,
      width: iconSize,
      height: iconSize,
      color: color,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to crisp outline material icon if asset is not present
        return Icon(
          fallbackIcon,
          size: iconSize,
          color: color,
        );
      },
    );
  }
}
