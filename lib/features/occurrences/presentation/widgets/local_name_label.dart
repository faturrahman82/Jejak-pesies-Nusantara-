import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../application/occurrence_controller.dart';
import '../../domain/species_occurrence.dart';

class LocalNameLabel extends StatefulWidget {
  const LocalNameLabel({
    super.key,
    required this.occurrence,
    required this.controller,
    required this.compact,
  });

  final SpeciesOccurrence occurrence;
  final OccurrenceController controller;
  final bool compact;

  @override
  State<LocalNameLabel> createState() => _LocalNameLabelState();
}

class _LocalNameLabelState extends State<LocalNameLabel> {
  late Future<String?> _request;

  @override
  void initState() {
    super.initState();
    _request = widget.controller.localNameFor(widget.occurrence);
  }

  @override
  void didUpdateWidget(covariant LocalNameLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldOccurrence = oldWidget.occurrence;
    final newOccurrence = widget.occurrence;
    if (oldWidget.controller != widget.controller ||
        oldOccurrence.speciesKey != newOccurrence.speciesKey ||
        oldOccurrence.taxonKey != newOccurrence.taxonKey ||
        oldOccurrence.taxonRank != newOccurrence.taxonRank) {
      _request = widget.controller.localNameFor(newOccurrence);
    }
  }

  void _retry() {
    setState(() {
      _request = widget.controller.reloadLocalName(widget.occurrence);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _request,
    builder: (context, snapshot) {
      final style = widget.compact
          ? Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.muted)
          : Theme.of(context).textTheme.bodyMedium;
      if (snapshot.connectionState != ConnectionState.done) {
        return Text('Memuat nama lokal…', style: style);
      }
      if (snapshot.hasError) {
        if (widget.compact) {
          return Text('Nama lokal tidak dapat dimuat', style: style);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama lokal tidak dapat dimuat.', style: style),
            TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        );
      }

      final name = snapshot.data;
      return Text(
        name ?? 'Nama lokal belum tercatat',
        maxLines: widget.compact ? 1 : null,
        overflow: widget.compact ? TextOverflow.ellipsis : null,
        style: style,
      );
    },
  );
}
