import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An animated number counter text that counts up to the target integer or double
class AnimatedCountText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final String? suffix;
  final String? prefix;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, val, child) {
        final display = value is int ? val.round().toString() : val.toStringAsFixed(0);
        return Text(
          '${prefix ?? ''}$display${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

/// A glowing circular progress ring with smooth sweep animation and percentage text
class AnimatedAttendanceRing extends StatelessWidget {
  final double rate; // 0.0 - 100.0
  final double size;
  final double strokeWidth;
  final List<Color> gradientColors;

  const AnimatedAttendanceRing({
    super.key,
    required this.rate,
    this.size = 80,
    this.strokeWidth = 8,
    this.gradientColors = const [Color(0xFF00E5FF), Color(0xFF00FF87)],
  });

  @override
  Widget build(BuildContext context) {
    final clampedRate = rate.clamp(0.0, 100.0);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clampedRate / 100),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          return RepaintBoundary(
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                strokeWidth: strokeWidth,
                gradientColors: gradientColors,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Foreground arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepGradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: gradientColors,
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Glowing tip dot
    if (progress > 0.03) {
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipOffset = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );

      final glowPaint = Paint()
        ..color = gradientColors.last.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(tipOffset, strokeWidth * 0.6, glowPaint);
      canvas.drawCircle(tipOffset, strokeWidth * 0.4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
