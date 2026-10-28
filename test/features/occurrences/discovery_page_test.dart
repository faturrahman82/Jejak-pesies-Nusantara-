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

  testWidgets('searches by text and province, then shows an empty result', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await initializeDateFormatting('id_ID');
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    final searches = <Uri>[];
    final app = _app((request) async {
      if (request.url.path.endsWith('/occurrence/search')) {
        searches.add(request.url);
        final noResults = request.url.queryParameters['q'] == 'nothing-here';
        return http.Response(
          jsonEncode({
            'offset': 0,
            'count': noResults ? 0 : 1,
            'endOfRecords': true,
            'results': noResults ? [] : [_record],
          }),
          200,
        );
      }
      return http.Response('[]', 200);
    });

    await tester.pumpWidget(app.widget);
    await _pumpFrames(tester);
    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Cari spesies atau lokasi',
    );
    await tester.enterText(searchField, 'Chlidonias');
    await tester.pump(const Duration(milliseconds: 450));
    await _pumpFrames(tester);
    expect(
      searches.any((uri) => uri.queryParameters['q'] == 'Chlidonias'),
      isTrue,
    );

    await tester.tap(find.text('Filter provinsi'));
    await _pumpFrames(tester);
    await tester.enterText(find.byType(TextField).last, 'Jawa Timur');
    await tester.tap(find.text('Terapkan'));
    await _pumpFrames(tester);
    expect(searches.last.queryParameters['stateProvince'], 'Jawa Timur');
    expect(searches.last.queryParameters['q'], 'Chlidonias');

    await tester.enterText(searchField, 'nothing-here');
    await tester.pump(const Duration(milliseconds: 450));
    await _pumpFrames(tester);
    expect(find.textContaining('Belum ada catatan bergambar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });

  testWidgets('offers another page when the raw page has no usable photo', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await initializeDateFormatting('id_ID');
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    final offsets = <int>[];
    final app = _app((request) async {
      if (!request.url.path.endsWith('/occurrence/search')) {
        return http.Response('[]', 200);
      }
      final offset = int.parse(request.url.queryParameters['offset']!);
      offsets.add(offset);
      return http.Response(
        jsonEncode({
          'offset': offset,
          'count': 21,
          'endOfRecords': offset > 0,
          'results': offset == 0
              ? [
                  {
                    'key': 1,
                    'scientificName': 'Species without a photo',
                    'country': 'Indonesia',
                    'media': [],
                  },
                ]
              : [_record],
        }),
        200,
      );
    });

    await tester.pumpWidget(app.widget);
    await _pumpFrames(tester);
    expect(find.text('Muat catatan berikutnya'), findsOneWidget);
    await tester.tap(find.text('Muat catatan berikutnya'));
    await _pumpFrames(tester);
    expect(offsets, [0, 1]);
    expect(find.text('Chlidonias hybrida'), findsOneWidget);
    expect(find.text('Species without a photo'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });

  testWidgets('shows a retry action after the initial request fails', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await initializeDateFormatting('id_ID');
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    var attempts = 0;
    final app = _app((request) async {
      if (!request.url.path.endsWith('/occurrence/search')) {
        return http.Response('[]', 200);
      }
      attempts++;
      return attempts == 1
          ? http.Response('unavailable', 503)
          : http.Response(
              jsonEncode({
                'offset': 0,
                'count': 1,
                'endOfRecords': true,
                'results': [_record],
              }),
              200,
            );
    });

    await tester.pumpWidget(app.widget);
    await _pumpFrames(tester);
    expect(find.text('Coba lagi'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await _pumpFrames(tester);
    expect(attempts, 2);
    expect(find.text('Chlidonias hybrida'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}

_AppHarness _app(Future<http.Response> Function(http.Request) handler) {
  final api = GbifApiClient(client: MockClient(handler));
  final controller = OccurrenceController(
    repository: OccurrenceRepository(api),
    favoritesStore: FavoritesStore(),
  );
  return _AppHarness(SpeciesApp(controller: controller, apiClient: api));
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _AppHarness {
  const _AppHarness(this.widget);

  final Widget widget;
}

final _record = <String, dynamic>{
  'key': 42,
  'scientificName': 'Chlidonias hybrida',
  'country': 'Indonesia',
  'class': 'Aves',
  'taxonRank': 'SPECIES',
  'speciesKey': 5231190,
  'media': [
    {'identifier': 'https://example.org/tern.jpg'},
  ],
};
