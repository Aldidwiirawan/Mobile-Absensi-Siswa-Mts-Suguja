import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/ui/bouncing_widget.dart';
import '../../core/ui/status_selector_pills.dart';
import 'edit_siswa_logic.dart';

class EditSiswaScreen extends StatelessWidget {
  final int siswaId;
  final String no;
  final String nama;
  final DateTime tanggal;
  final String? statusAwal;
  final String? keteranganAwal;
  final String? suratUrl;

  const EditSiswaScreen({
    super.key,
    required this.siswaId,
    required this.no,
    required this.nama,
    required this.tanggal,
    this.statusAwal,
    this.keteranganAwal,
    this.suratUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditSiswaLogic(),
      child: _EditSiswaForm(
        siswaId: siswaId,
        no: no,
        nama: nama,
        tanggal: tanggal,
        statusAwal: statusAwal,
        keteranganAwal: keteranganAwal,
        suratUrl: suratUrl,
      ),
    );
  }
}

class _EditSiswaForm extends StatefulWidget {
  final int siswaId;
  final String no;
  final String nama;
  final DateTime tanggal;
  final String? statusAwal;
  final String? keteranganAwal;
  final String? suratUrl;

  const _EditSiswaForm({
    required this.siswaId,
    required this.no,
    required this.nama,
    required this.tanggal,
    this.statusAwal,
    this.keteranganAwal,
    this.suratUrl,
  });

  @override
  State<_EditSiswaForm> createState() => _EditSiswaFormState();
}

class _EditSiswaFormState extends State<_EditSiswaForm> {
  final _formKey = GlobalKey<FormState>();
  late String selectedStatus;
  late TextEditingController _keteranganController;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.statusAwal?.toLowerCase() ?? 'hadir';
    _keteranganController =
        TextEditingController(text: widget.keteranganAwal ?? '');

    // If keteranganAwal is empty/null, fetch existing attendance in background
    if (widget.keteranganAwal == null || widget.keteranganAwal!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingKeterangan();
      });
    }
  }

  Future<void> _loadExistingKeterangan() async {
    if (!mounted) return;
    final logic = context.read<EditSiswaLogic>();
    final ket = await logic.fetchInitialKeterangan(
      siswaId: widget.siswaId,
      tanggal: widget.tanggal,
    );
    if (ket != null &&
        ket.isNotEmpty &&
        _keteranganController.text.isEmpty &&
        mounted) {
      setState(() {
        _keteranganController.text = ket;
      });
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<EditSiswaLogic>();
    final currentStatus = AttendanceStatus.fromValue(selectedStatus);
    final isButuhSurat = currentStatus.requiresDocument;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Validasi Absensi Siswa',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info Hero Card
              _buildStudentHeaderCard()
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: -0.1, end: 0),

              const SizedBox(height: 24),

              // Interactive Status Selector Pills
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: StatusSelectorPills(
                  selectedStatus: selectedStatus,
                  onStatusChanged: (newStatus) {
                    setState(() => selectedStatus = newStatus);
                  },
                ),
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              // Form Keterangan / Catatan Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keterangan / Catatan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tambahkan catatan keterangan absensi siswa di sini',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick suggestion chips
                    _buildQuickKeteranganChips(),

                    const SizedBox(height: 12),

                    // Text Field
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 3,
                      minLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: selectedStatus == 'alfa'
                            ? 'Contoh: Siswa tidak ada di kelas saat diabsen ulang...'
                            : 'Tulis keterangan atau catatan absensi di sini...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _keteranganController,
                          builder: (context, val, child) {
                            if (val.text.isEmpty) return const SizedBox.shrink();
                            return IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _keteranganController.clear();
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    if (selectedStatus == 'alfa') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Saat diubah ke Alfa, jam masuk yang tercatat sebelumnya otomatis dihapus.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              // Letter Attachment Section (with smooth animation)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isButuhSurat
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.attachment_rounded, color: Color(0xFF2563EB), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Lampiran Surat Dokter / Izin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Wajib/disarankan melampirkan foto surat dokter atau surat dari orang tua.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      // Preview
                      if (logic.selectedFile != null)
                        _buildFilePreview(logic.selectedFile!)
                      else if (widget.suratUrl != null && widget.suratUrl!.isNotEmpty)
                        _buildUrlPreview(widget.suratUrl!)
                      else
                        _buildUploadPlaceholder(),

                      const SizedBox(height: 14),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: BouncingWidget(
                              onTap: () => logic.pickImage(ImageSource.camera),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_rounded, size: 18, color: Color(0xFF2563EB)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Ambil Foto',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
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
                          Expanded(
                            child: BouncingWidget(
                              onTap: () => logic.pickImage(ImageSource.gallery),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF8B5CF6)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Pilih Galeri',
                                      style: TextStyle(
                                        color: Color(0xFF8B5CF6),
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
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Bouncy Save Button
              BouncingWidget(
                onTap: logic.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        HapticFeedback.mediumImpact();

                        final success = await logic.submitAbsensi(
                          siswaId: widget.siswaId,
                          tanggal: widget.tanggal,
                          status: selectedStatus,
                          keterangan: _keteranganController.text.trim(),
                          namaSiswa: widget.nama,
                          oldSuratUrl: widget.suratUrl,
                        );

                        if (success) {
                          HapticFeedback.heavyImpact();
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text('Perubahan presensi berhasil disimpan!'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          navigator.pop(true);
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text('Gagal menyimpan perubahan.'),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: logic.isLoading
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : [const Color(0xFF1D4ED8), const Color(0xFF2563EB)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: logic.isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: logic.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'SIMPAN PERUBAHAN',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickKeteranganChips() {
    List<String> suggestions = [];
    if (selectedStatus == 'alfa') {
      suggestions = [
        'Tidak ada di kelas saat diabsen ulang',
        'Tanpa keterangan',
        'Meninggalkan kelas / bolos',
      ];
    } else if (selectedStatus == 'sakit') {
      suggestions = [
        'Sakit demam / flu',
        'Istirahat dokter',
        'Sakit perut',
      ];
    } else if (selectedStatus == 'izin') {
      suggestions = [
        'Izin acara keluarga',
        'Izin keperluan mendesak',
        'Izin urusan keluarga',
      ];
    } else if (selectedStatus == 'terlambat') {
      suggestions = [
        'Terlambat karena macet',
        'Terlambat karena cuaca hujan',
        'Bangun kesiangan',
      ];
    } else {
      suggestions = [
        'Hadir di kelas',
        'Absensi manual guru',
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilihan Cepat:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: suggestions.map((chipText) {
            final isSelected = _keteranganController.text == chipText;
            return InkWell(
              onTap: () {
                setState(() {
                  _keteranganController.text = chipText;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  chipText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudentHeaderCard() {
    final tglStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(widget.tanggal);
    final initial = widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Absen #${widget.no}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tglStr,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(File file) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'Foto Baru',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlPreview(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const Text(
              'Gagal memuat gambar',
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text(
            'Belum ada lampiran surat',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
