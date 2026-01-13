import 'package:flutter/material.dart';

class LogoIcon extends StatelessWidget {
  final bool isSelected;
  final double size;
  final String logoType; // 'light', 'dark', 'white', 'dark_logo', 'white_logo'

  const LogoIcon({
    super.key,
    this.isSelected = false,
    this.size = 24,
    this.logoType = 'light',
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFFFF4500) : Colors.grey;

    // Determine which logo to use based on logoType
    String assetPath;
    switch (logoType) {
      case 'dark':
        assetPath = 'assets/logos/dark.png';
        break;
      case 'dark_logo':
        assetPath = 'assets/logos/dark_logo.png';
        break;
      case 'white':
        assetPath = 'assets/logos/white_logo.png';
        break;
      case 'white_logo':
        assetPath = 'assets/logos/white_logo.png';
        break;
      case 'light':
      default:
        assetPath = 'assets/logos/light.png';
        break;
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to home icon if logo fails to load
        return Icon(
          Icons.home,
          color: color,
          size: size,
        );
      },
    );
  }
}
