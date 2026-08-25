/// Model representing permit or sick leave letter (Surat Izin / Sakit)
enum SuratStatus {
  menunggu('menunggu', 'Menunggu Persetujuan'),
  disetujui('disetujui', 'Disetujui'),
  ditolak('ditolak', 'Ditolak');

  final String value;
  final String displayName;

  const SuratStatus(this.value, this.displayName);

  factory SuratStatus.fromValue(String? value) {
    if (value == null || value.isEmpty) return SuratStatus.menunggu;
    final lower = value.toLowerCase();
    return SuratStatus.values.firstWhere(
      (s) => s.value == lower,
      orElse: () => SuratStatus.menunggu,
    );
  }
}

/// Model for permission request (Surat Izin/Sakit) submitted by parents and approved by teachers
class SuratPengajuan {
  final int id;
  final int siswaId;
  final String? namaSiswa;
  final String? nisSiswa;
  final int? kelasId;
  final String? namaKelas;
  final String jenis; // 'izin' or 'sakit'
  final String tanggal; // 'YYYY-MM-DD'
  final String? tanggalSelesai;
  final String? keterangan;
  final String? fileUrl;
  final SuratStatus status;
  final String? catatanGuru;
  final DateTime createdAt;

  SuratPengajuan({
    required this.id,
    required this.siswaId,
    this.namaSiswa,
    this.nisSiswa,
    this.kelasId,
    this.namaKelas,
    required this.jenis,
    required this.tanggal,
    this.tanggalSelesai,
    this.keterangan,
    this.fileUrl,
    required this.status,
    this.catatanGuru,
    required this.createdAt,
  });

  bool get isSakit => jenis.toLowerCase() == 'sakit';
  bool get isIzin => jenis.toLowerCase() == 'izin';
  bool get isPending => status == SuratStatus.menunggu;
  bool get isApproved => status == SuratStatus.disetujui;
  bool get isRejected => status == SuratStatus.ditolak;

  factory SuratPengajuan.fromJson(Map<String, dynamic> json) {
    final siswaObj = json['siswa'] as Map<String, dynamic>?;
    final kelasObj = siswaObj?['kelas'] as Map<String, dynamic>? ??
        json['kelas'] as Map<String, dynamic>?;

    return SuratPengajuan(
      id: json['id'] as int? ?? 0,
      siswaId: json['siswa_id'] as int? ?? 0,
      namaSiswa:
          json['nama_siswa'] as String? ?? siswaObj?['nama'] as String?,
      nisSiswa: json['nis'] as String? ?? siswaObj?['nis'] as String?,
      kelasId: json['kelas_id'] as int? ?? siswaObj?['kelas_id'] as int?,
      namaKelas: json['nama_kelas'] as String? ??
          kelasObj?['nama_kelas'] as String? ??
          kelasObj?['nama'] as String?,
      jenis: json['jenis'] as String? ?? 'izin',
      tanggal: json['tanggal'] as String? ?? '',
      tanggalSelesai: json['tanggal_selesai'] as String?,
      keterangan: json['keterangan'] as String?,
      fileUrl: json['file_url'] as String?,
      status: SuratStatus.fromValue(json['status'] as String?),
      catatanGuru: json['catatan_guru'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'siswa_id': siswaId,
        'jenis': jenis,
        'tanggal': tanggal,
        'tanggal_selesai': tanggalSelesai,
        'keterangan': keterangan,
        'file_url': fileUrl,
        'status': status.value,
        'catatan_guru': catatanGuru,
        'created_at': createdAt.toIso8601String(),
      };
}
