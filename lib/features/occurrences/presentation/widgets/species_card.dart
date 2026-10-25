import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../domain/species_occurrence.dart';
import 'photo_panel.dart';

class SpeciesCard extends StatelessWidget {
  const SpeciesCard({
    super.key,
    required this.occurrence,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  final SpeciesOccurrence occurrence;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final date = occurrence.eventDate;
    return Semantics(
      button: true,
      label:
          'Detail ${occurrence.scientificName}, ${occurrence.location ?? occurrence.country}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Card(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      PhotoPanel(media: occurrence.firstPhoto),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          color: AppColors.card,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: isFavorite
                                ? 'Hapus dari favorit'
                                : 'Simpan favorit',
                            constraints: const BoxConstraints.tightFor(
                              width: 48,
                              height: 48,
                            ),
                            onPressed: onFavorite,
                            icon: AnimatedSwitcher(
                              duration: Duration(
                                milliseconds:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? 0
                                    : 220,
                              ),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: Icon(
                                isFavorite
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                key: ValueKey(isFavorite),
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: _GroupBadge(label: occurrence.groupLabel),
                      ),
                    ],
                  ),
                  Container(
                    color: AppColors.card.withValues(alpha: 0.78),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          occurrence.scientificName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, children: [
                          if (occurrence.firstPhoto != null) const Text('Foto tersedia', style: TextStyle(fontSize: 11)),
                          if (occurrence.hasCoordinates) const Text('Ada koordinat', style: TextStyle(fontSize: 11)),
                          if (date != null) const Text('Ada tanggal', style: TextStyle(fontSize: 11)),
                        ]),
                        _MetadataLine(
                          icon: Icons.place_outlined,
                          text: occurrence.location ?? occurrence.country,
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 6),
                          _MetadataLine(
                            icon: Icons.calendar_today_outlined,
                            text: DateFormat('d MMMM y', 'id_ID').format(date),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.deepForest,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _MetadataLine extends StatelessWidget {
  const _MetadataLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: AppColors.forest),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}
