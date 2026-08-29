import 'dart:convert';
import '../../core/constants.dart';

/// Model representing a child (student) linked to a parent's device
class ChildProfile {
  final int id;
  final String nis;
  final String nama;
  final int? kelasId;
  final String namaKelas;
  final String? waliKelasNama;
  final String? waliKelasNoHp;
  final String? fotoUrl;

  ChildProfile({
    required this.id,
    required this.nis,
    required this.nama,
    this.kelasId,
    required this.namaKelas,
    this.waliKelasNama,
    this.waliKelasNoHp,
    this.fotoUrl,
  });

  /// Initials for avatar fallback (e.g. "Ahmad Fauzi" -> "AF")
  String get initials {
    if (nama.trim().isEmpty) return 'AN';
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as int,
      nis: json['nis'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      kelasId: json['kelas_id'] as int?,
      namaKelas: json['nama_kelas'] as String? ?? 'Belum Ditentukan',
      waliKelasNama: json['wali_kelas_nama'] as String?,
      waliKelasNoHp: json['wali_kelas_no_hp'] as String?,
      fotoUrl: json['foto_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nis': nis,
        'nama': nama,
        'kelas_id': kelasId,
        'nama_kelas': namaKelas,
        'wali_kelas_nama': waliKelasNama,
        'wali_kelas_no_hp': waliKelasNoHp,
        'foto_url': fotoUrl,
      };

  String serialize() => jsonEncode(toJson());

  static ChildProfile deserialize(String raw) =>
      ChildProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  ChildProfile copyWith({
    int? id,
    String? nis,
    String? nama,
    int? kelasId,
    String? namaKelas,
    String? waliKelasNama,
    String? waliKelasNoHp,
    String? fotoUrl,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      nis: nis ?? this.nis,
      nama: nama ?? this.nama,
      kelasId: kelasId ?? this.kelasId,
      namaKelas: namaKelas ?? this.namaKelas,
      waliKelasNama: waliKelasNama ?? this.waliKelasNama,
      waliKelasNoHp: waliKelasNoHp ?? this.waliKelasNoHp,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}

/// Model for today's live attendance status
class TodayAttendance {
  final int? id;
  final int siswaId;
  final DateTime tanggal;
  final AttendanceStatus status;
  final String? waktuMasuk;
  final String? waktuPulang;
  final String? keterangan;
  final bool hasScannedMasuk;
  final bool hasScannedPulang;
  final bool isLate;
  final int? lateMinutes;

  TodayAttendance({
    this.id,
    required this.siswaId,
    required this.tanggal,
    required this.status,
    this.waktuMasuk,
    this.waktuPulang,
    this.keterangan,
    this.hasScannedMasuk = false,
    this.hasScannedPulang = false,
    this.isLate = false,
    this.lateMinutes,
  });

  /// Whether there is an actual attendance record saved in database today
  bool get hasRecord => id != null;
  bool get isAlfa => status == AttendanceStatus.alfa && hasRecord;
  bool get isSakit => status == AttendanceStatus.sakit && hasRecord;
  bool get isIzin => status == AttendanceStatus.izin && hasRecord;

  factory TodayAttendance.empty(int siswaId) {
    return TodayAttendance(
      id: null,
      siswaId: siswaId,
      tanggal: DateTime.now(),
      status: AttendanceStatus.alfa,
      hasScannedMasuk: false,
      hasScannedPulang: false,
    );
  }

  factory TodayAttendance.fromJson(Map<String, dynamic> json, {String? targetJamMasuk}) {
    final statusStr = json['status'] as String?;
    final status = AttendanceStatus.fromValue(statusStr);
    final waktuMasuk = json['waktu_masuk'] as String?;
    final waktuPulang = json['waktu_pulang'] as String?;

    bool isLate = status == AttendanceStatus.terlambat;
    int? lateMinutes;

    if (waktuMasuk != null && targetJamMasuk != null) {
      try {
        final todayStr = json['tanggal'] as String? ?? '';
        final masukDt = DateTime.parse('$todayStr $waktuMasuk');
        final targetDt = DateTime.parse('$todayStr $targetJamMasuk');
        if (masukDt.isAfter(targetDt)) {
          isLate = true;
          lateMinutes = masukDt.difference(targetDt).inMinutes;
        }
      } catch (_) {}
    }

    return TodayAttendance(
      id: json['id'] as int?,
      siswaId: json['siswa_id'] as int? ?? 0,
      tanggal: json['tanggal'] != null
          ? DateTime.tryParse(json['tanggal'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: status,
      waktuMasuk: waktuMasuk,
      waktuPulang: waktuPulang,
      keterangan: json['keterangan'] as String?,
      hasScannedMasuk: waktuMasuk != null,
      hasScannedPulang: waktuPulang != null,
      isLate: isLate,
      lateMinutes: lateMinutes,
    );
  }
}

/// Model for monthly attendance statistics
class MonthlyAttendanceStats {
  final int totalHariSekolah;
  final int totalHadir;
  final int totalTerlambat;
  final int totalSakit;
  final int totalIzin;
  final int totalAlfa;
  final int bulan;
  final int tahun;
  final List<AttendanceChartPoint> weeklyTrend;

  MonthlyAttendanceStats({
    required this.totalHariSekolah,
    required this.totalHadir,
    required this.totalTerlambat,
    required this.totalSakit,
    required this.totalIzin,
    required this.totalAlfa,
    required this.bulan,
    required this.tahun,
    this.weeklyTrend = const [],
  });

  factory MonthlyAttendanceStats.empty(int bulan, int tahun) {
    return MonthlyAttendanceStats(
      totalHariSekolah: 0,
      totalHadir: 0,
      totalTerlambat: 0,
      totalSakit: 0,
      totalIzin: 0,
      totalAlfa: 0,
      bulan: bulan,
      tahun: tahun,
      weeklyTrend: const [],
    );
  }

  /// Total days student attended (including late)
  int get totalKehadiran => totalHadir + totalTerlambat;

  /// Total recorded attendance events (hadir + telat + sakit + izin + alfa)
  int get totalTercatat =>
      totalHadir + totalTerlambat + totalSakit + totalIzin + totalAlfa;

  /// Percentage of attendance (0.0 to 100.0)
  double get attendancePercentage {
    if (totalHariSekolah <= 0 || totalTercatat == 0) return 0.0;
    final totalAttended = totalHadir + totalTerlambat;
    return ((totalAttended / totalHariSekolah) * 100).clamp(0.0, 100.0);
  }
}

/// Model for a point in the attendance line chart
class AttendanceChartPoint {
  final String label;
  final double percentage;
  final int hadir;
  final int totalHari;

  const AttendanceChartPoint({
    required this.label,
    required this.percentage,
    this.hadir = 0,
    this.totalHari = 0,
  });
}

/// Model for Parent Notification / Announcement Entry
class WaliNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'pengumuman', 'informasi', 'admin'
  final bool isRead;
  final String? author;
  final String? category;
  final Map<String, dynamic>? data;

  WaliNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = 'pengumuman',
    this.isRead = false,
    this.author,
    this.category,
    this.data,
  });

  factory WaliNotificationItem.fromJson(Map<String, dynamic> json) {
    return WaliNotificationItem(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ??
          json['judul'] as String? ??
          'Pengumuman Sekolah',
      message: json['message'] as String? ??
          json['isi'] as String? ??
          json['konten'] as String? ??
          '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
              : DateTime.now()),
      type: json['type'] as String? ?? 'pengumuman',
      isRead: json['is_read'] as bool? ?? false,
      author: json['author'] as String? ?? json['penulis'] as String?,
      category: json['category'] as String? ?? json['kategori'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'is_read': isRead,
        if (author != null) 'author': author,
        if (category != null) 'category': category,
        if (data != null) 'data': data,
      };
}
