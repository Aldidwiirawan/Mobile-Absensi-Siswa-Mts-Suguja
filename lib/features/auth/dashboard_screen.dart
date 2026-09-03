import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/ui/animated_counter.dart';
import '../../core/ui/bouncing_widget.dart';
import '../../data/models/models.dart';
import 'dashboard_logic.dart';
import 'form_login.dart';
import '../kelas/kelas_screen.dart';
import '../persetujuan_surat/persetujuan_surat_screen.dart';
import '../profil/profil_guru_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardLogic()
        ..loadDashboard()
        ..startAutoRefresh(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with WidgetsBindingObserver {
  String? _selectedKelas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final logic = context.read<DashboardLogic>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      logic.stopAutoRefresh();
    } else if (state == AppLifecycleState.resumed) {
      logic.loadDashboard(isBackground: true);
      logic.startAutoRefresh();
    }
  }

  void _onKelasSelected(String namaKelas) {
    setState(() => _selectedKelas = namaKelas);
    Navigator.pop(context); // Close drawer
  }

  void _openKelasDirectly(String namaKelas) {
    setState(() => _selectedKelas = namaKelas);
  }

  void _onHomeSelected() {
    setState(() => _selectedKelas = null);
    Navigator.pop(context); // Close drawer
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<DashboardLogic>();

    if (logic.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Memuat Data Presensi...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (logic.errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  logic.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 15),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: logic.loadDashboard,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate light
      appBar: AppBar(
        leading: _selectedKelas != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() => _selectedKelas = null);
                  logic.loadDashboard(isBackground: true);
                },
              )
            : null,
        title: Text(
          _selectedKelas ?? 'Dashboard Guru',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.fact_check_outlined),
                tooltip: 'Persetujuan Surat',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PersetujuanSuratScreen(),
                    ),
                  ).then((_) => logic.loadDashboard());
                },
              ),
              if (logic.pendingSuratCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${logic.pendingSuratCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: logic.guruProfile?.displayAvatarUrl != null
                  ? NetworkImage(logic.guruProfile!.displayAvatarUrl!)
                  : null,
              child: logic.guruProfile?.displayAvatarUrl == null
                  ? const Icon(Icons.person_rounded,
                      size: 16, color: Color(0xFF2563EB))
                  : null,
            ),
            tooltip: 'Profil Saya',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilGuruScreen(),
                ),
              ).then((_) => logic.loadDashboard());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Perbarui Data',
            onPressed: logic.loadDashboard,
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _selectedKelas == null ? _buildDrawer(context, logic) : null,
      body: _selectedKelas != null
          ? PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                setState(() => _selectedKelas = null);
                logic.loadDashboard(isBackground: true);
              },
              child: KelasScreen(namaKelas: _selectedKelas!),
            )
          : RefreshIndicator(
              onRefresh: logic.loadDashboard,
              color: const Color(0xFF2563EB),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                children: [
                  // Greeting & Date Header
                  _buildHeaderGreeting(logic.guruProfile?.nama),
                  const SizedBox(height: 16),

                  // Hero Attendance Ring Card
                  _AttendanceHeroCard(
                    rate: logic.attendanceRate,
                    totalHadir: logic.totalHadir,
                    totalSiswa: logic.totalSiswa,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 16),

                  // Persetujuan Izin / Sakit Quick Banner
                  BouncingWidget(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersetujuanSuratScreen(),
                        ),
                      ).then((_) => logic.loadDashboard());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: logic.pendingSuratCount > 0
                              ? const Color(0xFFC7D2FE)
                              : const Color(0xFFE2E8F0),
                          width: logic.pendingSuratCount > 0 ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: logic.pendingSuratCount > 0
                                ? const Color(0xFF6366F1).withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.fact_check_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              if (logic.pendingSuratCount > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        'Persetujuan Izin / Sakit',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (logic.pendingSuratCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${logic.pendingSuratCount} Menunggu',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  logic.pendingSuratCount > 0
                                      ? 'Ada ${logic.pendingSuratCount} pengajuan surat butuh persetujuan Anda'
                                      : 'Tinjau permohonan surat izin/sakit siswa',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: logic.pendingSuratCount > 0
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF64748B),
                                    fontWeight: logic.pendingSuratCount > 0
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 450.ms),

                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ringkasan Kelas Hari Ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${logic.summaryList.length} Kelas',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (logic.summaryList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada kelas yang diajar.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    ...logic.summaryList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return _ClassSummaryCard(
                        data: data,
                        onTap: () => _openKelasDirectly(data.namaKelas),
                      )
                          .animate()
                          .fadeIn(
                            delay: (100 * index).ms,
                            duration: 400.ms,
                          )
                          .slideY(begin: 0.15, end: 0);
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderGreeting(String? guruName) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  guruName ?? 'Bapak/Ibu Guru',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, DashboardLogic logic) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header Card (Clickable to Profil)
          InkWell(
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilGuruScreen(),
                ),
              ).then((_) => logic.loadDashboard());
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2563EB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: logic.guruProfile?.displayAvatarUrl != null
                          ? NetworkImage(logic.guruProfile!.displayAvatarUrl!)
                          : null,
                      child: logic.guruProfile?.displayAvatarUrl == null
                          ? const Icon(Icons.person_rounded,
                              size: 32, color: Color(0xFF2563EB))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          logic.guruProfile?.nama ?? 'Guru Pengampu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppConstants.schoolName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.dashboard_rounded, color: Color(0xFF2563EB)),
            title: const Text(
              'Dashboard Utama',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            selected: _selectedKelas == null,
            selectedTileColor: Colors.blue.shade50,
            onTap: _onHomeSelected,
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_rounded,
                color: Color(0xFF0284C7)),
            title: const Text(
              'Profil & Akun Saya',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilGuruScreen(),
                ),
              ).then((_) => logic.loadDashboard());
            },
          ),
          ListTile(
            leading: const Icon(Icons.mark_email_read_rounded,
                color: Color(0xFF8B5CF6)),
            title: const Text(
              'Persetujuan Izin / Sakit',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: logic.pendingSuratCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${logic.pendingSuratCount} Baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersetujuanSuratScreen(),
                ),
              ).then((_) => logic.loadDashboard());
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.class_outlined, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'DAFTAR KELAS DIAMPU',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: logic.kelasDiampu.entries.map((entry) {
                return ExpansionTile(
                  leading: const Icon(Icons.folder_open_rounded, color: Color(0xFF3B82F6)),
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  children: entry.value.map((kelasName) {
                    final isSelected = _selectedKelas == kelasName;
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 48, right: 16),
                      leading: Icon(
                        Icons.chevron_right_rounded,
                        color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
                      ),
                      title: Text(
                        kelasName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Colors.blue.shade50,
                      onTap: () => _onKelasSelected(kelasName),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            title: const Text(
              'Keluar Akun',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              final navigator = Navigator.of(context);
              await logic.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AttendanceHeroCard extends StatelessWidget {
  final double rate;
  final int totalHadir;
  final int totalSiswa;

  const _AttendanceHeroCard({
    required this.rate,
    required this.totalHadir,
    required this.totalSiswa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A), // Deep Navy
            Color(0xFF2563EB), // Royal Blue
            Color(0xFF3B82F6), // Vibrant Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Glowing Progress Ring
          AnimatedAttendanceRing(
            rate: rate,
            size: 84,
            strokeWidth: 9,
            gradientColors: const [
              Color(0xFF67E8F9), // Cyan
              Color(0xFF34D399), // Emerald
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRESENSI KESELURUHAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Total Kehadiran Siswa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalSiswa > 0
                      ? '$totalHadir dari $totalSiswa siswa hadir hari ini'
                      : 'Akumulasi kehadiran siswa hari ini',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassSummaryCard extends StatelessWidget {
  final ClassSummary data;
  final VoidCallback onTap;

  const _ClassSummaryCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncingWidget(
      onTap: onTap,
      scaleFactor: 0.97,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.namaKelas,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${data.totalSiswa} Siswa Terdaftar',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Buka',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem('Hadir', data.hadir + data.pulang, const Color(0xFF10B981), Icons.check_circle_outline_rounded),
                  _StatItem('Telat', data.terlambat, const Color(0xFFF59E0B), Icons.schedule_rounded),
                  _StatItem('Sakit', data.sakit, const Color(0xFF3B82F6), Icons.healing_rounded),
                  _StatItem('Izin', data.izin, const Color(0xFF8B5CF6), Icons.assignment_outlined),
                  _StatItem('Alfa', data.alfa, const Color(0xFFEF4444), Icons.cancel_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatItem(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              AnimatedCountText(
                value: value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
