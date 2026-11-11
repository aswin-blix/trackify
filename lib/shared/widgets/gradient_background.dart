import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import 'hud.dart';

/// Paints the app's themed background gradient behind [child].
///
/// Tab screens inside [HomeShell] get this from the shell; screens pushed as
/// standalone routes (Budget, Tips) wrap themselves in it.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (AppFonts.hud) return HudBackdrop(child: child);
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? darkBackgroundGradient() : lightBackgroundGradient(),
      ),
      child: child,
    );
  }
}
