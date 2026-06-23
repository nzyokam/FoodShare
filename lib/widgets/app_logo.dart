import 'package:flutter/material.dart';

/// Switches between light-mode.png and dark-mode.png based on the active theme.
/// Works with both system theme and the custom pitch-black dark theme.
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppLogo({super.key, this.width, this.height, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'lib/assets/dark-mode.png' : 'lib/assets/light-mode.png',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
