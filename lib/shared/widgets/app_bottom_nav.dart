import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _iconControllers;

  final _tabs = const [
    _TabItem(icon: Icons.home_rounded, label: 'Home'),
    _TabItem(
        icon: Icons.receipt_long_rounded,
        label: 'Transactions',
        short: 'History'),
    _TabItem(icon: Icons.add_circle_rounded, label: 'Add', isFab: true),
    _TabItem(icon: Icons.bar_chart_rounded, label: 'Analytics', short: 'Stats'),
    _TabItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      _tabs.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );
    if (widget.currentIndex < _iconControllers.length) {
      _iconControllers[widget.currentIndex].value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _iconControllers[old.currentIndex].reverse();
      _iconControllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    // Sit above the system navigation bar: ~48dp with 3-button navigation,
    // ~16dp with gestures. Edge-to-edge is enforced on Android 15+.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final bg = Theme.of(context).scaffoldBackgroundColor;

    // The bar floats, so fade the page out behind it and the gap beneath it;
    // otherwise list content shows through under the bar.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg.withValues(alpha: 0), bg.withValues(alpha: 0.92), bg],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              // Equal-width slots keep the + exactly centred, and every tab
              // always shows its label so all icons sit on one baseline.
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final controller = _iconControllers[i];

                  if (tab.isFab) {
                    return Expanded(
                      child: Center(
                        child: _FabButton(
                          onTap: () => widget.onTap(i),
                          accent: accent,
                        ),
                      ),
                    );
                  }

                  final idle = isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5);
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == widget.currentIndex,
                      label: tab.label,
                      child: GestureDetector(
                        onTap: () => widget.onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) {
                            final t = controller.value;
                            final color = Color.lerp(idle, accent, t)!;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(tab.icon, size: 24, color: color),
                                const SizedBox(height: 4),
                                Text(
                                  tab.shortLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: t > 0.5
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FabButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color accent;

  const _FabButton({required this.onTap, required this.accent});

  @override
  State<_FabButton> createState() => _FabButtonState();
}

class _FabButtonState extends State<_FabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final scale = 1.0 + _pulseController.value * 0.04;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.accent, widget.accent.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;

  /// Fits under the icon in a fifth of the bar.
  final String? short;
  final bool isFab;

  const _TabItem({
    required this.icon,
    required this.label,
    this.short,
    this.isFab = false,
  });

  String get shortLabel => short ?? label;
}
