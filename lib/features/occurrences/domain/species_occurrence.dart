import 'occurrence_media.dart';

class SpeciesOccurrence {
  const SpeciesOccurrence({
    required this.id,
    required this.scientificName,
    required this.country,
    required this.media,
    this.kingdom,
    this.phylum,
    this.className,
    this.order,
    this.family,
    this.genus,
    this.taxonRank,
    this.location,
    this.stateProvince,
    this.eventDate,
    this.latitude,
    this.longitude,
    this.coordinateUncertaintyMeters,
    this.iucnCategory,
    this.basisOfRecord,
    this.datasetName,
    this.recordedBy,
    this.recordUrl,
    this.license,
    this.taxonKey,
  });

  final String id;
  final String scientificName;
  final String country;
  final String? kingdom;
  final String? phylum;
  final String? className;
  final String? order;
  final String? family;
  final String? genus;
  final String? taxonRank;
  final String? location;
  final String? stateProvince;
  final DateTime? eventDate;
  final double? latitude;
  final double? longitude;
  final double? coordinateUncertaintyMeters;
  final String? iucnCategory;
  final String? basisOfRecord;
  final String? datasetName;
  final String? recordedBy;
  final String? recordUrl;
  final String? license;
  final String? taxonKey;
  final List<OccurrenceMedia> media;

  bool get hasCoordinates => latitude != null && longitude != null;
  OccurrenceMedia? get firstPhoto => media.isEmpty ? null : media.first;

  String get speciesIdentity {
    if (taxonKey != null) return 'taxon:$taxonKey';
    final canonical = _stringFromName(scientificName).toLowerCase();
    final words = canonical.split(RegExp(r'\s+'));
    return words.length >= 2
        ? 'name:${words.take(2).join(' ')}'
        : 'name:$canonical';
  }

  int get completenessScore =>
      (firstPhoto == null ? 0 : 8) +
      (hasCoordinates ? 4 : 0) +
      (eventDate == null ? 0 : 2) +
      (datasetName == null ? 0 : 1);

  String get groupLabel {
    final value = className ?? kingdom ?? taxonRank ?? 'Spesies';
    return switch (value.toLowerCase()) {
      'aves' => 'Burung',
      'mammalia' => 'Mamalia',
      'reptilia' => 'Reptil',
      'amphibia' => 'Amfibi',
      'insecta' => 'Serangga',
      'actinopterygii' || 'chondrichthyes' => 'Ikan',
      'plantae' => 'Tumbuhan',
      'fungi' => 'Jamur',
      _ => value,
    };
  }

  factory SpeciesOccurrence.fromJson(Map<String, dynamic> json) {
    final gadm = _map(json['gadm']);
    final province =
        _string(json['stateProvince']) ?? _gadmName(gadm, 'level1');
    final locality = _string(json['locality']) ?? _gadmName(gadm, 'level3');
    final city = _gadmName(gadm, 'level2');
    final location = _joinLocation([
      locality,
      city,
      province,
      _string(json['country']),
    ]);
    final media = (json['media'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OccurrenceMedia.fromJson)
        .where((item) => item.url.isNotEmpty)
        .toList(growable: false);

    return SpeciesOccurrence(
      id:
          _identifier(json['key']) ??
          _identifier(json['gbifID']) ??
          _identifier(json['identifier']) ??
          '',
      scientificName:
          _string(json['scientificName']) ??
          _string(json['acceptedScientificName']) ??
          'Nama spesies belum tersedia',
      country: _string(json['country']) ?? 'Indonesia',
      kingdom: _string(json['kingdom']),
      phylum: _string(json['phylum']),
      className: _string(json['class']),
      order: _string(json['order']),
      family: _string(json['family']),
      genus: _string(json['genus']),
      taxonRank: _string(json['taxonRank']),
      location: location,
      stateProvince: province,
      eventDate: _date(json['eventDate']) ?? _dateParts(json),
      latitude: _number(json['decimalLatitude']),
      longitude: _number(json['decimalLongitude']),
      coordinateUncertaintyMeters: _number(
        json['coordinateUncertaintyInMeters'],
      ),
      iucnCategory: _string(json['iucnRedListCategory']),
      basisOfRecord: _string(json['basisOfRecord']),
      datasetName: _string(json['datasetName']),
      recordedBy: _string(json['recordedBy']),
      recordUrl: _string(json['references']),
      license: _string(json['license']),
      taxonKey: _identifier(json['speciesKey']) ?? _identifier(json['taxonKey']),
      media: media,
    );
  }
}

String _stringFromName(String value) {
  final words = value.trim().split(RegExp(r'\s+'));
  return words.length > 2 ? words.take(2).join(' ') : value.trim();
}

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

String? _identifier(Object? value) => switch (value) {
  String text when text.trim().isNotEmpty => text.trim(),
  num number => number.toString(),
  _ => null,
};

double? _number(Object? value) => value is num ? value.toDouble() : null;

DateTime? _date(Object? value) {
  if (value is! String) return null;
  final normalized = value.split('/').first.trim();
  return DateTime.tryParse(normalized);
}

DateTime? _dateParts(Map<String, dynamic> json) {
  final year = json['year'];
  if (year is! int) return null;
  final month = json['month'] is int ? json['month'] as int : 1;
  final day = json['day'] is int ? json['day'] as int : 1;
  return DateTime.tryParse(
    '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

String? _gadmName(Map<String, dynamic> gadm, String level) =>
    _string(_map(gadm[level])['name']);

String? _joinLocation(List<String?> parts) {
  final unique = <String>[];
  for (final part in parts.whereType<String>()) {
    if (!unique.any(
      (existing) => existing.toLowerCase() == part.toLowerCase(),
    )) {
      unique.add(part);
    }
  }
  return unique.isEmpty ? null : unique.join(', ');
}
