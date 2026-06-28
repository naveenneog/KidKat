import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidkat/core/palette.dart';
import 'package:kidkat/core/theme.dart';
import 'package:kidkat/data/curation_service.dart';
import 'package:kidkat/widgets/brand.dart';

/// Regression tests for the v0.6.0 bug-fix pass (found during the QA review).
void main() {
  group('BUG-08 theme palette', () {
    test('Candy Bright is pink-forward (primary #EC4899, secondary #8B5CF6)',
        () {
      final candy = paletteFor(ThemeId.candyBright);
      expect(candy.primary, const Color(0xFFEC4899));
      expect(candy.secondary, const Color(0xFF8B5CF6));
      expect(candy.accent, const Color(0xFFFBBF24));
      expect(candy.ink, const Color(0xFF831843));
    });

    test('every theme defines a full palette', () {
      for (final id in ThemeId.values) {
        final p = paletteFor(id);
        expect(p.gradient.length, greaterThanOrEqualTo(2));
        expect(p.name, isNotEmpty);
      }
    });
  });

  group('BUG-07 demo content', () {
    test('demo clips are kid-safe Blender films, not pop-music placeholders',
        () {
      final ids = kDemoVideos.map((v) => v.id).toList();
      expect(ids, contains('aqz-KE-bpKQ')); // Big Buck Bunny
      // The old placeholder/pop-music ids must be gone.
      expect(ids, isNot(contains('dQw4w9WgXcQ'))); // Rickroll
      expect(ids, isNot(contains('9bZkp7q19f0'))); // Gangnam Style
      expect(ids, isNot(contains('kJQP7kiw5Fk'))); // Despacito
      // Friendly titles, not "Demo clip N".
      expect(
        kDemoVideos.every((v) => !v.title.startsWith('Demo clip')),
        isTrue,
      );
    });
  });

  group('BUG-01 button legibility', () {
    Future<Color?> foregroundOf(WidgetTester tester, Color? color) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildKidKatTheme(paletteFor(ThemeId.defaultPurple)),
          home: Scaffold(
            body: BigButton(label: 'Tap', color: color, onPressed: () {}),
          ),
        ),
      );
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      return btn.style?.foregroundColor?.resolve(<WidgetState>{});
    }

    testWidgets('a light (white) button gets a dark, legible label',
        (tester) async {
      final fg = await foregroundOf(tester, Colors.white);
      expect(fg, isNotNull);
      expect(fg, isNot(Colors.white));
      expect(fg, KidColors.ink);
    });

    testWidgets('a dark button keeps a white label', (tester) async {
      final fg = await foregroundOf(tester, KidColors.blue);
      expect(fg, Colors.white);
    });
  });
}
