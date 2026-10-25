import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jejak_spesies_nusantara/app/species_app.dart';
import 'package:jejak_spesies_nusantara/core/network/gbif_api_client.dart';
import 'package:jejak_spesies_nusantara/features/favorites/data/favorites_store.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/application/occurrence_controller.dart';
import 'package:jejak_spesies_nusantara/features/occurrences/data/occurrence_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search results can be saved, opened, and viewed on favorites', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await initializeDateFormatting('id_ID');
    final api = GbifApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/occurrence/search')) {
          return http.Response(
            jsonEncode({
              'offset': 0,
              'count': 1,
              'endOfRecords': true,
              'results': [_record],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/occurrence/42')) {
          return http.Response(jsonEncode(_record), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    final controller = OccurrenceController(
      repository: OccurrenceRepository(api),
      favoritesStore: FavoritesStore(),
    );

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpWidget(SpeciesApp(controller: controller, apiClient: api));
    await tester.pumpAndSettle();
    expect(find.text('Chlidonias hybrida'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).extendBody,
      isTrue,
    );

    await tester.tap(find.byTooltip('Simpan favorit').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorit'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan tersimpan'), findsOneWidget);
    expect(find.text('Chlidonias hybrida'), findsOneWidget);

    await tester.tap(find.text('Chlidonias hybrida'));
    await tester.pumpAndSettle();
    expect(find.text('Detail catatan'), findsOneWidget);
    expect(find.text('Klasifikasi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sumber catatan'),
      360,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sumber catatan'), findsOneWidget);
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}

final _record = <String, dynamic>{
  'key': 42,
  'scientificName': 'Chlidonias hybrida',
  'country': 'Indonesia',
  'class': 'Aves',
  'stateProvince': 'Jawa Timur',
  'locality': 'Surabaya',
  'eventDate': '2026-01-05',
  'decimalLatitude': -7.3,
  'decimalLongitude': 112.8,
  'basisOfRecord': 'HUMAN_OBSERVATION',
  'datasetName': 'iNaturalist research-grade observations',
  'references': 'https://www.inaturalist.org/observations/42',
};
