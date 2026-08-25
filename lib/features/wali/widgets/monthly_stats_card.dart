import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/animated_counter.dart';
import '../../../core/ui/bouncing_widget.dart';
import '../../../data/models/wali_murid_models.dart';
import 'attendance_line_chart.dart';

enum StatsViewMode { summary, lineChart }

/// Monthly Attendance Statistics Card with interactive Line Chart and Ring progress
class MonthlyStatsCard extends StatefulWidget {
  final MonthlyAttendanceStats stats;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthlyStatsCard({
    super.key,
    required this.stats,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  State<MonthlyStatsCard> createState() => _MonthlyStatsCardState();
}

class _MonthlyStatsCardState extends State<MonthlyStatsCard> {
  StatsViewMode _viewMode = StatsViewMode.summary;

  @override
  Widget build(BuildContext context) {
    final monthName =
        DateFormat('MMMM yyyy', 'id_ID').format(widget.selectedMonth);
    final rate = widget.stats.attendancePercentage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header & Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rekap & Tren Kehadiran',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            monthName,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Month switcher controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMonthArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      final prev = DateTime(
                        widget.selectedMonth.year,
                        widget.selectedMonth.month - 1,
                        1,
                      );
                      widget.onMonthChanged(prev);
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildMonthArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      final next = DateTime(
                        widget.selectedMonth.year,
                        widget.selectedMonth.month + 1,
                        1,
                      );
                      final now = DateTime.now();
                      if (next.year < now.year ||
                          (next.year == now.year && next.month <= now.month)) {
                        widget.onMonthChanged(next);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // View Switcher (Ringkasan vs Grafik Garis)
          _buildViewModeToggle(),
          const SizedBox(height: 14),

          // Animated CrossFade for [Summary Ring View] vs [Line Chart View]
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _viewMode == StatsViewMode.summary
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildSummaryBanner(rate),
            secondChild: _buildLineChartSection(),
          ),
          const SizedBox(height: 16),

          // Grid of 5 Status Count Chips
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Hadir',
                  count: widget.stats.totalHadir,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Telat',
                  count: widget.stats.totalTerlambat,
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFFBEB),
                  icon: Icons.access_time_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Sakit',
                  count: widget.stats.totalSakit,
                  color: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                  icon: Icons.medical_services_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Izin',
                  count: widget.stats.totalIzin,
                  color: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFF5F3FF),
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Alfa',
                  count: widget.stats.totalAlfa,
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEF2F2),
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(
          begin: 0.05,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Tab 1: Ringkasan
          Expanded(
            child: BouncingWidget(
              onTap: () {
                if (_viewMode != StatsViewMode.summary) {
                  HapticFeedback.selectionClick();
                  setState(() => _viewMode = StatsViewMode.summary);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _viewMode == StatsViewMode.summary
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _viewMode == StatsViewMode.summary
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 15,
                      color: _viewMode == StatsViewMode.summary
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Ringkasan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _viewMode == StatsViewMode.summary
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 2: Grafik Garis
          Expanded(
            child: BouncingWidget(
              onTap: () {
                if (_viewMode != StatsViewMode.lineChart) {
                  HapticFeedback.selectionClick();
                  setState(() => _viewMode = StatsViewMode.lineChart);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _viewMode == StatsViewMode.lineChart
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _viewMode == StatsViewMode.lineChart
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 16,
                      color: _viewMode == StatsViewMode.lineChart
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Grafik Garis',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _viewMode == StatsViewMode.lineChart
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(double rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Animated Progress Ring
          AnimatedAttendanceRing(
            rate: rate,
            size: 78,
            strokeWidth: 8,
            gradientColors: _getRingGradient(rate),
          ),
          const SizedBox(width: 16),

          // Text Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPerformanceTitle(rate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getPerformanceSubtitle(rate, widget.stats),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.timeline_rounded,
                        size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Tren Mingguan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tap titik info',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Bezier Line Chart
          AttendanceLineChart(
            points: widget.stats.weeklyTrend,
            height: 145,
            lineColors: const [Color(0xFF2563EB), Color(0xFF00D2FF)],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return BouncingWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedCountText(
                  value: count,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  'hari',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getRingGradient(double rate) {
    if (widget.stats.totalTercatat == 0) {
      return [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)];
    }
    if (rate >= 90) return [const Color(0xFF34D399), const Color(0xFF00FF87)];
    if (rate >= 75) return [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
    return [const Color(0xFFF87171), const Color(0xFFEF4444)];
  }

  String _getPerformanceTitle(double rate) {
    if (widget.stats.totalTercatat == 0) return 'Belum Ada Data ⏳';
    if (rate >= 95) return 'Kehadiran Prima ⭐';
    if (rate >= 85) return 'Kehadiran Baik 👍';
    if (rate >= 75) return 'Perlu Ditingkatkan ⚠️';
    return 'Perhatian Khusus ❗';
  }

  String _getPerformanceSubtitle(double rate, MonthlyAttendanceStats st) {
    if (widget.stats.totalTercatat == 0) {
      return 'Belum ada catatan presensi ananda untuk bulan ini.';
    }
    if (rate >= 90) {
      return 'Ananda sangat disiplin hadir ke sekolah bulan ini.';
    }
    if (rate >= 75) {
      return 'Pertahankan kedisiplinan dan hindari keterlambatan.';
    }
    return 'Jumlah kehadiran ananda di bawah standar minimal.';
  }
}
