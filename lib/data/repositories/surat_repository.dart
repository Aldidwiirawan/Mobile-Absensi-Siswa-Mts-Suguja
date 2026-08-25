import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../models/surat.dart';
import '../services/onesignal_service.dart';
import '../services/supabase_service.dart';

/// Repository for student leave & sick letter requests (Surat Izin / Sakit)
class SuratRepository {
  final SupabaseClient _client = supabaseService.client;

  /// Submit a new permit or sick leave request from parents
  Future<SuratPengajuan> submitPengajuanSurat({
    required int siswaId,
    required String jenis, // 'izin' or 'sakit'
    required DateTime tanggalMulai,
    DateTime? tanggalSelesai,
    required String keterangan,
    File? file,
  }) async {
    try {
      final tglMulaiStr = tanggalMulai.toIso8601String().split('T').first;
      final tglSelesaiStr =
          tanggalSelesai?.toIso8601String().split('T').first;

      String? fileUrl;
      if (file != null) {
        fileUrl = await uploadSuratFile(
          file: file,
          siswaId: siswaId,
          tanggalStr: tglMulaiStr,
        );
      }

      final fullData = <String, dynamic>{
        'siswa_id': siswaId,
        'jenis': jenis.toLowerCase(),
        'tanggal': tglMulaiStr,
        if (tglSelesaiStr != null) 'tanggal_selesai': tglSelesaiStr,
        'keterangan': keterangan.trim(),
        if (fileUrl != null) 'file_url': fileUrl,
        'status': SuratStatus.menunggu.value,
      };

      try {
        final response = await _client
            .from(DbTables.surat)
            .insert(fullData)
            .select('*, siswa:siswa_id(nama, nis, kelas_id, kelas:kelas_id(nama_kelas))')
            .maybeSingle();

        if (response != null) {
          return SuratPengajuan.fromJson(response);
        }
      } catch (e) {
        debugPrint('[SuratRepo] Insert with status failed, falling back to minimal columns: $e');
        // Fallback with standard minimal columns (siswa_id, jenis, tanggal, file_url)
        final minimalData = <String, dynamic>{
          'siswa_id': siswaId,
          'jenis': jenis.toLowerCase(),
          'tanggal': tglMulaiStr,
          if (fileUrl != null) 'file_url': fileUrl,
        };

        final fallbackRes = await _client
            .from(DbTables.surat)
            .insert(minimalData)
            .select()
            .maybeSingle();

        final merged = <String, dynamic>{
          ...fullData,
          if (fallbackRes != null) ...fallbackRes,
        };
        return SuratPengajuan.fromJson(merged);
      }

      return SuratPengajuan.fromJson(fullData);
    } on PostgrestException catch (e) {
      debugPrint('[SuratRepo] Postgrest error: ${e.message}');
      throw RepositoryException(
        message: 'Gagal mengajukan surat izin: ${e.message}',
        originalException: e,
      );
    } catch (e) {
      debugPrint('[SuratRepo] Error: $e');
      throw RepositoryException(
        message: 'Terjadi kesalahan saat mengirim surat: $e',
      );
    }
  }

