class OccurrenceMedia {
  const OccurrenceMedia({
    required this.url,
    this.creator,
    this.rightsHolder,
    this.license,
    this.licenseUrl,
    this.sourceUrl,
  });

  final String url;
  final String? creator;
  final String? rightsHolder;
  final String? license;
  final String? licenseUrl;
  final String? sourceUrl;

  String? get credit => creator ?? rightsHolder;

  factory OccurrenceMedia.fromJson(Map<String, dynamic> json) {
    return OccurrenceMedia(
      url: _string(json['identifier']) ?? '',
      creator: _string(json['creator']),
      rightsHolder: _string(json['rightsHolder']),
      license: _string(json['license']),
      licenseUrl: _string(json['license']),
      sourceUrl: _string(json['references']),
    );
  }
}

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
