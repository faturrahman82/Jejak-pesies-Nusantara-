import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/presentation/widgets/landscape_hero.dart';

void main() {
  testWidgets('landscape illustration settles when reduced motion is enabled', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: LandscapeBackdrop()),
              Align(alignment: Alignment.topCenter, child: LandscapeHero()),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LandscapeBackdrop), findsOneWidget);
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}
