import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/domain/occurrence_media.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/presentation/widgets/photo_panel.dart';

void main() {
  testWidgets('shows the photo placeholder when no usable link is available', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PhotoPanel(media: null)));
    expect(find.text('Foto tidak tersedia'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: PhotoPanel(media: OccurrenceMedia(url: '')),
      ),
    );
    expect(find.text('Foto tidak tersedia'), findsOneWidget);
  });
}
