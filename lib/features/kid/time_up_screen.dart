import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/brand.dart';

/// Shown when the child reaches the daily watch-time limit. A grown-up can add
/// more time from the parent area.
class TimeUpScreen extends StatelessWidget {
  const TimeUpScreen({super.key});

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
                  const Text('🌙', style: TextStyle(fontSize: 90)),
                  const SizedBox(height: 16),
                  Text(
                    "That's all for today!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You used all your learning time.\nSee you tomorrow! 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 28),
                  BigButton(
                    label: 'Okay',
                    icon: Icons.check_rounded,
                    color: Colors.white,
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => context.go('/gate'),
                    icon: const Icon(Icons.lock_outline_rounded,
                        color: Colors.white70),
                    label: const Text('Parent: add more time',
                        style: TextStyle(color: Colors.white70)),
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
