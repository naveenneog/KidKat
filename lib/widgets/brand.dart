import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Full-screen brand gradient used on welcome / break screens.
class BrandGradient extends StatelessWidget {
  const BrandGradient({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: KidColors.brandGradient),
      child: child,
    );
  }
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
          : ElevatedButton.styleFrom(backgroundColor: color),
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
