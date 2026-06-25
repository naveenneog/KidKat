import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/brand.dart';

/// Shown when a finite learning session finishes. Celebrates progress and
/// gently sends the child back home — no "up next" rabbit hole.
class BreakScreen extends StatelessWidget {
  const BreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 90)),
                  const SizedBox(height: 16),
                  Text(
                    'Great job!',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You finished your learning session.\nTime to rest your eyes '
                    'and play! 🐱',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 28),
                  BigButton(
                    label: 'Back home',
                    icon: Icons.home_rounded,
                    color: Colors.white,
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
