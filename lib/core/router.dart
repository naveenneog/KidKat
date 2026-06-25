import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/kid/break_screen.dart';
import '../features/kid/kid_home.dart';
import '../features/kid/session_screen.dart';
import '../features/kid/time_up_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/parent/parent_dashboard.dart';
import '../features/parent/parent_gate.dart';
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild routing when onboarding state flips.
  final refresh = ValueNotifier<int>(0);
  ref.listen(onboardedProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final onboarded = ref.read(onboardedProvider);
      final loc = state.matchedLocation;
      if (!onboarded) return loc == '/onboarding' ? null : '/onboarding';
      if (loc == '/' || loc == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: KidColors.purple),
          ),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const KidHome()),
      GoRoute(
        path: '/session',
        builder: (_, state) =>
            SessionScreen(topicIds: state.extra as List<String>?),
      ),
      GoRoute(path: '/break', builder: (_, _) => const BreakScreen()),
      GoRoute(path: '/timeup', builder: (_, _) => const TimeUpScreen()),
      GoRoute(path: '/gate', builder: (_, _) => const ParentGate()),
      GoRoute(path: '/parent', builder: (_, _) => const ParentDashboard()),
    ],
  );
});

