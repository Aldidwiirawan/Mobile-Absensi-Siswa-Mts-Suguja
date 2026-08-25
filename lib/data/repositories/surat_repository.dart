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

      final insertData = {
        'siswa_id': siswaId,
        'jenis': jenis.toLowerCase(),
        'tanggal': tglMulaiStr,
        if (tglSelesaiStr != null) 'tanggal_selesai': tglSelesaiStr,
        'keterangan': keterangan.trim(),
        if (fileUrl != null) 'file_url': fileUrl,
        'status': SuratStatus.menunggu.value,
      };

      debugPrint('--- [SuratRepo] Inserting pengajuan: $insertData ---');

      final response = await _client
          .from(DbTables.surat)
          .insert(insertData)
          .select('*, siswa:siswa_id(nama, nis, kelas_id, kelas:kelas_id(nama_kelas))')
          .maybeSingle();

      if (response == null) {
        // Fallback without join
        final fallbackRes = await _client
            .from(DbTables.surat)
            .select()
            .eq('siswa_id', siswaId)
            .eq('tanggal', tglMulaiStr)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        return SuratPengajuan.fromJson(fallbackRes ?? insertData);
      }

      return SuratPengajuan.fromJson(response);
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
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => SuratPengajuan.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SuratRepo] Error getRiwayatSuratBySiswa: $e');
      // Fallback simple query
      try {
        final fallback = await _client
            .from(DbTables.surat)
            .select()
            .eq('siswa_id', siswaId)
            .order('created_at', ascending: false);

        return (fallback as List)
            .map((item) =>
                SuratPengajuan.fromJson(item as Map<String, dynamic>))
            .toList();
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

      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'semua') {
        query = query.eq('status', statusFilter.toLowerCase());
      }

      if (kelasId != null) {
        query = query.eq('siswa.kelas_id', kelasId);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((item) => SuratPengajuan.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SuratRepo] Error getDaftarPengajuanGuru with inner join: $e');
      // Fallback query without inner join
      try {
        var query = _client.from(DbTables.surat).select();
        if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'semua') {
          query = query.eq('status', statusFilter.toLowerCase());
        }
        final list = await query.order('created_at', ascending: false) as List;

        final result = <SuratPengajuan>[];
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
                continue; // filter out other classes
              }
              map['nama_siswa'] = sRes['nama'];
              map['nis'] = sRes['nis'];
              map['kelas_id'] = sRes['kelas_id'];
            }
          }
          result.add(SuratPengajuan.fromJson(map));
        }
        return result;
      } catch (err) {
        debugPrint('[SuratRepo] Fallback getDaftarPengajuanGuru failed: $err');
        return [];
      }
    }
  }

  /// Approve permission request by teacher
  Future<bool> approvePengajuan({
    required SuratPengajuan surat,
    String? catatanGuru,
  }) async {
    try {
      // 1. Update Surat status to 'disetujui'
      await _client.from(DbTables.surat).update({
        'status': SuratStatus.disetujui.value,
        if (catatanGuru != null) 'catatan_guru': catatanGuru.trim(),
      }).eq('id', surat.id);

      // 2. Automatically sync to table absensi
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
              'keterangan': surat.keterangan ?? 'Surat ${surat.jenis} Mandiri',
            },
            onConflict: 'siswa_id, tanggal',
          );
        }
        cur = cur.add(const Duration(days: 1));
      }

      // 3. Send Push Notification to Parent via OneSignal
      final nama = surat.namaSiswa ?? 'Ananda';
      final jenisTitle = surat.isSakit ? 'Sakit' : 'Izin';
      await OneSignalService.sendPushNotification(
        heading: '✅ Surat $jenisTitle Disetujui',
        content:
            'Pengajuan surat $jenisTitle untuk $nama pada tanggal ${surat.tanggal} telah disetujui oleh Wali Kelas.',
        filters: [
          {'field': 'tag', 'key': 'siswa_id_${surat.siswaId}', 'relation': '=', 'value': 'true'}
        ],
      );

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
      // 1. Update Surat status to 'ditolak'
      await _client.from(DbTables.surat).update({
        'status': SuratStatus.ditolak.value,
        'catatan_guru': alasan.trim(),
      }).eq('id', surat.id);

      // 2. Send Push Notification to Parent via OneSignal
      final nama = surat.namaSiswa ?? 'Ananda';
      final jenisTitle = surat.isSakit ? 'Sakit' : 'Izin';
      await OneSignalService.sendPushNotification(
        heading: '❌ Surat $jenisTitle Ditolak',
        content:
            'Pengajuan surat $jenisTitle untuk $nama ditolak. Alasan: $alasan',
        filters: [
          {'field': 'tag', 'key': 'siswa_id_${surat.siswaId}', 'relation': '=', 'value': 'true'}
        ],
      );

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
      final fileName = 'surat_${siswaId}_${tanggalStr}_${DateTime.now().millisecondsSinceEpoch}.$ext';
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
}
