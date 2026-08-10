import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

// ── Tab data model ────────────────────────────────────────────────────────────

class _TabData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _tabs = [
  _TabData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: AppStrings.home,
  ),
  _TabData(
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment_rounded,
    label: AppStrings.assessments,
  ),
  _TabData(
    icon: Icons.history_outlined,
    activeIcon: Icons.history_rounded,
    label: AppStrings.history,
  ),
  _TabData(
    icon: Icons.local_hospital_outlined,
    activeIcon: Icons.local_hospital_rounded,
    label: AppStrings.clinic,
  ),
];

// ── Floating pill nav bar ─────────────────────────────────────────────────────

/// A floating, pill-shaped bottom navigation bar.
///
/// Sits above the screen bottom edge with horizontal + vertical margin.
/// The active tab shows a bright pill indicator behind the icon/label.
/// All transitions (pill position, icon swap, label weight) are animated.
class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  double _pillFrom = 0;

  @override
  void initState() {
    super.initState();
    _pillFrom = widget.currentIndex.toDouble();
  }

  @override
  void didUpdateWidget(BottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _pillFrom = old.currentIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Outer padding gives the "floating" effect — space from screen edges.
    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _FloatingPill(
            currentIndex: widget.currentIndex,
            pillFrom: _pillFrom,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

// ── Pill container ────────────────────────────────────────────────────────────

class _FloatingPill extends StatelessWidget {
  final int currentIndex;
  final double pillFrom;
  final ValueChanged<int> onTap;

  const _FloatingPill({
    required this.currentIndex,
    required this.pillFrom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const tabCount = 4;
    const barH    = 62.0;
    const navBg   = Color(0xFF2563EB); // app blue

    return Container(
      height: barH,
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: BorderRadius.circular(barH / 2),
        boxShadow: [
          // Ambient shadow
          BoxShadow(
            color: const Color(0xFF172554).withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          // Tight shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(barH / 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabW = constraints.maxWidth / tabCount;

            // Active pill indicator dimensions
            const pillH  = 42.0;
            const pillW  = 76.0;

            return TweenAnimationBuilder<double>(
              tween: Tween(
                begin: pillFrom,
                end: currentIndex.toDouble(),
              ),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              builder: (context, animPos, _) {
                final pillLeft = animPos * tabW + (tabW - pillW) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Animated active pill ─────────────────────────────
                    Positioned(
                      left: pillLeft,
                      top: (barH - pillH) / 2,
                      child: Container(
                        width: pillW,
                        height: pillH,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(pillH / 2),
                        ),
                      ),
                    ),

                    // ── Tab items ────────────────────────────────────────
                    Row(
                      children: List.generate(tabCount, (i) {
                        return _NavItem(
                          data: _tabs[i],
                          isActive: i == currentIndex,
                          tabWidth: tabW,
                          barHeight: barH,
                          onTap: () => onTap(i),
                        );
                      }),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Individual tab item ───────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _TabData data;
  final bool isActive;
  final double tabWidth;
  final double barHeight;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.tabWidth,
    required this.barHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Active: navy text/icons to contrast against white pill
    // Inactive: white at 70% so they're visible on blue bg
    final activeColor   = const Color(0xFF1E3A8A);
    final inactiveColor = Colors.white.withValues(alpha: 0.75);
    final color         = isActive ? activeColor : inactiveColor;

    return Semantics(
      label: data.label,
      button: true,
      selected: isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: tabWidth,
          height: barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon — scale up + cross-fade on activation
              AnimatedScale(
                scale: isActive ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    isActive ? data.activeIcon : data.icon,
                    key: ValueKey(isActive),
                    size: 20,
                    color: color,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              // Label — smooth weight + colour transition
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Inter',
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                  letterSpacing: isActive ? 0.3 : 0,
                ),
                child: Text(data.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
