import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_theme.dart';
import '../../domain/species_occurrence.dart';

class OccurrenceMapView extends StatelessWidget {
  const OccurrenceMapView({
    super.key,
    required this.occurrences,
    required this.onTapOccurrence,
    this.showOpenStreetMapCredit = true,
    this.initialZoom = 4.2,
  });

  final List<SpeciesOccurrence> occurrences;
  final ValueChanged<SpeciesOccurrence> onTapOccurrence;
  final bool showOpenStreetMapCredit;
  final double initialZoom;

  @override
  Widget build(BuildContext context) {
    final located = occurrences
        .where((item) => item.hasCoordinates)
        .toList(growable: false);
    final center = located.isEmpty
        ? const LatLng(-2.5, 118)
        : LatLng(located.first.latitude!, located.first.longitude!);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: initialZoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.ac.jejakspesies.jejak_spesies_nusantara',
        ),
        MarkerLayer(
          markers: [
            for (final occurrence in located)
              Marker(
                point: LatLng(occurrence.latitude!, occurrence.longitude!),
                width: 48,
                height: 54,
                child: Semantics(
                  button: true,
                  label: 'Buka ${occurrence.scientificName}',
                  child: IconButton(
                    tooltip: occurrence.scientificName,
                    onPressed: () => onTapOccurrence(occurrence),
                    icon: const Icon(
                      Icons.location_on,
                      color: AppColors.orange,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (showOpenStreetMapCredit)
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap contributors',
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
