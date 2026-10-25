import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class LandscapeBackdrop extends StatefulWidget {
  const LandscapeBackdrop({super.key});

  @override
  State<LandscapeBackdrop> createState() => _LandscapeBackdropState();
}

class _LandscapeBackdropState extends State<LandscapeBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _motion.stop();
      _motion.value = 0.5;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    image: true,
    label: 'Ilustrasi langit, bukit, pohon, rumput, dan tanah Nusantara',
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) => CustomPaint(
          painter: _LandscapePainter(
            progress: _reduceMotion ? 0.5 : _motion.value,
          ),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

class LandscapeHero extends StatelessWidget {
  const LandscapeHero({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 152,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.eco_outlined, color: AppColors.card),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JEJAK SPESIES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      color: AppColors.forest,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Nusantara',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.58,
            child: const Text(
              'Kenali kehidupan\ndi sekitar kita.',
              style: TextStyle(
                color: AppColors.deepForest,
                fontSize: 21,
                height: 1.13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Catatan spesies dari seluruh Indonesia.',
            style: TextStyle(
              color: AppColors.deepForest,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LandscapePainter extends CustomPainter {
  const _LandscapePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.sky);

    canvas.drawCircle(
      Offset(width * 0.76, height * 0.14),
      15,
      Paint()..color = AppColors.sunlight,
    );
    _drawClouds(canvas, size);
    _drawHill(
      canvas,
      size,
      color: const Color(0xFFC7D9B6),
      startY: height * 0.59,
      peakX: width * 0.42,
      peakY: height * 0.34,
    );
    _drawHill(
      canvas,
      size,
      color: const Color(0xFF91AD7B),
      startY: height * 0.75,
      peakX: width * 0.82,
      peakY: height * 0.48,
    );
    _drawTree(canvas, size);

    final ground = Path()
      ..moveTo(0, height * 0.83)
      ..quadraticBezierTo(width * 0.48, height * 0.74, width, height * 0.84)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(ground, Paint()..color = AppColors.soil);
    _drawGrass(canvas, size);
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()..color = const Color(0xAAFFFFF7);
    for (var i = 0; i < 2; i++) {
      final travel = (progress + i * 0.56) % 1;
      final x = travel * (size.width + 70) - 35;
      final y = size.height * (i == 0 ? 0.2 : 0.42);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 43, height: 11),
        cloudPaint,
      );
      canvas.drawCircle(Offset(x - 8, y - 5), 8, cloudPaint);
      canvas.drawCircle(Offset(x + 2, y - 7), 10, cloudPaint);
    }
  }

  void _drawHill(
    Canvas canvas,
    Size size, {
    required Color color,
    required double startY,
    required double peakX,
    required double peakY,
  }) {
    final path = Path()
      ..moveTo(0, startY)
      ..quadraticBezierTo(peakX * 0.45, peakY, peakX, peakY)
      ..quadraticBezierTo(peakX * 1.45, peakY, size.width, startY * 0.96)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawTree(Canvas canvas, Size size) {
    final sway = math.sin(progress * math.pi * 2) * 0.035;
    final center = Offset(size.width * 0.85, size.height * 0.53);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, size.height * 0.72),
          width: 9,
          height: 58,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF79543A),
    );

    final leaves = [
      (Offset(-14, 0), 24.0, AppColors.forest),
      (Offset(11, -10), 23.0, AppColors.leaf),
      (Offset(0, -24), 24.0, const Color(0xFF557D50)),
      (Offset(-23, -17), 18.0, const Color(0xFF78975F)),
      (Offset(22, -23), 19.0, const Color(0xFF678A54)),
    ];
    for (final (offset, radius, color) in leaves) {
      final rotatedX = offset.dx - offset.dy * sway;
      final rotatedY = offset.dy + offset.dx * sway;
      canvas.drawCircle(
        center + Offset(rotatedX, rotatedY),
        radius,
        Paint()..color = color,
      );
    }
  }

  void _drawGrass(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5C38A)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 15; i++) {
      final x = size.width * (i / 14);
      final y = size.height * (0.84 + (i % 3) * 0.018);
      canvas.drawLine(Offset(x, y + 7), Offset(x - 2, y), paint);
      canvas.drawLine(Offset(x + 1, y + 7), Offset(x + 4, y + 1), paint);
    }
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
