import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/occurrence_media.dart';

class PhotoPanel extends StatelessWidget {
  const PhotoPanel({super.key, required this.media, this.height = 168});

  final OccurrenceMedia? media;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = media?.url;
    if (url == null || url.isEmpty) return _placeholder(height);
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => _placeholder(height, loading: true),
      errorWidget: (context, url, error) => _placeholder(height),
    );
  }

  Widget _placeholder(double height, {bool loading = false}) => Container(
    height: height,
    color: AppColors.moss,
    alignment: Alignment.center,
    child: loading
        ? const CircularProgressIndicator(color: AppColors.forest)
        : const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.nature_outlined, color: AppColors.forest, size: 34),
              SizedBox(height: 6),
              Text(
                'Foto tidak tersedia',
                style: TextStyle(color: AppColors.deepForest),
              ),
            ],
          ),
  );
}
