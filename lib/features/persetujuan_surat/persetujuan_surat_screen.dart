import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/ui/bouncing_widget.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Screen for Teachers / Homeroom teachers to approve/reject student leave & sick requests
class PersetujuanSuratScreen extends StatefulWidget {
  final int? kelasId;
  final String? namaKelas;

  const PersetujuanSuratScreen({
    super.key,
    this.kelasId,
    this.namaKelas,
  });

  @override
  State<PersetujuanSuratScreen> createState() => _PersetujuanSuratScreenState();
}

class _PersetujuanSuratScreenState extends State<PersetujuanSuratScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _suratRepository = SuratRepository();

  bool _isLoading = true;
  List<SuratPengajuan> _allSurat = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _suratRepository.getDaftarPengajuanGuru(
        kelasId: widget.kelasId,
      );
      if (mounted) {
        setState(() {
          _allSurat = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<SuratPengajuan> _getFilteredList(int tabIndex) {
    switch (tabIndex) {
      case 0: // Menunggu
        return _allSurat.where((s) => s.isPending).toList();
      case 1: // Disetujui
        return _allSurat.where((s) => s.isApproved).toList();
      case 2: // Ditolak
        return _allSurat.where((s) => s.isRejected).toList();
      case 3: // Semua
      default:
        return _allSurat;
    }
  }

  Future<void> _handleApprove(SuratPengajuan item) async {
    final noteController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text('Setujui Surat ${item.jenis.toUpperCase()}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setujui pengajuan ${item.jenis} untuk ananda ${item.namaSiswa ?? 'Siswa'} pada tanggal ${item.tanggal}?',
              style: const TextStyle(fontSize: 13.5, height: 1.3),
            ),
            const SizedBox(height: 12),
            Text(
              '*Status presensi siswa di tanggal tersebut akan otomatis tercatat sebagai ${item.jenis.toUpperCase()}.',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Catatan Guru (Opsional)',
                hintText: 'Contoh: Semoga lekas sembuh',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _suratRepository.approvePengajuan(
        surat: item,
        catatanGuru: noteController.text.trim().isNotEmpty
            ? noteController.text.trim()
            : null,
      );

      HapticFeedback.mediumImpact();
      _showSnackbar('Surat berhasil disetujui & presensi otomatis tercatat!');
      await _loadData();
    } catch (e) {
      _showSnackbar('Gagal menyetujui: $e', isError: true);
      HapticFeedback.vibrate();
    }
  }

  Future<void> _handleReject(SuratPengajuan item) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Tolak Pengajuan Surat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tolak pengajuan surat ${item.jenis} untuk ${item.namaSiswa ?? 'Siswa'}?',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Alasan Penolakan *',
                hintText: 'Contoh: Surat bukti tidak jelas / tidak sah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true || reasonController.text.trim().isEmpty) return;

    try {
      await _suratRepository.rejectPengajuan(
        surat: item,
        alasan: reasonController.text.trim(),
      );

      HapticFeedback.mediumImpact();
      _showSnackbar('Pengajuan surat ditolak.');
      await _loadData();
    } catch (e) {
      _showSnackbar('Gagal menolak surat: $e', isError: true);
      HapticFeedback.vibrate();
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allSurat.where((s) => s.isPending).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Persetujuan Izin / Sakit',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            if (widget.namaKelas != null)
              Text(
                widget.namaKelas!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D2FF),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('Menunggu'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Disetujui'),
            const Tab(text: 'Ditolak'),
            const Tab(text: 'Semua'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListTab(0),
                _buildListTab(1),
                _buildListTab(2),
                _buildListTab(3),
              ],
            ),
    );
  }

  Widget _buildListTab(int tabIndex) {
    final list = _getFilteredList(tabIndex);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 40,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tidak Ada Pengajuan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Daftar pengajuan izin/sakit pada filter ini kosong',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = list[index];
          return _buildSuratCard(item);
        },
      ),
    );
  }

  Widget _buildSuratCard(SuratPengajuan item) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (item.status) {
      case SuratStatus.disetujui:
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFECFDF5);
        statusIcon = Icons.check_circle_rounded;
        break;
      case SuratStatus.ditolak:
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFFEF2F2);
        statusIcon = Icons.cancel_rounded;
        break;
      case SuratStatus.menunggu:
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFFFBEB);
        statusIcon = Icons.schedule_rounded;
        break;
    }

    final dateDisplay = item.tanggalSelesai != null &&
            item.tanggalSelesai != item.tanggal
        ? '${item.tanggal} s/d ${item.tanggalSelesai}'
        : item.tanggal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Student Name & Class
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: item.isSakit
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                    : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                child: Icon(
                  item.isSakit
                      ? Icons.medical_services_outlined
                      : Icons.assignment_outlined,
                  color: item.isSakit
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaSiswa ?? 'Siswa ID: ${item.siswaId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.namaKelas ?? 'Kelas'} • NIS: ${item.nisSiswa ?? '-'}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      item.status.displayName,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date of Leave
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                Text(
                  'Tanggal: $dateDisplay',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Alasan
          if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
            const Text(
              'Alasan / Keterangan:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.keterangan!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Photo Attachment Thumbnail & Preview
          if (item.fileUrl != null && item.fileUrl!.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text(
              'Foto Lampiran Surat / Bukti:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _showImageDialog(item.fileUrl!),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.fileUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF8FAFC),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: Color(0xFF94A3B8), size: 32),
                              SizedBox(height: 4),
                              Text('Gagal memuat gambar',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Ketuk untuk Zoom',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Teacher Note if present
          if (item.catatanGuru != null && item.catatanGuru!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: ${item.catatanGuru}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Action Buttons (Only for Pending requests)
          if (item.isPending) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                // Tolak Button
                Expanded(
                  child: BouncingWidget(
                    onTap: () => _handleReject(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded,
                              color: Color(0xFFDC2626), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Tolak',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Setujui Button
                Expanded(
                  child: BouncingWidget(
                    onTap: () => _handleApprove(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Setujui',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black87,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 250,
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.white,
                      child: const Center(
                        child: Text('Gagal memuat foto lampiran'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan 2 jari untuk memperbesar (Zoom)',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
