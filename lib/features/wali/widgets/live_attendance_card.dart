import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../data/models/wali_murid_models.dart';

/// Live Attendance Card for Parents with dynamic colors, status pulses, and check-in/out timestamps
class LiveAttendanceCard extends StatelessWidget {
  final TodayAttendance attendance;
  final String namaSiswa;
  final VoidCallback? onRefresh;

  const LiveAttendanceCard({
    super.key,
    required this.attendance,
    required this.namaSiswa,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    final statusConfig = _getStatusConfig(attendance);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: statusConfig.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: statusConfig.shadowColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background decorative glow shapes
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Date & Live Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Live Pulse Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pulsing Dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusConfig.dotColor,
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat())
                                .scale(
                                  duration: 1000.ms,
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.5, 1.5),
                                )
                                .then()
                                .scale(
                                  duration: 1000.ms,
                                  begin: const Offset(1.5, 1.5),
                                  end: const Offset(1, 1),
                                ),
                            const SizedBox(width: 6),
                            const Text(
                              'HARI INI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Main Status Heading & Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          statusConfig.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusConfig.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              statusConfig.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Timestamp Cards: Masuk & Pulang
                  Row(
                    children: [
                      // Card Masuk
                      Expanded(
                        child: _buildTimeBox(
                          title: 'JAM MASUK',
                          time: attendance.waktuMasuk != null
                              ? '${attendance.waktuMasuk!.substring(0, 5)} WIB'
                              : '-- : --',
                          icon: Icons.login_rounded,
                          isFilled: attendance.hasScannedMasuk,
                          badgeText: attendance.isLate
                              ? 'Telat ${attendance.lateMinutes ?? 0} mnt'
                              : (attendance.hasScannedMasuk ? 'Tepat Waktu' : 'Belum Scan'),
                          badgeColor: attendance.isLate
                              ? const Color(0xFFEF4444)
                              : (attendance.hasScannedMasuk
                                  ? const Color(0xFF10B981)
                                  : Colors.white24),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Card Pulang
                      Expanded(
                        child: _buildTimeBox(
                          title: 'JAM PULANG',
                          time: attendance.waktuPulang != null
                              ? '${attendance.waktuPulang!.substring(0, 5)} WIB'
                              : '-- : --',
                          icon: Icons.logout_rounded,
                          isFilled: attendance.hasScannedPulang,
                          badgeText: attendance.hasScannedPulang
                              ? 'Selesai'
                              : (attendance.hasScannedMasuk ? 'Di Sekolah' : 'Belum Ada'),
                          badgeColor: attendance.hasScannedPulang
                              ? const Color(0xFF10B981)
                              : (attendance.hasScannedMasuk
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.05,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildTimeBox({
    required String title,
    required String time,
    required IconData icon,
    required bool isFilled,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                icon,
                color: isFilled ? Colors.white : Colors.white38,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(TodayAttendance att) {
    if (att.hasScannedPulang) {
      return _StatusConfig(
        title: 'Sudah Pulang',
        subtitle: 'Ananda telah menyelesaikan kegiatan belajar hari ini.',
        icon: Icons.home_rounded,
        dotColor: const Color(0xFF00E5FF),
        gradientColors: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        shadowColor: const Color(0xFF0284C7),
      );
    }

    if (att.hasScannedMasuk) {
      if (att.isLate) {
        return _StatusConfig(
          title: 'Hadir (Terlambat)',
          subtitle: 'Ananda tiba terlambat ${att.lateMinutes ?? 0} menit di sekolah.',
          icon: Icons.warning_amber_rounded,
          dotColor: const Color(0xFFFBBF24),
          gradientColors: [const Color(0xFFD97706), const Color(0xFFB45309)],
          shadowColor: const Color(0xFFD97706),
        );
      }
      return _StatusConfig(
        title: 'Di Sekolah (Tepat Waktu)',
        subtitle: 'Alhamdulillah, Ananda hadir tepat waktu dan sedang belajar.',
        icon: Icons.check_circle_rounded,
        dotColor: const Color(0xFF34D399),
        gradientColors: [const Color(0xFF059669), const Color(0xFF047857)],
        shadowColor: const Color(0xFF059669),
      );
    }

    if (att.status == AttendanceStatus.sakit) {
      return _StatusConfig(
        title: 'Izin Sakit',
        subtitle: 'Tercatat izin sakit untuk hari ini.',
        icon: Icons.medical_services_rounded,
        dotColor: const Color(0xFF60A5FA),
        gradientColors: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
        shadowColor: const Color(0xFF2563EB),
      );
    }

    if (att.status == AttendanceStatus.izin) {
      return _StatusConfig(
        title: 'Izin Berhalangan',
        subtitle: 'Tercatat izin tidak masuk sekolah hari ini.',
        icon: Icons.assignment_rounded,
        dotColor: const Color(0xFFC084FC),
        gradientColors: [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
        shadowColor: const Color(0xFF7C3AED),
      );
    }

    return _StatusConfig(
      title: 'Menunggu Presensi',
      subtitle: 'Belum ada catatan presensi masuk hari ini.',
      icon: Icons.schedule_rounded,
      dotColor: const Color(0xFF94A3B8),
      gradientColors: [const Color(0xFF334155), const Color(0xFF1E293B)],
      shadowColor: const Color(0xFF334155),
    );
  }
}

class _StatusConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color dotColor;
  final List<Color> gradientColors;
  final Color shadowColor;

  _StatusConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dotColor,
    required this.gradientColors,
    required this.shadowColor,
  });
}
