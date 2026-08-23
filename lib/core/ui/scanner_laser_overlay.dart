import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Scanner overlay with ultra-smooth animated laser line and glowing corner brackets
class AnimatedScannerOverlay extends StatefulWidget {
  final Color borderColor;
  final bool isScanning;

  const AnimatedScannerOverlay({
    super.key,
    required this.borderColor,
    this.isScanning = true,
  });

  @override
  State<AnimatedScannerOverlay> createState() => _AnimatedScannerOverlayState();
}

class _AnimatedScannerOverlayState extends State<AnimatedScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.03, end: 0.97).animate(
      CurvedAnimation(
        parent: _laserController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _laserController,
      builder: (context, child) {
        final isMovingUp = _laserController.status == AnimationStatus.reverse;
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ScannerLaserPainter(
            borderColor: widget.borderColor,
            laserProgress: _laserAnimation.value,
            isMovingUp: isMovingUp,
            isScanning: widget.isScanning,
          ),
        );
      },
    );
  }
}

class _ScannerLaserPainter extends CustomPainter {
  final Color borderColor;
  final double laserProgress;
  final bool isMovingUp;
  final bool isScanning;

  _ScannerLaserPainter({
    required this.borderColor,
    required this.laserProgress,
    required this.isMovingUp,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.72;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2 - 30;
    final Rect scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);
    final RRect scanRRect = RRect.fromRectAndRadius(
      scanRect,
      const Radius.circular(22),
    );

    // 1. Dark backdrop overlay outside scan box
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(scanRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // 2. Subtle border around scan area
    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRRect(scanRRect, borderPaint);

    // 3. Animated Laser Line with bidirectional fluid glow
    if (isScanning) {
      canvas.save();
      // Clip inside scan box to prevent any overflow at the edges
      canvas.clipRRect(scanRRect);

      final laserY = top + (scanAreaSize * laserProgress);

      // Trail factor scales down near edges (0 at edges, 1 at center) for seamless deceleration
      final edgeFactor = math.sin(laserProgress * math.pi).clamp(0.0, 1.0);
      final dynamicTrailHeight = 45.0 * edgeFactor;

      if (dynamicTrailHeight > 2.0) {
        // Draw directional trailing gradient (behind movement direction)
        final Rect trailRect = isMovingUp
            ? Rect.fromLTRB(
                left + 10,
                laserY,
                left + scanAreaSize - 10,
                laserY + dynamicTrailHeight,
              )
            : Rect.fromLTRB(
                left + 10,
                laserY - dynamicTrailHeight,
                left + scanAreaSize - 10,
                laserY,
              );

        final trailGradient = LinearGradient(
          begin: isMovingUp ? Alignment.topCenter : Alignment.bottomCenter,
          end: isMovingUp ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            borderColor.withValues(alpha: 0.28 * edgeFactor),
            borderColor.withValues(alpha: 0.0),
          ],
        );

        final trailPaint = Paint()
          ..shader = trailGradient.createShader(trailRect)
          ..style = PaintingStyle.fill;

        canvas.drawRect(trailRect, trailPaint);
      }

      // Soft ambient aura around the laser line
      final auraPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.4 * edgeFactor)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawLine(
        Offset(left + 20, laserY),
        Offset(left + scanAreaSize - 20, laserY),
        auraPaint,
      );

      // Main Laser Line
      final laserLinePaint = Paint()
        ..color = borderColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

      canvas.drawLine(
        Offset(left + 14, laserY),
        Offset(left + scanAreaSize - 14, laserY),
        laserLinePaint,
      );

      // Center bright laser beam streak
      final brightLinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(left + 32, laserY),
        Offset(left + scanAreaSize - 32, laserY),
        brightLinePaint,
      );

      canvas.restore();
    }

    // 4. Modern Glowing Corner Brackets
    final cornerLength = scanAreaSize * 0.16;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const radius = 22.0;

    // Top-Left
    final pathTL = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top + radius)
      ..arcToPoint(
        Offset(left + radius, top),
        radius: const Radius.circular(radius),
      )
      ..lineTo(left + cornerLength, top);
    canvas.drawPath(pathTL, cornerPaint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(left + scanAreaSize - cornerLength, top)
      ..lineTo(left + scanAreaSize - radius, top)
      ..arcToPoint(
        Offset(left + scanAreaSize, top + radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(left + scanAreaSize, top + cornerLength);
    canvas.drawPath(pathTR, cornerPaint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(left, top + scanAreaSize - cornerLength)
      ..lineTo(left, top + scanAreaSize - radius)
      ..arcToPoint(
        Offset(left + radius, top + scanAreaSize),
        radius: const Radius.circular(radius),
      )
      ..lineTo(left + cornerLength, top + scanAreaSize);
    canvas.drawPath(pathBL, cornerPaint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(left + scanAreaSize - cornerLength, top + scanAreaSize)
      ..lineTo(left + scanAreaSize - radius, top + scanAreaSize)
      ..arcToPoint(
        Offset(left + scanAreaSize, top + scanAreaSize - radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(left + scanAreaSize, top + scanAreaSize - cornerLength);
    canvas.drawPath(pathBR, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerLaserPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress ||
        oldDelegate.isMovingUp != isMovingUp ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isScanning != isScanning;
  }
}
