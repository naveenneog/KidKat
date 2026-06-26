import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidkat/data/local_store.dart';
import 'package:kidkat/data/providers.dart';
import 'package:kidkat/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _bootstrap(Widget child) async {
  final store = await LocalStore.create();
  return ProviderScope(
    overrides: [localStoreProvider.overrideWithValue(store)],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('onboarding welcome renders branding and CTA', (tester) async {
    await tester.pumpWidget(await _bootstrap(const OnboardingScreen()));
    await tester.pump();
    expect(find.text('KidKat'), findsWidgets);
    expect(find.text("Let's set up"), findsOneWidget);
  });

  testWidgets('onboarding advances to parent setup step', (tester) async {
    await tester.pumpWidget(await _bootstrap(const OnboardingScreen()));
    await tester.pump();
    await tester.tap(find.text("Let's set up"));
    await tester.pump();
    expect(find.text('Parent setup'), findsOneWidget);
    expect(find.text('Connect YouTube (one-time)'), findsOneWidget);
  });
}
