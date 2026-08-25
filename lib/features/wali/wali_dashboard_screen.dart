import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/ui/bouncing_widget.dart';
import '../../data/models/wali_murid_models.dart';
import '../../data/repositories/wali_repository.dart';
import '../../data/services/wali_storage_service.dart';
import '../auth/form_login.dart';
import 'widgets/add_child_dialog.dart';
import 'widgets/child_switcher_bar.dart';
import 'widgets/live_attendance_card.dart';
import 'widgets/monthly_stats_card.dart';
import 'pengajuan_surat_screen.dart';
import 'wali_notifications_screen.dart';

/// Main Dashboard Screen for Wali Murid (Parents)
class WaliDashboardScreen extends StatefulWidget {
  const WaliDashboardScreen({super.key});

  @override
  State<WaliDashboardScreen> createState() => _WaliDashboardScreenState();
}

class _WaliDashboardScreenState extends State<WaliDashboardScreen> {
  final _waliRepository = WaliRepository();

  List<ChildProfile> _children = [];
  ChildProfile? _activeChild;

  TodayAttendance? _todayAttendance;
  MonthlyAttendanceStats? _monthlyStats;
  DateTime _selectedMonth = DateTime.now();
  int _unreadNotifCount = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final children = await waliStorageService.getSavedChildren();
      final active = await waliStorageService.getActiveChild();

      if (children.isEmpty) {
        // No children linked, redirect to login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
      }

      setState(() {
        _children = children;
        _activeChild = active ?? children.first;
      });

      if (_activeChild != null) {
        await _fetchChildData(_activeChild!);
      }
    } catch (e) {
      debugPrint('[WaliDashboard] Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchChildData(ChildProfile child) async {
    try {
      final profileFuture = _waliRepository.getChildProfileById(child.id);
      final unreadFuture = _waliRepository.getUnreadNotificationCount(child);
      final todayFuture = _waliRepository.getTodayAttendance(
        child.id,
        kelasId: child.kelasId,
      );
      final statsFuture = _waliRepository.getMonthlyAttendanceStats(
        siswaId: child.id,
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );

      final results = await Future.wait([
        todayFuture,
        statsFuture,
        profileFuture,
        unreadFuture,
      ]);

      if (mounted) {
        final freshProfile = results[2] as ChildProfile?;
        if (freshProfile != null) {
          await waliStorageService.saveChild(
            freshProfile,
            makeActive: (_activeChild?.id == freshProfile.id),
          );
          final updatedChildren = await waliStorageService.getSavedChildren();
          setState(() {
            _children = updatedChildren;
            if (_activeChild?.id == freshProfile.id) {
              _activeChild = freshProfile;
            }
          });
        }

        setState(() {
          _todayAttendance = results[0] as TodayAttendance;
          _monthlyStats = results[1] as MonthlyAttendanceStats;
          _unreadNotifCount = results[3] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint('[WaliDashboard] Error fetching child data: $e');
    }
  }

  Future<void> _handleChildSwitch(ChildProfile newChild) async {
    if (_activeChild?.id == newChild.id) return;
    HapticFeedback.selectionClick();

    setState(() {
      _activeChild = newChild;
      _todayAttendance = null;
      _monthlyStats = null;
    });

    await waliStorageService.setActiveChildId(newChild.id);
    await _fetchChildData(newChild);
  }

  Future<void> _handleRefresh() async {
    if (_activeChild == null) return;
    await _fetchChildData(_activeChild!);
  }

  void _handleAddChild() {
    AddChildBottomSheet.show(
      context,
      onChildAdded: (newChild) async {
        final updatedList = await waliStorageService.getSavedChildren();
        setState(() {
          _children = updatedList;
          _activeChild = newChild;
        });
        await _fetchChildData(newChild);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil menghubungkan ananda ${newChild.nama}'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun Orang Tua?'),
        content: const Text(
          'Anda dapat masuk kembali kapan saja menggunakan NISN dan PIN ananda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await waliStorageService.clearAll();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String? phone, String namaSiswa) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor kontak wali kelas belum tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final message = Uri.encodeComponent(
      'Assalamu\'alaikum Bapak/Ibu Wali Kelas, saya orang tua dari ananda $namaSiswa.',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF2563EB),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverHeader(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Multi-Child Switcher Bar
                        ChildSwitcherBar(
                          children: _children,
                          activeChild: _activeChild,
                          onChildSelected: _handleChildSwitch,
                          onAddChild: _handleAddChild,
                        ),

                        // 2. Live Today Attendance Status Card
                        if (_todayAttendance != null && _activeChild != null)
                          LiveAttendanceCard(
                            attendance: _todayAttendance!,
                            namaSiswa: _activeChild!.nama,
                            onRefresh: _handleRefresh,
                          )
                        else
                          _buildLoadingCard(),

                        // 3. Quick Action Navigation Bar
                        _buildQuickActionsBar(),

                        // 4. Monthly Attendance Summary Card
                        if (_monthlyStats != null)
                          MonthlyStatsCard(
                            stats: _monthlyStats!,
                            selectedMonth: _selectedMonth,
                            onMonthChanged: (newMonth) {
                              setState(() => _selectedMonth = newMonth);
                              if (_activeChild != null) {
                                _fetchChildData(_activeChild!);
                              }
                            },
                          )
                        else
                          _buildLoadingCard(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF1E3A8A),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E3A8A), // Deep Navy
                Color(0xFF2563EB), // Royal Blue
                Color(0xFF3B82F6), // Vibrant Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: School Label & Logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            AppConstants.schoolName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),

                      // Logout / Exit Button
                      BouncingWidget(
                        onTap: _handleLogout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Keluar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Student Title & Class Badge
                  if (_activeChild != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activeChild!.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _activeChild!.namaKelas,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'NIS: ${_activeChild!.nis}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsBar() {
    if (_activeChild == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          // 1. Banner Ajukan Surat Izin / Sakit Mandiri
          BouncingWidget(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PengajuanSuratScreen(child: _activeChild!),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.note_add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajukan Surat Izin / Sakit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kirim surat izin/sakit mandiri ke Wali Kelas',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Secondary Row: Riwayat Info & Chat Wali Kelas
          Row(
            children: [
              // Riwayat Notifikasi
              Expanded(
                child: BouncingWidget(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WaliNotificationsScreen(child: _activeChild!),
                      ),
                    ).then((_) {
                      if (mounted && _activeChild != null) {
                        _fetchChildData(_activeChild!);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _unreadNotifCount > 0
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFE2E8F0),
                        width: _unreadNotifCount > 0 ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
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
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                            ),
                            if (_unreadNotifCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Riwayat Info',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_unreadNotifCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$_unreadNotifCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                _unreadNotifCount > 0
                                    ? '$_unreadNotifCount baru belum dibaca'
                                    : 'Notifikasi sekolah',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _unreadNotifCount > 0
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF64748B),
                                  fontWeight: _unreadNotifCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Chat Wali Kelas
              Expanded(
                child: BouncingWidget(
                  onTap: () => _openWhatsApp(
                    _activeChild?.waliKelasNoHp,
                    _activeChild?.nama ?? '',
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.chat_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wali Kelas',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Kirim pesan WA',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
