/// Model for class summary data from dashboard RPC
class ClassSummary {
  final String namaKelas;
  final int totalSiswa;
  final int hadir;
  final int terlambat;
  final int sakit;
  final int izin;
  final int alfa;
  final int pulang;

  ClassSummary({
    required this.namaKelas,
    required this.totalSiswa,
    required this.hadir,
    required this.terlambat,
    required this.sakit,
    required this.izin,
    required this.alfa,
    this.pulang = 0,
  });

  factory ClassSummary.fromJson(Map<String, dynamic> json) {
    return ClassSummary(
      namaKelas: json['nama_kelas'] as String? ?? '-',
      totalSiswa: json['total_siswa'] as int? ?? 0,
      hadir: json['hadir'] as int? ?? 0,
      terlambat: json['terlambat'] as int? ?? 0,
      sakit: json['sakit'] as int? ?? 0,
      izin: json['izin'] as int? ?? 0,
      alfa: json['alfa'] as int? ?? 0,
      pulang: json['pulang'] as int? ?? 0,
    );
  }

  /// Total students present (hadir + terlambat + pulang)
  int get totalPresent => hadir + terlambat + pulang;

  /// Total students absent
  int get totalAbsent => sakit + izin + alfa;

  /// Attendance rate percentage
  double get attendanceRate {
    if (totalSiswa == 0) return 0;
    return (totalPresent / totalSiswa) * 100;
  }

  Map<String, dynamic> toJson() => {
        'nama_kelas': namaKelas,
        'total_siswa': totalSiswa,
        'hadir': hadir,
        'terlambat': terlambat,
        'sakit': sakit,
        'izin': izin,
        'alfa': alfa,
        'pulang': pulang,
      };

  @override
  String toString() =>
      'ClassSummary(namaKelas: $namaKelas, total: $totalSiswa, hadir: $hadir, terlambat: $terlambat, pulang: $pulang)';
}
