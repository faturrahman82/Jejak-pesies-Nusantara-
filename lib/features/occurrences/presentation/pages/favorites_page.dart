import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../application/occurrence_controller.dart';
import '../../domain/species_occurrence.dart';
import '../widgets/request_state.dart';
import '../widgets/species_card.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  final OccurrenceController controller;
  final ValueChanged<SpeciesOccurrence> onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final records = controller.favoriteOccurrences;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan tersimpan',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Kumpulan spesies pilihanmu.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Expanded(
            child: controller.loadingFavorites && records.isEmpty
                ? const RequestState.loading()
                : records.isEmpty
                ? const RequestState.empty(
                    message: 'Belum ada catatan tersimpan. Tekan ikon penanda pada kartu spesies untuk menyimpannya.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final occurrence = records[index];
                      return SpeciesCard(
                        occurrence: occurrence,
                        controller: controller,
                        isFavorite: true,
                        onTap: () => onOpen(occurrence),
                        onFavorite: () => controller.toggleFavorite(occurrence),
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );
}
