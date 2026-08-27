import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snowtrak/core/theme.dart';

/// Names of the brand icons in `assets/icons/` (the Snowtrak Icon Suite).
///
/// Only the ones the app actually draws are listed; the folder holds all 51.
class StIcons {
  static const String home = 'home';
  static const String map = 'map-navigation';
  static const String community = 'community';
  static const String messageChat = 'message-chat';
  static const String profile = 'profile-you';
  static const String search = 'search';
  static const String bell = 'bell';
  static const String bellNotification = 'bell-notification';
  static const String menu = 'menu-hamburger';
  static const String settings = 'settings';
  static const String ski = 'ski';
  static const String speedometer = 'speedometer';
  static const String activity = 'activity';
  static const String lightning = 'lighting';
  static const String lightningSpeed = 'lighting-speed';
  static const String pin = 'pin-location';
  static const String heart = 'heart';
  static const String message = 'message';
  static const String share = 'send-share';
  static const String target = 'target-goal';
  static const String filter = 'filter-funnel';
  static const String bookmark = 'bookmark-save';
  static const String logomark = 'logomark';
}

/// A brand icon. SVGs use `currentColor`, so [color] tints the whole glyph.
class StIcon extends StatelessWidget {
  const StIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? SnowtrakColors.textSecondary,
        BlendMode.srcIn,
      ),
    );
  }
}
