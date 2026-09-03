import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/ui/bouncing_widget.dart';
import '../../data/models/models.dart';
import 'kelas_logic.dart';
import '../edit_siswa/edit_siswa_screen.dart';

class KelasScreen extends StatefulWidget {
  final String namaKelas;

  const KelasScreen({super.key, required this.namaKelas});

  @override
  State<KelasScreen> createState() => _KelasScreenState();
}

class _KelasScreenState extends State<KelasScreen> {
  late final KelasLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = KelasLogic()..init(widget.namaKelas);
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _logic,
      child: const _KelasScreenView(),
    );
  }
}

class _KelasScreenView extends StatelessWidget {
  const _KelasScreenView();

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<KelasLogic>();

    return Column(
      children: [
        // Header & Search Filter Card
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Input
              TextField(
                controller: logic.searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama siswa...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                  suffixIcon: logic.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 20),
                          onPressed: () => logic.searchController.clear(),
                        )
                      : null,
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
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Semua',
                      count: logic.totalCount,
                      filterKey: 'all',
                      selectedKey: logic.selectedFilter,
                      color: const Color(0xFF2563EB),
                      onTap: () => logic.setFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Hadir',
                      count: logic.hadirCount,
                      filterKey: 'hadir',
                      selectedKey: logic.selectedFilter,
                      color: const Color(0xFF10B981),
                      onTap: () => logic.setFilter('hadir'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Telat',
                      count: logic.terlambatCount,
                      filterKey: 'terlambat',
                      selectedKey: logic.selectedFilter,
                      color: const Color(0xFFF59E0B),
                      onTap: () => logic.setFilter('terlambat'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Sakit/Izin',
                      count: logic.sakitIzinCount,
                      filterKey: 'sakit_izin',
                      selectedKey: logic.selectedFilter,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => logic.setFilter('sakit_izin'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Alfa',
                      count: logic.alfaCount,
                      filterKey: 'alfa',
                      selectedKey: logic.selectedFilter,
                      color: const Color(0xFFEF4444),
                      onTap: () => logic.setFilter('alfa'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List Content
        Expanded(
          child: logic.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                )
              : logic.errorMessage.isNotEmpty
                  ? _buildErrorState(context, logic)
                  : RefreshIndicator(
                      onRefresh: () async => await logic.fetchData(),
                      color: const Color(0xFF2563EB),
                      child: logic.filteredList.isEmpty
                          ? _buildEmptyState(context, logic)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: logic.filteredList.length,
                              itemBuilder: (context, index) {
                                final item = logic.filteredList[index];
                                return _SiswaCardItem(
                                  key: ValueKey(item.id),
                                  item: item,
                                  index: index + 1,
                                )
                                    .animate()
                                    .fadeIn(
                                      delay: (40 * (index % 12)).ms,
                                      duration: 350.ms,
                                    )
                                    .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    );
                              },
                            ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required String filterKey,
    required String selectedKey,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedKey == filterKey;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, KelasLogic logic) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 380,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada siswa ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              logic.searchController.text.isNotEmpty
                  ? 'Coba gunakan kata kunci pencarian yang lain'
                  : 'Belum ada data pada kategori filter ini',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (logic.searchController.text.isNotEmpty || logic.selectedFilter != 'all')
              TextButton.icon(
                onPressed: () {
                  logic.searchController.clear();
                  logic.setFilter('all');
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset Filter'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, KelasLogic logic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(logic.errorMessage, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => logic.fetchData(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SiswaCardItem extends StatelessWidget {
  final SiswaWithAbsensi item;
  final int index;

  const _SiswaCardItem({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final logic = context.read<KelasLogic>();
    final statusText = logic.getStatusDisplay(item);
    final statusColor = logic.getStatusColor(item);

    // Initial for student avatar
    final initial = item.nama.isNotEmpty ? item.nama[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Student Avatar Initial Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.2),
                    statusColor.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${item.no > 0 ? item.no : index}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.jamMasuk != null) ...[
                        Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Masuk: ${item.jamMasuk!.substring(0, 5)} WIB',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ] else ...[
                        Text(
                          'ID Siswa: #${item.id}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                      if (item.fileUrl != null && item.fileUrl!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file_rounded, size: 10, color: Color(0xFF2563EB)),
                              Text(
                                'Ada Surat',
                                style: TextStyle(fontSize: 9, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.keterangan != null && item.keterangan!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 11, color: Colors.orange.shade800),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.keterangan!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontStyle: FontStyle.italic,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Status Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Bouncy Edit Button
            BouncingWidget(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSiswaScreen(
                      siswaId: item.id,
                      tanggal: DateTime.now(),
                      no: item.no.toString(),
                      nama: item.nama,
                      statusAwal: item.statusAbsensi,
                      keteranganAwal: item.keterangan,
                      suratUrl: item.fileUrl,
                    ),
                  ),
                );
                if (context.mounted) logic.fetchData();
              },
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}
