import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/providers.dart';

/// Full-screen brand gradient (theme-aware) used on welcome / break screens.
class BrandGradient extends ConsumerWidget {
  const BrandGradient({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    return Container(
      decoration: BoxDecoration(gradient: palette.brandGradient),
      child: child,
    );
  }
}

/// A soft, colorful, theme-aware backdrop with floating shapes. Place content
/// as [child]; the decorative blobs sit behind it.
class KidBackdrop extends ConsumerWidget {
  const KidBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(paletteProvider);
    return Container(
      color: p.bg,
      child: Stack(
        children: [
          Positioned(
              top: -70,
              right: -50,
              child: _blob(p.primary.withValues(alpha: 0.16), 220)),
          Positioned(
              top: 140,
              left: -60,
              child: _blob(p.secondary.withValues(alpha: 0.14), 170)),
          Positioned(
              bottom: -60,
              right: -30,
              child: _blob(p.accent.withValues(alpha: 0.18), 200)),
          Positioned(
              bottom: 120,
              left: -40,
              child: _blob(p.primary.withValues(alpha: 0.10), 130)),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// The KidKat graduate-cat mark.
class KidLogo extends StatelessWidget {
  const KidLogo({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/branding/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// A large, friendly rounded action button.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: color == null
          ? null
          : ElevatedButton.styleFrom(
              backgroundColor: color,
              // Keep the label/icon legible on light backgrounds: the global
              // ElevatedButton theme forces a white foreground, which would be
              // invisible on a white/pale button.
              foregroundColor:
                  ThemeData.estimateBrightnessForColor(color!) ==
                          Brightness.light
                      ? KidColors.ink
                      : Colors.white,
            ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 26), const SizedBox(width: 10)],
          Text(label),
        ],
      ),
    );
  }
}

/// A rounded card used for topic tiles and list rows.
class RoundedCard extends StatelessWidget {
  const RoundedCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
