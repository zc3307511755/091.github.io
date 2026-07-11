import 'package:flutter/material.dart';

abstract final class StitchColors {
  static const primary = Color(0xFFBA0034);
  static const primaryContainer = Color(0xFFE51245);
  static const ink = Color(0xFF1A1B1F);
  static const muted = Color(0xFF5D3F40);
  static const page = Color(0xFFFAF9FE);
  static const grouped = Color(0xFFF2F2F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF4F3F8);
  static const surfaceHigh = Color(0xFFE9E7ED);
  static const line = Color(0xFFE5E2E7);
  static const roseLine = Color(0xFFE6BCBD);
  static const blue = Color(0xFF0058BC);
  static const green = Color(0xFF00694B);
  static const red = Color(0xFFBA1A1A);
}

class StitchPageFrame extends StatelessWidget {
  const StitchPageFrame({
    required this.child,
    this.backgroundColor = StitchColors.page,
    super.key,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
  }
}

class StitchTopBar extends StatelessWidget {
  const StitchTopBar({
    required this.avatarAsset,
    this.onHeartPressed,
    super.key,
  });

  final String avatarAsset;
  final VoidCallback? onHeartPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            '我们俩',
            style: TextStyle(
              color: StitchColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: StitchColors.surface,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: StitchColors.roseLine),
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(avatarAsset, fit: BoxFit.cover),
                    ),
                  ),
                  IconButton(
                    tooltip: '我们俩',
                    onPressed: onHeartPressed ?? () {},
                    iconSize: 32,
                    color: StitchColors.primary,
                    icon: const Icon(Icons.favorite_border_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StitchSegmentedControl extends StatelessWidget {
  const StitchSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StitchColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: Material(
              color: selected ? StitchColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              elevation: selected ? 1 : 0,
              shadowColor: Colors.black.withValues(alpha: 0.10),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelected(index),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected ? StitchColors.ink : StitchColors.muted,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StitchGroupCard extends StatelessWidget {
  const StitchGroupCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StitchColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class StitchEmptyState extends StatelessWidget {
  const StitchEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: StitchColors.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
