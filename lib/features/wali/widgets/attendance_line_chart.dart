import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/wali_murid_models.dart';

/// An interactive, animated smooth Bezier line chart for attendance trend
class AttendanceLineChart extends StatefulWidget {
  final List<AttendanceChartPoint> points;
  final double height;
  final List<Color> lineColors;

  const AttendanceLineChart({
    super.key,
    required this.points,
    this.height = 180,
    this.lineColors = const [Color(0xFF2563EB), Color(0xFF00D2FF)],
  });

  @override
  State<AttendanceLineChart> createState() => _AttendanceLineChartState();
}

class _AttendanceLineChartState extends State<AttendanceLineChart> {
  int? _selectedPointIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Belum ada data grafik untuk bulan ini',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tooltip Banner when a point is tapped
        if (_selectedPointIndex != null &&
            _selectedPointIndex! < widget.points.length) ...[
          _buildTooltipBadge(widget.points[_selectedPointIndex!]),
          const SizedBox(height: 8),
        ],

        // Interactive Canvas
        GestureDetector(
          onTapDown: (details) => _handleTouch(details.localPosition),
          onPanUpdate: (details) => _handleTouch(details.localPosition),
          onPanEnd: (_) => setState(() => _selectedPointIndex = null),
          onTapUp: (_) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _selectedPointIndex = null);
            });
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return CustomPaint(
                size: Size(double.infinity, widget.height),
                painter: _LineChartPainter(
                  points: widget.points,
                  progress: animValue,
                  selectedIndex: _selectedPointIndex,
                  lineColors: widget.lineColors,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // X-Axis Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widget.points.asMap().entries.map((entry) {
            final idx = entry.key;
            final pt = entry.value;
            final isSelected = _selectedPointIndex == idx;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPointIndex = idx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Text(
                      pt.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _handleTouch(Offset localPos) {
    if (widget.points.isEmpty) return;
    final width = context.size?.width ?? 300;
    const paddingLeft = 32.0;
    const paddingRight = 16.0;
    final chartWidth = width - paddingLeft - paddingRight;

    if (chartWidth <= 0) return;

    final stepX = chartWidth / (widget.points.length - 1);
    final relativeX = localPos.dx - paddingLeft;
    final index = (relativeX / stepX).round().clamp(0, widget.points.length - 1);

    if (_selectedPointIndex != index) {
      HapticFeedback.lightImpact();
      setState(() => _selectedPointIndex = index);
    }
  }

  Widget _buildTooltipBadge(AttendanceChartPoint pt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00D2FF),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${pt.label}: ${pt.percentage.toInt()}% Hadir (${pt.hadir}/${pt.totalHari} hari)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _LineChartPainter extends CustomPainter {
  final List<AttendanceChartPoint> points;
  final double progress;
  final int? selectedIndex;
  final List<Color> lineColors;

  _LineChartPainter({
    required this.points,
    required this.progress,
    required this.selectedIndex,
    required this.lineColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const paddingLeft = 32.0;
    const paddingRight = 16.0;
    const paddingTop = 12.0;
    const paddingBottom = 16.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // 1. Draw Grid Lines (0%, 50%, 100%)
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final gridValues = [100, 50, 0];
    for (final val in gridValues) {
      final y = paddingTop + chartHeight * (1 - (val / 100));

      // Draw dashed horizontal line
      _drawDashedLine(
        canvas,
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Y-axis label
      textPainter.text = TextSpan(
        text: '$val%',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    if (points.length < 2) return;

    // 2. Calculate coordinates for points
    final stepX = chartWidth / (points.length - 1);
    final List<Offset> offsets = [];

    for (int i = 0; i < points.length; i++) {
      final x = paddingLeft + (i * stepX);
      final rawY = points[i].percentage.clamp(0.0, 100.0);
      final y = paddingTop + chartHeight * (1 - (rawY / 100) * progress);
      offsets.add(Offset(x, y));
    }

    // 3. Build Smooth Bezier Path
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      final controlX1 = current.dx + (next.dx - current.dx) / 2;
      final controlY1 = current.dy;
      final controlX2 = current.dx + (next.dx - current.dx) / 2;
      final controlY2 = next.dy;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, next.dx, next.dy);
    }

    // 4. Draw Gradient Fill under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(offsets.last.dx, paddingTop + chartHeight);
    fillPath.lineTo(offsets.first.dx, paddingTop + chartHeight);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColors.first.withValues(alpha: 0.25),
        lineColors.last.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, paddingTop, size.width, chartHeight),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Glowing Line Stroke
    final strokeGradient = LinearGradient(
      colors: lineColors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    // Glow blur
    final glowPaint = Paint()
      ..shader = strokeGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);

    // Sharp stroke
    final strokePaint = Paint()
      ..shader = strokeGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // 6. Draw Dots for Points
    for (int i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final isSelected = selectedIndex == i;

      // Outer glow circle
      final dotGlowPaint = Paint()
        ..color = (isSelected ? const Color(0xFF00D2FF) : lineColors.last)
            .withValues(alpha: isSelected ? 0.6 : 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, isSelected ? 8 : 5, dotGlowPaint);

      // Inner solid point
      final dotPaint = Paint()
        ..color = isSelected ? const Color(0xFF00D2FF) : lineColors.first
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, isSelected ? 5 : 3.5, dotPaint);

      // Center white core
      final whiteCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, isSelected ? 2.5 : 1.5, whiteCore);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(math.min(startX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
