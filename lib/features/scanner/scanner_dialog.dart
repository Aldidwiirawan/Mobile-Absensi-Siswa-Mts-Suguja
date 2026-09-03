import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../../core/ui/scan_result_sheet.dart';
import '../../data/repositories/repositories.dart';
import 'scanner_widget.dart';

/// Scanner dialog with continuous scanning, haptic feedback, and celebratory animated popups
class ContinuousScannerDialog extends StatefulWidget {
  const ContinuousScannerDialog({super.key});

  @override
  State<ContinuousScannerDialog> createState() =>
      _ContinuousScannerDialogState();
}

class _ContinuousScannerDialogState extends State<ContinuousScannerDialog> {
  final SiswaRepository _siswaRepository = SiswaRepository();
  final AbsensiRepository _absensiRepository = AbsensiRepository();

  // Track recent scan times per NIS (prevents duplicate scans of the SAME student)
  final Map<String, DateTime> _recentScans = {};
  final Set<String> _inFlightNis = {};

  Color _borderColor = const Color(0xFF3B82F6); // Initial blue glow
  Timer? _borderResetTimer;

  Widget? _currentPopup;
  Timer? _popupTimer;

  @override
  void dispose() {
    _popupTimer?.cancel();
    _borderResetTimer?.cancel();
    super.dispose();
  }

  void _showResultPopup({
    required String namaSiswa,
    String? nis,
    required String statusTitle,
    required String statusSubtitle,
    required ScanFeedbackType type,
  }) {
    _popupTimer?.cancel();
    final nowTime = DateFormat('HH:mm').format(DateTime.now());

    setState(() {
      _currentPopup = ScanResultPopup(
        namaSiswa: namaSiswa,
        nis: nis,
        statusTitle: statusTitle,
        statusSubtitle: statusSubtitle,
        time: nowTime,
        type: type,
        onDismiss: () {
          _popupTimer?.cancel();
          if (mounted) setState(() => _currentPopup = null);
        },
      );
    });

    _popupTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() => _currentPopup = null);
      }
    });
  }

  Future<void> _handleScan(String result) async {
    final nis = result.trim();
    if (nis.isEmpty) return;

    final now = DateTime.now();

    // 1. Debounce only for the EXACT SAME student (prevent double scan within 2s)
    final lastScanTime = _recentScans[nis];
    if (lastScanTime != null &&
        now.difference(lastScanTime).inMilliseconds <
            UiConstants.scanDebounceMs) {
      return;
    }

    // 2. Prevent concurrent processing of the exact same NIS
    if (_inFlightNis.contains(nis)) return;

    _recentScans[nis] = now;
    _inFlightNis.add(nis);

    // Clean up memory cache for very old scans
    if (_recentScans.length > 60) {
      _recentScans.removeWhere((_, time) => now.difference(time).inSeconds > 10);
    }

    // Immediate scanning glow visual feedback
    _borderResetTimer?.cancel();
    if (mounted) {
      setState(() => _borderColor = const Color(0xFFFBBF24));
    }

    try {
      // Find student by NIS (instant via memory cache)
      final siswaData = await _siswaRepository.findForScan(nis);

      if (siswaData == null) {
        throw StudentNotFoundException(
          message: 'Siswa tidak ditemukan',
          nis: nis,
        );
      }

      // Process attendance
      final absensiResult = await _absensiRepository.processCheckIn(
        siswaId: siswaData.id,
        nis: nis,
        namaSiswa: siswaData.nama,
        kelasId: siswaData.kelasId,
      );

      if (absensiResult.success) {
        // Success Haptic Feedback
        HapticFeedback.heavyImpact();

        if (absensiResult.isCheckIn) {
          if (absensiResult.isLate) {
            // Late Check-in
            if (mounted) {
              setState(() => _borderColor = const Color(0xFFF59E0B));
            }
            _showResultPopup(
              namaSiswa: siswaData.nama,
              nis: nis,
              statusTitle: 'TERLAMBAT',
              statusSubtitle:
                  'Terlambat ${absensiResult.lateMinutes ?? 0} menit. Tetap semangat!',
              type: ScanFeedbackType.late,
            );
          } else {
            // On-time Check-in
            if (mounted) {
              setState(() => _borderColor = const Color(0xFF10B981));
            }
            _showResultPopup(
              namaSiswa: siswaData.nama,
              nis: nis,
              statusTitle: 'HADIR TEPAT WAKTU 🌟',
              statusSubtitle: 'Presensi masuk berhasil dicatat. Selamat belajar!',
              type: ScanFeedbackType.success,
            );
          }
        } else {
          // Check-out (Pulang)
          if (mounted) {
            setState(() => _borderColor = const Color(0xFF06B6D4));
          }
          _showResultPopup(
            namaSiswa: siswaData.nama,
            nis: nis,
            statusTitle: 'ABSEN PULANG 👋',
            statusSubtitle: 'Presensi pulang berhasil. Hati-hati di perjalanan!',
            type: ScanFeedbackType.pulang,
          );
        }
      } else {
        // Warning (e.g., Belum jam pulang / double scan)
        HapticFeedback.vibrate();
        if (mounted) {
          setState(() => _borderColor = const Color(0xFFF97316));
        }
        _showResultPopup(
          namaSiswa: siswaData.nama,
          nis: nis,
          statusTitle: 'PERINGATAN',
          statusSubtitle:
              absensiResult.message.replaceAll('\n${siswaData.nama}', ''),
          type: ScanFeedbackType.warning,
        );
      }
    } on StudentNotFoundException catch (e) {
      HapticFeedback.vibrate();
      if (mounted) setState(() => _borderColor = const Color(0xFFEF4444));
      _showResultPopup(
        namaSiswa: 'NIS: ${e.nis ?? nis}',
        statusTitle: 'TIDAK TERDAFTAR',
        statusSubtitle: 'Data siswa belum terdaftar di database.',
        type: ScanFeedbackType.error,
      );
    } on AttendanceException catch (e) {
      HapticFeedback.vibrate();
      if (mounted) setState(() => _borderColor = const Color(0xFFEF4444));
      _showResultPopup(
        namaSiswa: 'Gagal Memproses',
        statusTitle: 'ERROR',
        statusSubtitle: e.message,
        type: ScanFeedbackType.error,
      );
    } catch (e) {
      HapticFeedback.vibrate();
      if (mounted) setState(() => _borderColor = const Color(0xFFEF4444));
      _showResultPopup(
        namaSiswa: 'Terjadi Kesalahan',
        statusTitle: 'ERROR SISTEM',
        statusSubtitle: '$e',
        type: ScanFeedbackType.error,
      );
    } finally {
      _inFlightNis.remove(nis);

      // Reset border color to standby non-blockingly without delaying next scan
      _borderResetTimer?.cancel();
      _borderResetTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted && _inFlightNis.isEmpty) {
          setState(() {
            _borderColor = const Color(0xFF3B82F6);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeScannerPage(
      onResult: _handleScan,
      borderColor: _borderColor,
      overlayPopup: _currentPopup,
    );
  }
}
