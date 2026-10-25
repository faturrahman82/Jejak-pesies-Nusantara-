import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../application/occurrence_controller.dart';
import '../../domain/species_occurrence.dart';
import '../widgets/occurrence_map_view.dart';
import '../widgets/request_state.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key, required this.controller, required this.onOpen});

  final OccurrenceController controller;
  final ValueChanged<SpeciesOccurrence> onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final located = controller.occurrences
          .where((item) => item.hasCoordinates)
          .toList(growable: false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peta pengamatan',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Marker berasal dari catatan yang sudah dimuat.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Expanded(
            child: located.isEmpty
                ? const RequestState.empty(
                    message: 'Belum ada catatan berkoordinat. Buka Jelajah dan muat catatan terlebih dahulu.',
                  )
                : ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: OccurrenceMapView(
                      occurrences: located,
                      onTapOccurrence: onOpen,
                    ),
                  ),
          ),
        ],
      );
    },
  );
}
