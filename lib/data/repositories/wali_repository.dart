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
      // 1. Fetch student by NIS with specific valid columns
      final siswaRes = await _client
          .from(DbTables.siswa)
          .select('${SiswaColumns.id}, ${SiswaColumns.nis}, ${SiswaColumns.nama}, ${SiswaColumns.kelasId}')
          .eq(SiswaColumns.nis, cleanNis)
          .maybeSingle();

      debugPrint('--- [WaliRepo Login] Data Siswa Ditemukan: $siswaRes ---');

      if (siswaRes == null) {
        throw ValidationException(
          message: 'NIS siswa tidak terdaftar di sistem sekolah.',
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
        null,
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
        message: 'Gagal memverifikasi NIS siswa: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Refresh / fetch fresh ChildProfile by student ID
  Future<ChildProfile?> getChildProfileById(int siswaId) async {
    try {
      final siswaRes = await _client
          .from(DbTables.siswa)
          .select('${SiswaColumns.id}, ${SiswaColumns.nis}, ${SiswaColumns.nama}, ${SiswaColumns.kelasId}')
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
        null,
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

        if (kelasRes != null) {
          namaKelas = kelasRes[KelasColumns.namaKelas] as String? ??
              kelasRes['nama'] as String? ??
              'Kelas $kelasId';

          final rawWali = kelasRes['wali_kelas'] ??
              kelasRes['wali_kelas_id'] ??
              kelasRes['wali_id'];

          if (rawWali != null && rawWali.toString().isNotEmpty) {
            final rawWaliStr = rawWali.toString().trim();
            // If rawWali is a teacher name directly
            if (rawWaliStr.length > 3 &&
                !rawWaliStr.contains('-') &&
                int.tryParse(rawWaliStr) == null) {
              waliKelasNama = rawWaliStr;
            }

            try {
              final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(rawWaliStr);
              final isInt = int.tryParse(rawWaliStr) != null;

              var guruQuery = _client
                  .from(DbTables.guru)
                  .select('${GuruColumns.id}, ${GuruColumns.nama}, ${GuruColumns.noHp}');

              if (isUuid || isInt) {
                guruQuery = guruQuery.eq(GuruColumns.id, rawWaliStr);
              } else {
                guruQuery = guruQuery.eq(GuruColumns.nama, rawWaliStr);
              }

              final guruRes = await guruQuery.maybeSingle();

              if (guruRes != null) {
                waliKelasNama = guruRes[GuruColumns.nama] as String? ?? waliKelasNama;
                waliKelasNoHp = guruRes[GuruColumns.noHp] as String?;
              }
            } catch (err) {
              debugPrint('--- [WaliRepo] Info query guru: $err ---');
            }
          }
        }
      } catch (e) {
        debugPrint('--- [WaliRepo] Gagal memuat data kelas: $e ---');
      }
    }

    // Fallback: If waliKelasNoHp is still null, search table guru for teacher assigned to this class name
    if (waliKelasNoHp == null || waliKelasNoHp.isEmpty) {
      try {
        final allGurus = await _client
            .from(DbTables.guru)
            .select('${GuruColumns.id}, ${GuruColumns.nama}, ${GuruColumns.noHp}, ${GuruColumns.kelasDiampu}');
        for (final g in (allGurus as List)) {
          final kDiampu = g[GuruColumns.kelasDiampu];
          final gNoHp = g[GuruColumns.noHp] as String?;

          if (gNoHp != null && gNoHp.isNotEmpty) {
            if (kDiampu != null && kDiampu.toString().contains(namaKelas)) {
              waliKelasNama ??= g[GuruColumns.nama] as String?;
              waliKelasNoHp = gNoHp;
              break;
            }
          }
        }
      } catch (_) {}
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
          .select('${AbsensiColumns.id}, ${AbsensiColumns.siswaId}, ${AbsensiColumns.tanggal}, ${AbsensiColumns.status}, ${AbsensiColumns.waktuMasuk}, ${AbsensiColumns.waktuPulang}, ${AbsensiColumns.keterangan}')
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
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final startDate = '$year-$monthStr-01';
      final endDate = '$year-$monthStr-${daysInMonth.toString().padLeft(2, '0')}';

      final response = await _client
          .from(DbTables.absensi)
          .select('${AbsensiColumns.status}, ${AbsensiColumns.tanggal}')
          .eq(AbsensiColumns.siswaId, siswaId)
          .gte(AbsensiColumns.tanggal, startDate)
          .lte(AbsensiColumns.tanggal, endDate);

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

        // Count attended and total recorded in this week window
        int weekAttended = 0;
        int weekRecorded = 0;
        for (final raw in records) {
          final item = raw as Map<String, dynamic>;
          final tglStr = item[AbsensiColumns.tanggal] as String? ?? '';
          final tglParts = tglStr.split('-');
          if (tglParts.length == 3) {
            final day = int.tryParse(tglParts[2]) ?? 0;
            if (day >= startDay && day <= endDay) {
              final status = AttendanceStatus.fromValue(item[AbsensiColumns.status] as String?);
              weekRecorded++;
              if (status.isPresent || status.isLate) {
                weekAttended++;
              }
            }
          }
        }

        double pct = 0.0;
        if (weekRecorded > 0) {
          pct = ((weekAttended / weekRecorded) * 100).clamp(0.0, 100.0);
        } else {
          pct = 0.0;
        }

        weeklyTrend.add(
          AttendanceChartPoint(
            label: label,
            percentage: pct,
            hadir: weekAttended,
            totalHari: weekRecorded,
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
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final startDate = '$year-$monthStr-01';
      final endDate = '$year-$monthStr-${daysInMonth.toString().padLeft(2, '0')}';

      final response = await _client
          .from(DbTables.absensi)
          .select()
          .eq(AbsensiColumns.siswaId, siswaId)
          .gte(AbsensiColumns.tanggal, startDate)
          .lte(AbsensiColumns.tanggal, endDate)
          .order(AbsensiColumns.tanggal, ascending: false);

      return (response as List).map((json) => Absensi.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      debugPrint('[WaliRepo] Error fetching history: ${e.message}');
      return [];
    }
  }

  /// Get announcement & broadcast notifications for child from Supabase & local inbox
  Future<List<WaliNotificationItem>> getNotificationsForChild(
      ChildProfile child) async {
    final readIds = await waliStorageService.getReadNotificationIds();
    final List<WaliNotificationItem> items = [];
    final Set<String> processedIds = {};

    // 1. Fetch announcements from Supabase 'pengumuman' table
    try {
      List<dynamic>? response;
      try {
        response = await _client
            .from(DbTables.pengumuman)
            .select()
            .order('created_at', ascending: false);
      } catch (_) {
        try {
          // Fallback if created_at column is not present or named differently
          response = await _client.from(DbTables.pengumuman).select();
        } catch (e) {
          debugPrint('[WaliRepo] Info query tabel pengumuman: $e');
        }
      }

      if (response != null && response.isNotEmpty) {
        for (final row in response) {
          final map = row as Map<String, dynamic>;

          // Target Role Filter (e.g. 'all', 'wali_murid', 'semua', 'umum')
          final targetRole = (map['target_role'] ?? map['target'] ?? map['role'])
              ?.toString()
              .toLowerCase();
          if (targetRole != null &&
              targetRole.isNotEmpty &&
              targetRole != 'all' &&
              targetRole != 'semua' &&
              targetRole != 'wali' &&
              targetRole != 'wali_murid' &&
              targetRole != 'umum') {
            if (targetRole.contains('guru') || targetRole.contains('admin')) {
              continue; // Announcement is only for teachers / admins
            }
          }

          // Target Class Filter
          final rawKelasId = map['kelas_id'] ?? map['id_kelas'];
          if (rawKelasId != null && child.kelasId != null) {
            final parsedKelasId = int.tryParse(rawKelasId.toString());
            if (parsedKelasId != null && parsedKelasId != child.kelasId) {
              continue; // Announcement is targeted to a different class
            }
          }

          // Target Student (Siswa) Filter
          final rawSiswaId = map['siswa_id'] ??
              map['target_siswa_id'] ??
              map['id_siswa'] ??
              map['student_id'];
          if (rawSiswaId != null) {
            final parsedSiswaId = int.tryParse(rawSiswaId.toString());
            if (parsedSiswaId != null && parsedSiswaId != child.id) {
              continue; // Announcement is targeted to a different student
            }
          }

          final rawNis = map['nis'] ?? map['student_nis'];
          if (rawNis != null && rawNis.toString().trim().isNotEmpty) {
            if (rawNis.toString().trim() != child.nis.trim()) {
              continue; // Announcement is targeted to a different NIS
            }
          }

          final id = (map['id'] ?? map['uuid'] ?? map['pengumuman_id'])?.toString() ??
              'pengumuman_${map.hashCode}';
          final title = (map['judul'] ?? map['title'] ?? map['subjek'] ?? map['nama'] ?? 'Pengumuman Sekolah')
              .toString();
          final message = (map['isi'] ?? map['konten'] ?? map['pesan'] ?? map['deskripsi'] ?? map['keterangan'] ?? map['content'] ?? '')
              .toString();
          final rawTime = map['created_at'] ?? map['tanggal'] ?? map['tgl'] ?? map['waktu'] ?? map['updated_at'];
          final timestamp = rawTime != null
              ? (DateTime.tryParse(rawTime.toString()) ?? DateTime.now())
              : DateTime.now();
          final author = (map['penulis'] ?? map['author'] ?? map['created_by'] ?? map['nama_guru'] ?? map['sender'])?.toString();
          final category = (map['kategori'] ?? map['tipe'] ?? map['category'])?.toString();

          processedIds.add(id);
          items.add(
            WaliNotificationItem(
              id: id,
              title: title,
              message: message,
              timestamp: timestamp,
              type: 'pengumuman',
              isRead: readIds.contains(id),
              author: author,
              category: category,
              data: map,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[WaliRepo] Error fetching pengumuman: $e');
    }

    // 2. Merge local push notifications received via OneSignal (inbox) - FILTERED BY CHILD
    try {
      final localPushItems = await waliStorageService.getLocalInAppNotifications();
      for (final localItem in localPushItems) {
        if (processedIds.contains(localItem.id)) continue;

        // Check if this push notification was targeted to a specific child
        final notifData = localItem.data ?? {};
        final rawNotifSiswaId = notifData['siswa_id'] ??
            notifData['student_id'] ??
            notifData['id_siswa'];
        if (rawNotifSiswaId != null) {
          final parsedId = int.tryParse(rawNotifSiswaId.toString());
          if (parsedId != null && parsedId != child.id) {
            continue; // Push notification belongs to a different child
          }
        }

        final rawNotifNis = notifData['nis'] ?? notifData['student_nis'];
        if (rawNotifNis != null && rawNotifNis.toString().trim().isNotEmpty) {
          if (rawNotifNis.toString().trim() != child.nis.trim()) {
            continue; // Push notification belongs to a different NIS
          }
        }

        final rawNotifKelasId = notifData['kelas_id'] ?? notifData['student_class'];
        if (rawNotifKelasId != null && child.kelasId != null) {
          final parsedKId = int.tryParse(rawNotifKelasId.toString());
          if (parsedKId != null && parsedKId != child.kelasId) {
            continue; // Push notification belongs to a different class
          }
        }

        processedIds.add(localItem.id);
        items.add(
          WaliNotificationItem(
            id: localItem.id,
            title: localItem.title,
            message: localItem.message,
            timestamp: localItem.timestamp,
            type: 'pengumuman',
            isRead: readIds.contains(localItem.id),
            author: localItem.author,
            category: localItem.category,
            data: localItem.data,
          ),
        );
      }
    } catch (e) {
      debugPrint('[WaliRepo] Error merging local notifications: $e');
    }

    // 3. Sort newest first
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
