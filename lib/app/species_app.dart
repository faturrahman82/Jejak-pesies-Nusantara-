import 'package:flutter/material.dart';

import '../core/network/gbif_api_client.dart';
import '../features/occurrences/application/occurrence_controller.dart';
import '../features/occurrences/presentation/pages/home_shell.dart';
import 'app_theme.dart';

class SpeciesApp extends StatefulWidget {
  const SpeciesApp({
    super.key,
    required this.controller,
    required this.apiClient,
  });

  final OccurrenceController controller;
  final GbifApiClient apiClient;

  @override
  State<SpeciesApp> createState() => _SpeciesAppState();
}

class _SpeciesAppState extends State<SpeciesApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadFavorites();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    widget.apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Jejak Spesies Nusantara',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: HomeShell(controller: widget.controller),
  );
}
