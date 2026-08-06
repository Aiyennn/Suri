import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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

// ── Bottom nav bar ────────────────────────────────────────────────────────────

/// Bottom navigation bar with 4 tabs and a smooth sliding pill indicator.
///
/// The pill slides between tabs with a spring-like cubic curve.
/// Icons cross-fade between outlined/filled variants, scale up on activation,
/// and labels transition their weight and colour — all simultaneously.
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
  // Previous index tracked so TweenAnimationBuilder always starts the pill
  // animation from the last selected tab.
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
      // Begin the next tween from wherever the pill currently is.
      _pillFrom = old.currentIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabCount = 4;
    const barHeight = 64.0;
    // Line indicator dimensions
    const lineH = 3.0;
    const lineW = 28.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabW = constraints.maxWidth / tabCount;

              return TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: _pillFrom,
                  end: widget.currentIndex.toDouble(),
                ),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                builder: (context, animPos, _) {
                  // Align line to the active tab's full width.
                  final lineLeft = animPos * tabW;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── Sliding top-line indicator ──────────────────────
                      Positioned(
                        left: lineLeft,
                        top: 0,
                        child: Container(
                          width: tabW,
                          height: lineH,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(lineH / 2),
                          ),
                        ),
                      ),

                      // ── Tab items ───────────────────────────────────────
                      Row(
                        children: List.generate(tabCount, (i) {
                          return _NavItem(
                            data: _tabs[i],
                            isActive: i == widget.currentIndex,
                            tabWidth: tabW,
                            onTap: () => widget.onTap(i),
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
      ),
    );
  }
}

// ── Individual tab item ───────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _TabData data;
  final bool isActive;
  final double tabWidth;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.tabWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor   = AppColors.navActive;
    final inactiveColor = AppColors.navInactive;
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
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon — scale + cross-fade between filled/outlined variants
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve:  Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    isActive ? data.activeIcon : data.icon,
                    key: ValueKey(isActive),
                    size: 22,
                    color: color,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Label — weight + colour transition
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                  letterSpacing: isActive ? 0.2 : 0,
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
