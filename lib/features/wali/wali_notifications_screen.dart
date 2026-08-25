import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../data/models/wali_murid_models.dart';
import '../../data/repositories/wali_repository.dart';
import '../../data/services/wali_storage_service.dart';

/// Screen displaying notification timeline & school announcements for parents
class WaliNotificationsScreen extends StatefulWidget {
  final ChildProfile child;

  const WaliNotificationsScreen({
    super.key,
    required this.child,
  });

  @override
  State<WaliNotificationsScreen> createState() =>
      _WaliNotificationsScreenState();
}

class _WaliNotificationsScreenState extends State<WaliNotificationsScreen> {
  final _waliRepository = WaliRepository();
  bool _isLoading = true;
  List<WaliNotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final items =
          await _waliRepository.getNotificationsForChild(widget.child);

      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final allIds = _notifications.map((n) => n.id).toList();
    await waliStorageService.markAllNotificationsAsRead(allIds);
    HapticFeedback.selectionClick();
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Riwayat & Pengumuman',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (hasUnread)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded,
                  size: 16, color: Color(0xFF2563EB)),
              label: const Text(
                'Tandai Dibaca',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _buildNotificationCard(item, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(WaliNotificationItem item, int index) {
    final config = _getNotificationConfig(item.type);
    final timeStr =
        DateFormat('d MMM yyyy • HH:mm', 'id_ID').format(item.timestamp);

    return GestureDetector(
      onTap: () async {
        if (!item.isRead) {
          await waliStorageService.markNotificationAsRead(item.id);
          _loadNotifications();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF93C5FD),
            width: item.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Box
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    config.icon,
                    color: config.color,
                    size: 22,
                  ),
                ),
                if (!item.isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item.isRead
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF1E3A8A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Baru',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms).slideY(
          begin: 0.05,
          end: 0,
        );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belum Ada Pemberitahuan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Notifikasi absensi masuk dan pulang ananda akan muncul di sini secara otomatis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  _NotificationConfig _getNotificationConfig(String type) {
    switch (type) {
      case 'masuk':
        return _NotificationConfig(
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
        );
      case 'pulang':
        return _NotificationConfig(
          icon: Icons.logout_rounded,
          color: const Color(0xFF0284C7),
        );
      case 'terlambat':
        return _NotificationConfig(
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B),
        );
      case 'pengumuman':
      default:
        return _NotificationConfig(
          icon: Icons.campaign_rounded,
          color: const Color(0xFF8B5CF6),
        );
    }
  }
}

class _NotificationConfig {
  final IconData icon;
  final Color color;

  _NotificationConfig({
    required this.icon,
    required this.color,
  });
}
