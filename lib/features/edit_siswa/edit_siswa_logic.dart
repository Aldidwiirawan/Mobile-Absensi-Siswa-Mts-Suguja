import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/onesignal_service.dart';

/// Logic class for Edit Siswa screen using ChangeNotifier
class EditSiswaLogic extends ChangeNotifier {
  final AbsensiRepository _absensiRepository = AbsensiRepository();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  File? selectedFile;

  /// Fetch existing keterangan from database for initial load
  Future<String?> fetchInitialKeterangan({
    required int siswaId,
    required DateTime tanggal,
  }) async {
    try {
      final absensi = await _absensiRepository.getAbsensiByDate(
        siswaId: siswaId,
        tanggal: tanggal,
      );
      return absensi?.keterangan;
    } catch (e) {
      debugPrint('Error fetchInitialKeterangan: $e');
      return null;
    }
  }

  /// Pick image from camera or gallery
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (picked != null) {
        selectedFile = File(picked.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error pick image: $e');
    }
  }

  /// Clear selected file
  void clearSelectedFile() {
    selectedFile = null;
    notifyListeners();
  }

  /// Submit attendance update
  Future<bool> submitAbsensi({
    required int siswaId,
    required DateTime tanggal,
    required String status,
    String? keterangan,
    String? namaSiswa,
    String? oldSuratUrl,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final attendanceStatus = AttendanceStatus.fromValue(status);

      // 1. Always upsert the main attendance status with keterangan & cleared time if alfa/sakit/izin
      final absensiSuccess = await _absensiRepository.upsertAbsensi(
        siswaId: siswaId,
        tanggal: tanggal,
        status: attendanceStatus,
        keterangan: keterangan,
      );

      if (!absensiSuccess) {
        throw Exception('Failed to update attendance status');
      }

      // 2. Handle document logic based on status
      if (attendanceStatus.requiresDocument) {
        // For 'Sakit' or 'Izin', if a new file is selected, upsert it.
        if (selectedFile != null) {
          await _absensiRepository.upsertSurat(
            siswaId: siswaId,
            tanggal: tanggal,
            status: attendanceStatus,
            file: selectedFile!,
          );
        }
      } else {
        // For other statuses, if there was an old surat, delete it.
        if (oldSuratUrl != null && oldSuratUrl.isNotEmpty) {
          await _absensiRepository.deleteSurat(
            siswaId: siswaId,
            tanggal: tanggal,
          );
        }
      }

      // 3. Send notification to parents if status is not hadir / updated
      if (namaSiswa != null && namaSiswa.isNotEmpty) {
        try {
          final tglStr = DateFormat('yyyy-MM-dd').format(tanggal);
          await OneSignalService.sendAbsensiStatusUpdateNotification(
            siswaId: siswaId,
            namaSiswa: namaSiswa,
            status: attendanceStatus.value,
            tanggal: tglStr,
            keterangan: keterangan,
          );
        } catch (e) {
          debugPrint('Error sending status notification: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error Submit: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
