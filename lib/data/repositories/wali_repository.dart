import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/wali_storage_service.dart';

/// Repository for Wali Murid (Parent Portal) data access
class WaliRepository {
  final SupabaseClient _client = supabaseService.client;

  /// Authenticate parent using Student's NIS
  Future<ChildProfile> loginWithNis({
    required String nis,
  }) async {
    final cleanNis = nis.trim();

    if (cleanNis.isEmpty) {
      throw ValidationException(message: 'NIS tidak boleh kosong');
    }

    try {
      // 1. Fetch student by NIS
      final siswaRes = await _client
          .from(DbTables.siswa)
          .select()
          .eq(SiswaColumns.nis, cleanNis)
          .maybeSingle();

      debugPrint('--- [WaliRepo Login] Data Siswa Ditemukan: $siswaRes ---');

      if (siswaRes == null) {
        throw ValidationException(
          message: 'Data siswa dengan NIS $cleanNis tidak ditemukan di sistem.',
        );
      }

      final siswaId = siswaRes[SiswaColumns.id] as int;
      final namaSiswa = siswaRes[SiswaColumns.nama] as String? ?? 'Siswa';
      final rawKelasId = siswaRes['kelas_id'] ??
          siswaRes['id_kelas'] ??
          siswaRes['kelasId'] ??
          siswaRes[SiswaColumns.kelasId];

      final int? kelasId = rawKelasId is int
          ? rawKelasId
          : (rawKelasId != null ? int.tryParse(rawKelasId.toString()) : null);

      debugPrint('--- [WaliRepo Login] rawKelasId: $rawKelasId, parsed: $kelasId ---');

      // 2. Fetch Class Details & Wali Kelas with robust UUID/Int and fallback resolution
      final waliInfo = await _resolveWaliKelasInfo(
        kelasId,
        siswaRes['nama_kelas']?.toString(),
      );

      return ChildProfile(
        id: siswaId,
        nis: cleanNis,
        nama: namaSiswa,
        kelasId: kelasId,
        namaKelas: waliInfo.namaKelas,
        waliKelasNama: waliInfo.waliKelasNama,
        waliKelasNoHp: waliInfo.waliKelasNoHp,
      );
    } on PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal memverifikasi login orang tua: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Refresh / fetch fresh ChildProfile by student ID
  Future<ChildProfile?> getChildProfileById(int siswaId) async {
    try {
      final siswaRes = await _client
          .from(DbTables.siswa)
          .select()
          .eq(SiswaColumns.id, siswaId)
          .maybeSingle();

      debugPrint('--- [WaliRepo Refresh] Data Siswa Ditemukan: $siswaRes ---');

      if (siswaRes == null) return null;

      final cleanNis = siswaRes[SiswaColumns.nis] as String? ?? '';
      final namaSiswa = siswaRes[SiswaColumns.nama] as String? ?? 'Siswa';
      final rawKelasId = siswaRes['kelas_id'] ??
          siswaRes['id_kelas'] ??
          siswaRes['kelasId'] ??
          siswaRes[SiswaColumns.kelasId];

      final int? kelasId = rawKelasId is int
          ? rawKelasId
          : (rawKelasId != null ? int.tryParse(rawKelasId.toString()) : null);

      final waliInfo = await _resolveWaliKelasInfo(
        kelasId,
        siswaRes['nama_kelas']?.toString(),
      );

      return ChildProfile(
        id: siswaId,
        nis: cleanNis,
        nama: namaSiswa,
        kelasId: kelasId,
        namaKelas: waliInfo.namaKelas,
        waliKelasNama: waliInfo.waliKelasNama,
        waliKelasNoHp: waliInfo.waliKelasNoHp,
      );
    } catch (e) {
      debugPrint('[WaliRepo] Error getChildProfileById: $e');
      return null;
    }
  }

  /// Helper to robustly resolve class name and homeroom teacher (Wali Kelas) info
  Future<({String namaKelas, String? waliKelasNama, String? waliKelasNoHp})>
      _resolveWaliKelasInfo(int? kelasId, String? defaultNamaKelas) async {
    String namaKelas = defaultNamaKelas ?? 'Belum Ditentukan';
    String? waliKelasNama;
    String? waliKelasNoHp;

    if (kelasId != null) {
      try {
        final kelasRes = await _client
            .from(DbTables.kelas)
            .select()
            .eq(KelasColumns.id, kelasId)
            .maybeSingle();

        debugPrint('--- [WaliRepo] Hasil Query Kelas ($kelasId): $kelasRes ---');

        if (kelasRes != null) {
          namaKelas = kelasRes['nama_kelas'] as String? ??
              kelasRes['nama'] as String? ??
              kelasRes['tingkat'] as String? ??
              'Kelas $kelasId';

          final rawWaliId = kelasRes['wali_kelas_id'] ?? kelasRes['wali_id'];

          if (rawWaliId != null && rawWaliId.toString().isNotEmpty) {
            try {
              final guruRes = await _client
                  .from(DbTables.guru)
                  .select()
                  .eq('id', rawWaliId)
                  .maybeSingle();

              debugPrint('--- [WaliRepo] Hasil Query Guru Wali ($rawWaliId): $guruRes ---');

              if (guruRes != null) {
                waliKelasNama = guruRes['nama'] as String?;
                waliKelasNoHp = guruRes['no_hp'] as String? ??
                    guruRes['no_telepon'] as String? ??
                    guruRes['telepon'] as String?;
              }
            } catch (err) {
              debugPrint('--- [WaliRepo] Gagal query guru by id $rawWaliId: $err ---');
            }
          }
        }
      } catch (e) {
        debugPrint('--- [WaliRepo] Gagal memuat data kelas/wali kelas: $e ---');
      }
    }

    // Fallback: If waliKelasNoHp is still null, search table guru for teacher assigned to this class name
    if (waliKelasNoHp == null || waliKelasNoHp.isEmpty) {
      try {
        final allGurus = await _client.from(DbTables.guru).select();
        for (final g in (allGurus as List)) {
          final kDiampu = g['kelas_diampu'];
          final gNoHp = g['no_hp'] as String? ??
              g['no_telepon'] as String? ??
              g['telepon'] as String?;

          if (gNoHp != null && gNoHp.isNotEmpty) {
            if (kDiampu != null && kDiampu.toString().contains(namaKelas)) {
              waliKelasNama ??= g['nama'] as String?;
              waliKelasNoHp = gNoHp;
              debugPrint('--- [WaliRepo] Found wali kelas via kelas_diampu ($namaKelas): ${g['nama']} ($gNoHp) ---');
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('--- [WaliRepo] Fallback search guru by kelas_diampu error: $e ---');
      }
    }

    return (
      namaKelas: namaKelas,
      waliKelasNama: waliKelasNama,
      waliKelasNoHp: waliKelasNoHp,
    );
  }

  /// Alias for login using NIS
  Future<ChildProfile> loginWithNisPin({
    required String nis,
    String? pin,
  }) => loginWithNis(nis: nis);

  /// Get today's attendance status for a student
  Future<TodayAttendance> getTodayAttendance(int siswaId, {int? kelasId}) async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      // Get target class schedule
      String targetJamMasuk = Kelas.defaultJamMasuk;
      if (kelasId != null) {
        try {
          final kelasRes = await _client
              .from(DbTables.kelas)
              .select('${KelasColumns.jamMasuk}, ${KelasColumns.jamPulang}')
              .eq(KelasColumns.id, kelasId)
              .maybeSingle();
          if (kelasRes != null && kelasRes[KelasColumns.jamMasuk] != null) {
            targetJamMasuk = kelasRes[KelasColumns.jamMasuk] as String;
          }
        } catch (_) {}
      }

      final response = await _client
          .from(DbTables.absensi)
          .select()
          .eq(AbsensiColumns.siswaId, siswaId)
          .eq(AbsensiColumns.tanggal, todayStr)
          .maybeSingle();

      if (response == null) {
        return TodayAttendance.empty(siswaId);
      }

      return TodayAttendance.fromJson(response, targetJamMasuk: targetJamMasuk);
    } on PostgrestException catch (e) {
      debugPrint('[WaliRepo] Error fetching today attendance: ${e.message}');
      return TodayAttendance.empty(siswaId);
    }
  }

  /// Get monthly attendance statistics for a student
  Future<MonthlyAttendanceStats> getMonthlyAttendanceStats({
    required int siswaId,
    required int month,
    required int year,
  }) async {
    try {
      final monthStr = month.toString().padLeft(2, '0');
      final prefix = '$year-$monthStr';

      final response = await _client
          .from(DbTables.absensi)
          .select()
          .eq(AbsensiColumns.siswaId, siswaId)
          .like(AbsensiColumns.tanggal, '$prefix%');

      int hadir = 0;
      int terlambat = 0;
      int sakit = 0;
      int izin = 0;
      int alfa = 0;

      final records = response as List;
      for (final raw in records) {
        final item = raw as Map<String, dynamic>;
        final status = AttendanceStatus.fromValue(item[AbsensiColumns.status] as String?);

        switch (status) {
          case AttendanceStatus.hadir:
          case AttendanceStatus.pulang:
            hadir++;
            break;
          case AttendanceStatus.terlambat:
            terlambat++;
            break;
          case AttendanceStatus.sakit:
            sakit++;
            break;
          case AttendanceStatus.izin:
            izin++;
            break;
          case AttendanceStatus.alfa:
            alfa++;
            break;
        }
      }

      // Estimate total school days up to current date in this month (Mon - Sat)
      final now = DateTime.now();
      final isCurrentMonth = now.year == year && now.month == month;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final maxDay = isCurrentMonth ? now.day : daysInMonth;

      int schoolDays = 0;
      for (int d = 1; d <= maxDay; d++) {
        final date = DateTime(year, month, d);
        if (date.weekday != DateTime.sunday) {
          schoolDays++;
        }
      }

      if (schoolDays == 0) schoolDays = records.isNotEmpty ? records.length : 1;

      // Calculate Weekly Trend for Line Chart (Weeks 1 to 4/5)
      final List<AttendanceChartPoint> weeklyTrend = [];
      final weekRanges = [
        (1, 7, 'Mgg 1'),
        (8, 14, 'Mgg 2'),
        (15, 21, 'Mgg 3'),
        (22, 28, 'Mgg 4'),
        if (daysInMonth > 28) (29, daysInMonth, 'Mgg 5'),
      ];

      for (final range in weekRanges) {
        final startDay = range.$1;
        final endDay = range.$2;
        final label = range.$3;

        // Count school days in this week window
        int weekSchoolDays = 0;
        final actualEndDay = isCurrentMonth && endDay > maxDay ? maxDay : endDay;

        if (startDay <= actualEndDay) {
          for (int d = startDay; d <= actualEndDay; d++) {
            final date = DateTime(year, month, d);
            if (date.weekday != DateTime.sunday) {
              weekSchoolDays++;
            }
          }
        }

        // Count attended in this week window
        int weekAttended = 0;
        for (final raw in records) {
          final item = raw as Map<String, dynamic>;
          final tglStr = item[AbsensiColumns.tanggal] as String? ?? '';
          final tglParts = tglStr.split('-');
          if (tglParts.length == 3) {
            final day = int.tryParse(tglParts[2]) ?? 0;
            if (day >= startDay && day <= endDay) {
              final status = AttendanceStatus.fromValue(item[AbsensiColumns.status] as String?);
              if (status.isPresent || status.isLate) {
                weekAttended++;
              }
            }
          }
        }

        double pct = 0.0;
        if (weekSchoolDays > 0 && weekAttended > 0) {
          pct = ((weekAttended / weekSchoolDays) * 100).clamp(0.0, 100.0);
        } else {
          pct = 0.0;
        }

        weeklyTrend.add(
          AttendanceChartPoint(
            label: label,
            percentage: pct,
            hadir: weekAttended,
            totalHari: weekSchoolDays,
          ),
        );
      }

      return MonthlyAttendanceStats(
        totalHariSekolah: schoolDays,
        totalHadir: hadir,
        totalTerlambat: terlambat,
        totalSakit: sakit,
        totalIzin: izin,
        totalAlfa: alfa,
        bulan: month,
        tahun: year,
        weeklyTrend: weeklyTrend,
      );
    } on PostgrestException catch (e) {
      debugPrint('[WaliRepo] Error fetching monthly stats: ${e.message}');
      return MonthlyAttendanceStats.empty(month, year);
    }
  }

  /// Get student's monthly attendance history
  Future<List<Absensi>> getAttendanceHistory({
    required int siswaId,
    required int month,
    required int year,
  }) async {
    try {
      final monthStr = month.toString().padLeft(2, '0');
      final prefix = '$year-$monthStr';

      final response = await _client
          .from(DbTables.absensi)
          .select()
          .eq(AbsensiColumns.siswaId, siswaId)
          .like(AbsensiColumns.tanggal, '$prefix%')
          .order(AbsensiColumns.tanggal, ascending: false);

      return (response as List).map((json) => Absensi.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      debugPrint('[WaliRepo] Error fetching history: ${e.message}');
      return [];
    }
  }

  /// Get notification feed for child including read status
  Future<List<WaliNotificationItem>> getNotificationsForChild(
      ChildProfile child) async {
    final now = DateTime.now();
    final history = await getAttendanceHistory(
      siswaId: child.id,
      month: now.month,
      year: now.year,
    );

    final readIds = await waliStorageService.getReadNotificationIds();
    final List<WaliNotificationItem> items = [];

    // School Announcement
    const announcementId = 'announcement_mts_1';
    items.add(
      WaliNotificationItem(
        id: announcementId,
        title: '📢 Informasi Kegiatan MTs Sunan Gunung Jati',
        message:
            'Diberitahukan kepada seluruh wali murid bahwa kegiatan belajar mengajar berjalan normal sesuai jadwal kelas.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        type: 'pengumuman',
        isRead: readIds.contains(announcementId),
      ),
    );

    for (final att in history) {
      final tanggal = att.tanggal;

      // Pulang event
      if (att.waktuPulang != null) {
        final id = 'pulang_${att.id}';
        items.add(
          WaliNotificationItem(
            id: id,
            title: '👋 Presensi Pulang: ${child.nama}',
            message:
                'Ananda telah melakukan absensi pulang pukul ${att.waktuPulang!.substring(0, 5)} WIB. Semoga selamat sampai di rumah!',
            timestamp: DateTime.tryParse('$tanggal ${att.waktuPulang}') ??
                DateTime.now(),
            type: 'pulang',
            isRead: readIds.contains(id),
          ),
        );
      }

      // Masuk event
      if (att.waktuMasuk != null) {
        final isLate = att.status == AttendanceStatus.terlambat;
        final id = 'masuk_${att.id}';
        items.add(
          WaliNotificationItem(
            id: id,
            title: isLate
                ? '⚠️ Presensi Masuk (Terlambat): ${child.nama}'
                : '✅ Presensi Masuk: ${child.nama}',
            message: isLate
                ? 'Ananda telah tiba di sekolah pukul ${att.waktuMasuk!.substring(0, 5)} WIB dengan status Terlambat.'
                : 'Alhamdulillah, ananda telah tiba di sekolah tepat waktu pukul ${att.waktuMasuk!.substring(0, 5)} WIB.',
            timestamp: DateTime.tryParse('$tanggal ${att.waktuMasuk}') ??
                DateTime.now(),
            type: isLate ? 'terlambat' : 'masuk',
            isRead: readIds.contains(id),
          ),
        );
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  /// Get unread notification count for child
  Future<int> getUnreadNotificationCount(ChildProfile child) async {
    try {
      final items = await getNotificationsForChild(child);
      return items.where((item) => !item.isRead).length;
    } catch (e) {
      return 0;
    }
  }
}
