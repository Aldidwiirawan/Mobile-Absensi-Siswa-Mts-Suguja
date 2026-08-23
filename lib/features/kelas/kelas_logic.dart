import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Logic class for Class (Kelas) screen using ChangeNotifier with search & status filter
class KelasLogic extends ChangeNotifier {
  final SiswaRepository _siswaRepository = SiswaRepository();

  // State Data
  List<SiswaWithAbsensi> _originalList = [];
  List<SiswaWithAbsensi> filteredList = [];

  bool isLoading = true;
  String errorMessage = '';

  // Filter State
  String selectedFilter = 'all'; // 'all', 'hadir', 'terlambat', 'sakit_izin', 'alfa', 'belum'

  // Search State
  final TextEditingController searchController = TextEditingController();

  // Timer for auto-refresh
  Timer? _autoRefreshTimer;

  // Current class name
  String currentClassName = '';

  void init(String namaKelas) {
    currentClassName = namaKelas;
    fetchData();
    _startAutoRefresh();
    searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: UiConstants.autoRefreshSeconds),
      (_) => fetchData(isBackground: true),
    );
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    _applyFilters();
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase().trim();

    filteredList = _originalList.where((s) {
      // 1. Check search query
      final matchesQuery = query.isEmpty || s.nama.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      // 2. Check status filter
      if (selectedFilter == 'all') return true;

      final status = s.statusAbsensi?.toLowerCase();
      if (selectedFilter == 'hadir') {
        return status == 'hadir' || status == 'pulang';
      } else if (selectedFilter == 'terlambat') {
        return status == 'terlambat';
      } else if (selectedFilter == 'sakit_izin') {
        return status == 'sakit' || status == 'izin';
      } else if (selectedFilter == 'alfa') {
        return status == 'alfa';
      } else if (selectedFilter == 'belum') {
        return status == null;
      }
      return true;
    }).toList();

    notifyListeners();
  }

  // Count Getters for quick badges
  int get totalCount => _originalList.length;
  int get hadirCount => _originalList
      .where((s) => s.statusAbsensi == 'hadir' || s.statusAbsensi == 'pulang')
      .length;
  int get terlambatCount =>
      _originalList.where((s) => s.statusAbsensi == 'terlambat').length;
  int get sakitIzinCount => _originalList
      .where((s) => s.statusAbsensi == 'sakit' || s.statusAbsensi == 'izin')
      .length;
  int get alfaCount =>
      _originalList.where((s) => s.statusAbsensi == 'alfa').length;

  Future<void> fetchData({bool isBackground = false}) async {
    if (!isBackground) {
      isLoading = true;
      errorMessage = '';
      notifyListeners();
    }

    try {
      final dataList =
          await _siswaRepository.getStudentsByClassToday(currentClassName);

      // Sort by name alphabetically
      dataList.sort((a, b) => a.nama.compareTo(b.nama));

      // Assign sequential number
      for (int i = 0; i < dataList.length; i++) {
        dataList[i] = dataList[i].copyWith(no: i + 1);
      }

      _originalList = dataList;
      _applyFilters();
    } catch (e) {
      if (!isBackground) {
        errorMessage = 'Gagal memuat data: $e';
      }
      debugPrint('Error KelasLogic: $e');
    } finally {
      if (!isBackground) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Get status display text
  String getStatusDisplay(SiswaWithAbsensi item) {
    if (item.statusAbsensi == null) return 'Belum Absen';
    final st = item.statusAbsensi!.toLowerCase();
    if (st == 'hadir') return 'Hadir';
    if (st == 'terlambat') return 'Terlambat';
    if (st == 'sakit') return 'Sakit';
    if (st == 'izin') return 'Izin';
    if (st == 'alfa') return 'Alfa';
    if (st == 'pulang') return 'Pulang';
    return item.statusAbsensi!.toUpperCase();
  }

  /// Get status color
  Color getStatusColor(SiswaWithAbsensi item) {
    if (item.statusAbsensi == null) return const Color(0xFF94A3B8);
    return StatusColors.getAttendanceColor(item.statusAbsensi);
  }
}
