import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_theme.dart';
import '../../application/occurrence_controller.dart';
import '../../domain/species_occurrence.dart';
import '../widgets/occurrence_map_view.dart';
import '../widgets/local_name_label.dart';
import '../widgets/photo_panel.dart';

class OccurrenceDetailPage extends StatelessWidget {
  const OccurrenceDetailPage({
    super.key,
    required this.occurrence,
    required this.controller,
  });

  final SpeciesOccurrence occurrence;
  final OccurrenceController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detail catatan'),
      actions: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final saved = controller.favoriteIds.contains(occurrence.id);
            return IconButton(
              tooltip: saved ? 'Hapus dari favorit' : 'Simpan favorit',
              onPressed: () => controller.toggleFavorite(occurrence),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: PhotoPanel(media: occurrence.firstPhoto, height: 250),
        ),
        const SizedBox(height: 20),
        Text(
          occurrence.scientificName,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        _SectionTitle('Nama lokal'),
        LocalNameLabel(
          occurrence: occurrence,
          controller: controller,
          compact: false,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Tag(occurrence.groupLabel),
            if (occurrence.iucnCategory case final category?)
              _Tag('IUCN ${_iucnLabel(category)}'),
          ],
        ),
        const SizedBox(height: 22),
        _SectionTitle('Klasifikasi'),
        _InfoCard(
          children: [
            _InfoRow(label: 'Kerajaan', value: occurrence.kingdom),
            _InfoRow(label: 'Filum', value: occurrence.phylum),
            _InfoRow(label: 'Kelas', value: occurrence.className),
            _InfoRow(label: 'Ordo', value: occurrence.order),
            _InfoRow(label: 'Famili', value: occurrence.family),
            _InfoRow(label: 'Genus', value: occurrence.genus),
            _InfoRow(label: 'Tingkat takson', value: occurrence.taxonRank),
          ],
        ),
        const SizedBox(height: 20),
        _SectionTitle('Lokasi dan waktu'),
        _InfoCard(
          children: [
            _InfoRow(
              label: 'Lokasi',
              value: occurrence.location ?? occurrence.country,
            ),
            _InfoRow(
              label: 'Tanggal pengamatan',
              value: occurrence.eventDate == null
                  ? null
                  : DateFormat(
                      'd MMMM y',
                      'id_ID',
                    ).format(occurrence.eventDate!),
            ),
            _InfoRow(
              label: 'Koordinat',
              value: occurrence.hasCoordinates
                  ? '${occurrence.latitude!.toStringAsFixed(5)}, ${occurrence.longitude!.toStringAsFixed(5)}'
                  : null,
            ),
            _InfoRow(
              label: 'Ketidakpastian lokasi',
              value: occurrence.coordinateUncertaintyMeters == null
                  ? null
                  : '± ${occurrence.coordinateUncertaintyMeters!.round()} m',
            ),
          ],
        ),
        if (occurrence.hasCoordinates) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: OccurrenceMapView(
                occurrences: [occurrence],
                onTapOccurrence: (_) {},
                showOpenStreetMapCredit: true,
                initialZoom: 10,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _SectionTitle('Sumber catatan'),
        _InfoCard(
          children: [
            _InfoRow(
              label: 'Jenis catatan',
              value: _recordType(occurrence.basisOfRecord),
            ),
            _InfoRow(label: 'Dataset', value: occurrence.datasetName),
            _InfoRow(label: 'Pencatat', value: occurrence.recordedBy),
            _InfoRow(label: 'Lisensi catatan', value: occurrence.license),
          ],
        ),
        if (occurrence.firstPhoto?.credit != null ||
            occurrence.firstPhoto?.license != null) ...[
          const SizedBox(height: 20),
          _SectionTitle('Kredit dan lisensi foto'),
          _InfoCard(
            children: [
              if (occurrence.firstPhoto?.credit case final credit?)
                _InfoRow(label: 'Foto oleh', value: credit),
              _InfoRow(
                label: 'Lisensi foto',
                value: occurrence.firstPhoto?.license,
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        if (occurrence.recordUrl case final recordUrl?)
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(recordUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Buka sumber catatan'),
          ),
        if (occurrence.firstPhoto?.licenseUrl case final licenseUrl?)
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(licenseUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Lihat lisensi foto'),
          ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        children: children
            .where((child) => child is! _InfoRow || child.value != null)
            .toList(),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.moss,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.deepForest,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}

String _iucnLabel(String code) => switch (code.toUpperCase()) {
  'LC' => 'Risiko Rendah',
  'NT' => 'Hampir Terancam',
  'VU' => 'Rentan',
  'EN' => 'Terancam',
  'CR' => 'Kritis',
  'EW' => 'Punah di Alam Liar',
  'EX' => 'Punah',
  _ => code,
};

String? _recordType(String? code) {
  if (code == null) return null;
  return switch (code) {
    'HUMAN_OBSERVATION' => 'Pengamatan manusia',
    'PRESERVED_SPECIMEN' => 'Spesimen tersimpan',
    'MACHINE_OBSERVATION' => 'Pengamatan mesin',
    'OBSERVATION' => 'Pengamatan',
    _ => code.replaceAll('_', ' ').toLowerCase(),
  };
}
