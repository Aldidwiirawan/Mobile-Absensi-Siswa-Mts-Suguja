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

  bool _isProcessing = false;
  String? _lastScan;
  DateTime _lastScanTime = DateTime.now();
  Color _borderColor = const Color(0xFF3B82F6); // Initial blue glow

  Widget? _currentPopup;
  Timer? _popupTimer;

  @override
  void dispose() {
    _popupTimer?.cancel();
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
          setState(() => _currentPopup = null);
        },
      );
    });

    _popupTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() => _currentPopup = null);
      }
    });
  }

  Future<void> _handleScan(String result) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    // Debounce: Prevent scanning same code within 2 seconds
    if (result == _lastScan &&
        now.difference(_lastScanTime).inMilliseconds <
            UiConstants.scanDebounceMs) {
      return;
    }

    _lastScan = result;
    _lastScanTime = now;

    setState(() {
      _isProcessing = true;
      _borderColor = const Color(0xFFFBBF24); // Amber scanning color
    });

    try {
      // Find student by NIS
      final siswaData = await _siswaRepository.findForScan(result);

      if (siswaData == null) {
        throw StudentNotFoundException(
          message: 'Siswa tidak ditemukan',
          nis: result,
        );
      }

      // Process attendance
      // `result` is the scanned NIS value from the QR code
      final absensiResult = await _absensiRepository.processCheckIn(
        siswaId: siswaData.id,
        nis: result,
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
              nis: result,
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
              nis: result,
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
            nis: result,
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
          nis: result,
          statusTitle: 'PERINGATAN',
          statusSubtitle: absensiResult.message.replaceAll('\n${siswaData.nama}', ''),
          type: ScanFeedbackType.warning,
        );
      }
    } on StudentNotFoundException catch (e) {
      HapticFeedback.vibrate();
      if (mounted) setState(() => _borderColor = const Color(0xFFEF4444));
      _showResultPopup(
        namaSiswa: 'NIS: ${e.nis ?? result}',
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
      // Delay before resetting standby border color
      await Future.delayed(const Duration(milliseconds: 1600));
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _borderColor = const Color(0xFF3B82F6);
        });
      }
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
