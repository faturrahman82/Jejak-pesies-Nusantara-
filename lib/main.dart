import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/species_app.dart';
import 'core/network/api_config.dart';
import 'core/network/gbif_api_client.dart';
import 'features/favorites/data/favorites_store.dart';
import 'features/occurrences/application/occurrence_controller.dart';
import 'features/occurrences/data/occurrence_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final apiClient = GbifApiClient(baseUri: ApiConfig.baseUri);
  final controller = OccurrenceController(
    repository: OccurrenceRepository(apiClient),
    favoritesStore: FavoritesStore(),
  );
  runApp(SpeciesApp(controller: controller, apiClient: apiClient));
}