  /// Get student request history
  Future<List<SuratPengajuan>> getRiwayatSuratBySiswa(int siswaId) async {
    try {
      final response = await _client
          .from(DbTables.surat)
          .select('*, siswa:siswa_id(nama, nis, kelas_id, kelas:kelas_id(nama_kelas))')
          .eq('siswa_id', siswaId)
          .order('tanggal', ascending: false);

      final list = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      return await _enrichSuratStatus(list);
    } catch (e) {
      debugPrint('[SuratRepo] Error getRiwayatSuratBySiswa: $e');
      try {
        final fallback = await _client
            .from(DbTables.surat)
            .select()
            .eq('siswa_id', siswaId)
            .order('tanggal', ascending: false);

        final list = (fallback as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        return await _enrichSuratStatus(list);
      } catch (_) {
        return [];
      }
    }
  }

  /// Get all requests for teachers to review
  Future<List<SuratPengajuan>> getDaftarPengajuanGuru({
    int? kelasId,
    String? statusFilter,
  }) async {
    try {
      var query = _client.from(DbTables.surat).select(
            '*, siswa!inner(id, nama, nis, kelas_id, kelas:kelas_id(id, nama_kelas))',
          );

      if (kelasId != null) {
        query = query.eq('siswa.kelas_id', kelasId);
      }

      final response = await query.order('tanggal', ascending: false);
      final rawList = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final enriched = await _enrichSuratStatus(rawList);

      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'semua') {
        return enriched
            .where((s) => s.status.value == statusFilter.toLowerCase())
            .toList();
      }

      return enriched;
    } catch (e) {
      debugPrint('[SuratRepo] Error getDaftarPengajuanGuru: $e');
      try {
        final list = await _client
            .from(DbTables.surat)
            .select()
            .order('tanggal', ascending: false) as List;

        final rawList = <Map<String, dynamic>>[];
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          final sid = map['siswa_id'] as int?;
          if (sid != null) {
            final sRes = await _client
                .from(DbTables.siswa)
                .select('id, nama, nis, kelas_id')
                .eq('id', sid)
                .maybeSingle();
            if (sRes != null) {
              if (kelasId != null && sRes['kelas_id'] != kelasId) {
                continue;
              }
              map['nama_siswa'] = sRes['nama'];
              map['nis'] = sRes['nis'];
              map['kelas_id'] = sRes['kelas_id'];
            }
          }
          rawList.add(map);
        }

        final enriched = await _enrichSuratStatus(rawList);

        if (statusFilter != null &&
            statusFilter.isNotEmpty &&
            statusFilter != 'semua') {
          return enriched
              .where((s) => s.status.value == statusFilter.toLowerCase())
              .toList();
        }

        return enriched;
      } catch (err) {
        debugPrint('[SuratRepo] Fallback getDaftarPengajuanGuru failed: $err');
        return [];
      }
    }
  }

  /// Helper to dynamically determine status from absensi if 'status' column is not present
  Future<List<SuratPengajuan>> _enrichSuratStatus(
      List<Map<String, dynamic>> rawList) async {
    final result = <SuratPengajuan>[];

    for (final item in rawList) {
      // If status column is already populated in DB
      if (item['status'] != null &&
          item['status'].toString().isNotEmpty &&
          item['status'] != 'menunggu') {
        result.add(SuratPengajuan.fromJson(item));
        continue;
      }

      // Check absensi table for cross-verification
      final sid = item['siswa_id'] as int?;
      final tgl = item['tanggal'] as String?;
      final jenis = (item['jenis'] as String? ?? '').toLowerCase();

      if (sid != null && tgl != null) {
        try {
          final absensiRes = await _client
              .from(DbTables.absensi)
              .select('status, keterangan')
              .eq('siswa_id', sid)
              .eq('tanggal', tgl)
              .maybeSingle();

          if (absensiRes != null) {
            final attStatus = (absensiRes['status'] as String? ?? '').toLowerCase();
            final ket = (absensiRes['keterangan'] as String? ?? '').toLowerCase();

            if (attStatus == jenis || attStatus == 'izin' || attStatus == 'sakit') {
              item['status'] = SuratStatus.disetujui.value;
            } else if (ket.contains('ditolak') || attStatus == 'alfa') {
              item['status'] = SuratStatus.ditolak.value;
              item['catatan_guru'] = absensiRes['keterangan'];
            }
          }
        } catch (_) {}
      }

      result.add(SuratPengajuan.fromJson(item));
    }

    return result;
  }

  /// Approve permission request by teacher
  Future<bool> approvePengajuan({
    required SuratPengajuan surat,
    String? catatanGuru,
  }) async {
    try {
      // 1. Try to update Surat table status (if column exists)
      try {
        await _client.from(DbTables.surat).update({
          'status': SuratStatus.disetujui.value,
          if (catatanGuru != null) 'catatan_guru': catatanGuru.trim(),
        }).eq('id', surat.id);
      } catch (e) {
        debugPrint('[SuratRepo] Info: Kolom status belum ada di tabel surat, lanjut sinkronisasi absensi: $e');
      }

      // 2. Automatically sync to table absensi (Core attendance record)
      final startDate = DateTime.tryParse(surat.tanggal) ?? DateTime.now();
      final endDate = surat.tanggalSelesai != null
          ? DateTime.tryParse(surat.tanggalSelesai!) ?? startDate
          : startDate;

      DateTime cur = startDate;
      while (!cur.isAfter(endDate)) {
        if (cur.weekday != DateTime.sunday) {
          final curDateStr = cur.toIso8601String().split('T').first;
          await _client.from(DbTables.absensi).upsert(
            {
              'siswa_id': surat.siswaId,
              'tanggal': curDateStr,
              'status': surat.jenis.toLowerCase(),
              'keterangan': surat.keterangan ??
                  (catatanGuru != null
                      ? 'Surat Disetujui: $catatanGuru'
                      : 'Surat ${surat.jenis} Mandiri (Disetujui)'),
            },
            onConflict: 'siswa_id, tanggal',
          );
        }
        cur = cur.add(const Duration(days: 1));
      }

      // 3. Send Push Notification to Parent via OneSignal
      try {
        final nama = surat.namaSiswa ?? 'Ananda';
        final jenisTitle = surat.isSakit ? 'Sakit' : 'Izin';
        await OneSignalService.sendPushNotification(
          heading: '✅ Surat $jenisTitle Disetujui',
          content:
              'Pengajuan surat $jenisTitle untuk $nama pada tanggal ${surat.tanggal} telah disetujui oleh Guru/Wali Kelas.',
          filters: [
            {
              'field': 'tag',
              'key': 'siswa_id_${surat.siswaId}',
              'relation': '=',
              'value': 'true'
            }
          ],
        );
      } catch (e) {
        debugPrint('[SuratRepo] Warning sending OneSignal: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[SuratRepo] Error approvePengajuan: $e');
      throw RepositoryException(message: 'Gagal menyetujui surat: $e');
    }
  }

  /// Reject permission request by teacher
  Future<bool> rejectPengajuan({
    required SuratPengajuan surat,
    required String alasan,
  }) async {
    try {
      // 1. Try to update Surat table status (if column exists)
      try {
        await _client.from(DbTables.surat).update({
          'status': SuratStatus.ditolak.value,
          'catatan_guru': alasan.trim(),
        }).eq('id', surat.id);
      } catch (e) {
        debugPrint('[SuratRepo] Info: Kolom status belum ada di tabel surat: $e');
      }

      // 2. Update absensi record with rejection note
      try {
        await _client.from(DbTables.absensi).upsert(
          {
            'siswa_id': surat.siswaId,
            'tanggal': surat.tanggal,
            'status': 'alfa',
            'keterangan': 'Surat ${surat.jenis} Ditolak: $alasan',
          },
          onConflict: 'siswa_id, tanggal',
        );
      } catch (e) {
        debugPrint('[SuratRepo] Warning updating absensi on reject: $e');
      }

      // 3. Send Push Notification to Parent via OneSignal
      try {
        final nama = surat.namaSiswa ?? 'Ananda';
        final jenisTitle = surat.isSakit ? 'Sakit' : 'Izin';
        await OneSignalService.sendPushNotification(
          heading: '❌ Surat $jenisTitle Ditolak',
          content:
              'Pengajuan surat $jenisTitle untuk $nama ditolak. Alasan: $alasan',
          filters: [
            {
              'field': 'tag',
              'key': 'siswa_id_${surat.siswaId}',
              'relation': '=',
              'value': 'true'
            }
          ],
        );
      } catch (e) {
        debugPrint('[SuratRepo] Warning sending OneSignal: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[SuratRepo] Error rejectPengajuan: $e');
      throw RepositoryException(message: 'Gagal menolak surat: $e');
    }
  }

  /// Upload photo / letter file to Supabase Storage
  Future<String?> uploadSuratFile({
    required File file,
    required int siswaId,
    required String tanggalStr,
  }) async {
    try {
      final ext = file.path.split('.').last;
      final fileName =
          'surat_${siswaId}_${tanggalStr}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = 'pengajuan/$fileName';

      await _client.storage.from(StorageBuckets.suratKeterangan).upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      return _client.storage
          .from(StorageBuckets.suratKeterangan)
          .getPublicUrl(filePath);
    } catch (e) {
      debugPrint('[SuratRepo] Error uploadSuratFile: $e');
      return null;
    }
  }

  /// Get total pending requests waiting for teacher approval
  Future<int> getPendingSuratCount({int? kelasId}) async {
    try {
      final list = await getDaftarPengajuanGuru(
        kelasId: kelasId,
        statusFilter: SuratStatus.menunggu.value,
      );
      return list.length;
    } catch (e) {
      debugPrint('[SuratRepo] Error getPendingSuratCount: $e');
      return 0;
    }
  }
}
