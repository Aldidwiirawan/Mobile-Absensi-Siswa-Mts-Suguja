import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Logic class for Dashboard using ChangeNotifier
class DashboardLogic extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final SuratRepository _suratRepository = SuratRepository();

  bool isLoading = true;
  String errorMessage = '';

  // Data Profil Guru
  Guru? guruProfile;
  Map<String, List<String>> kelasDiampu = {};

  // Data Dashboard
  List<ClassSummary> summaryList = [];
  double attendanceRate = 0.0;
  int pendingSuratCount = 0;

  Timer? _autoRefreshTimer;

  int get totalSiswa =>
      summaryList.fold<int>(0, (sum, item) => sum + item.totalSiswa);

  int get totalHadir =>
      summaryList.fold<int>(0, (sum, item) => sum + item.totalPresent);

  Future<void> loadDashboard({bool isBackground = false}) async {
    if (!isBackground) {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
    }

    try {
      // 1. Get Guru Profile
      guruProfile = await _authRepository.getCurrentGuruProfile();
      if (guruProfile == null) {
        throw AuthException(message: 'User tidak terautentikasi.');
      }

      // Parse kelas_diampu from profile
      if (guruProfile!.kelasDiampu != null) {
        kelasDiampu = guruProfile!.kelasDiampu!;
      }

      // 2. Get Dashboard Summary via RPC & Pending Surat count in parallel
      final summaryFuture = _authRepository.getDashboardSummary();
      final pendingSuratFuture = _suratRepository.getPendingSuratCount();

      final results = await Future.wait([summaryFuture, pendingSuratFuture]);

      summaryList = results[0] as List<ClassSummary>;
      pendingSuratCount = results[1] as int;

      // Calculate Global Attendance Rate
      final total = totalSiswa;
      final present = totalHadir;

      attendanceRate = total == 0 ? 0 : (present / total) * 100;
    } on AppException catch (e) {
      if (!isBackground) {
        errorMessage = 'Gagal memuat data: ${e.message}';
      }
      debugPrint('Dashboard Error: ${e.message}');
    } catch (e) {
      if (!isBackground) {
        errorMessage = 'Gagal memuat data: $e';
      }
      debugPrint('Dashboard Error: $e');
    } finally {
      if (!isBackground) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: UiConstants.autoRefreshSeconds),
      (_) => loadDashboard(isBackground: true),
    );
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  Future<void> logout() async {
    stopAutoRefresh();
    await _authRepository.signOut();
  }
}
