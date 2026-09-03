import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wali_murid_models.dart';
import 'onesignal_service.dart';

/// Local Storage Service to manage linked child profiles for parents
class WaliStorageService {
  static final WaliStorageService _instance = WaliStorageService._internal();
  factory WaliStorageService() => _instance;
  WaliStorageService._internal();

  static const String _keyChildren = 'wali_saved_children';
  static const String _keyActiveChildId = 'wali_active_child_id';

  /// Check if parent has any active linked child session
  Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childrenJson = prefs.getStringList(_keyChildren);
      return childrenJson != null && childrenJson.isNotEmpty;
    } catch (e) {
      debugPrint('[WaliStorage] Error checking active session: $e');
      return false;
    }
  }

  /// Get all saved linked children
  Future<List<ChildProfile>> getSavedChildren() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_keyChildren);
      if (rawList == null || rawList.isEmpty) return [];

      return rawList.map((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return ChildProfile.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('[WaliStorage] Error getting saved children: $e');
      return [];
    }
  }

  /// Save or update a child profile, and set as active if desired
  Future<void> saveChild(ChildProfile child, {bool makeActive = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getSavedChildren();

      // Check if child is already in the list, update it or append
      final existingIndex = currentList.indexWhere((c) => c.id == child.id);
      if (existingIndex >= 0) {
        currentList[existingIndex] = child;
      } else {
        currentList.add(child);
      }

      // Save back to SharedPreferences
      final encodedList = currentList.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_keyChildren, encodedList);

      if (makeActive || currentList.length == 1) {
        await prefs.setInt(_keyActiveChildId, child.id);
      }

      // Synchronize OneSignal Tags for all children
      await syncOneSignalTags(currentList);
      debugPrint('[WaliStorage] Berhasil menyimpan anak: ${child.nama} (ID: ${child.id})');
    } catch (e) {
      debugPrint('[WaliStorage] Error saving child: $e');
    }
  }

  /// Get the currently selected active child
  Future<ChildProfile?> getActiveChild() async {
    try {
      final children = await getSavedChildren();
      if (children.isEmpty) return null;

      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getInt(_keyActiveChildId);

      if (activeId != null) {
        final match = children.firstWhere(
          (c) => c.id == activeId,
          orElse: () => children.first,
        );
        return match;
      }

      return children.first;
    } catch (e) {
      debugPrint('[WaliStorage] Error getting active child: $e');
      return null;
    }
  }

  /// Set the active child by ID
  Future<void> setActiveChildId(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyActiveChildId, childId);
      debugPrint('[WaliStorage] Active child ID diset ke: $childId');
    } catch (e) {
      debugPrint('[WaliStorage] Error setting active child ID: $e');
    }
  }

  /// Remove a linked child
  Future<void> removeChild(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getSavedChildren();
      currentList.removeWhere((c) => c.id == childId);

      final encodedList = currentList.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_keyChildren, encodedList);

      final activeId = prefs.getInt(_keyActiveChildId);
      if (activeId == childId) {
        if (currentList.isNotEmpty) {
          await prefs.setInt(_keyActiveChildId, currentList.first.id);
        } else {
          await prefs.remove(_keyActiveChildId);
        }
      }

      // Re-sync OneSignal Tags
      await syncOneSignalTags(currentList);
      debugPrint('[WaliStorage] Anak ID $childId berhasil dihapus');
    } catch (e) {
      debugPrint('[WaliStorage] Error removing child: $e');
    }
  }

  /// Clear all parent data (Logout)
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyChildren);
      await prefs.remove(_keyActiveChildId);
      await prefs.remove(_keyReadNotifications);
      await prefs.remove(_keyInAppNotifications);

      // Clean all cached attendance snapshots
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_today_att_') || key.startsWith('cache_month_stats_')) {
          await prefs.remove(key);
        }
      }

      // Logout OneSignal
      await OneSignalService.logoutUser();
      debugPrint('[WaliStorage] Sesi wali murid berhasil dibersihkan secara total');
    } catch (e) {
      debugPrint('[WaliStorage] Error clearing session: $e');
    }
  }

  static const String _keyReadNotifications = 'wali_read_notification_ids';
  static const String _keyInAppNotifications = 'wali_in_app_notifications';

  /// Save an incoming in-app notification (e.g. from OneSignal push)
  Future<void> saveInAppNotification(WaliNotificationItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getLocalInAppNotifications();
      final existingIndex = currentList.indexWhere((n) => n.id == item.id);
      if (existingIndex >= 0) {
        currentList[existingIndex] = item;
      } else {
        currentList.insert(0, item);
      }
      if (currentList.length > 50) {
        currentList.removeRange(50, currentList.length);
      }
      final encoded = currentList.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_keyInAppNotifications, encoded);
      debugPrint('[WaliStorage] In-app notifikasi disimpan: ${item.title}');
    } catch (e) {
      debugPrint('[WaliStorage] Error saving in-app notification: $e');
    }
  }

  /// Get local in-app notifications
  Future<List<WaliNotificationItem>> getLocalInAppNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_keyInAppNotifications);
      if (rawList == null || rawList.isEmpty) return [];
      return rawList.map((str) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return WaliNotificationItem.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('[WaliStorage] Error getting local in-app notifications: $e');
      return [];
    }
  }

  /// Clear all local in-app notifications
  Future<void> clearInAppNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInAppNotifications);
    } catch (e) {
      debugPrint('[WaliStorage] Error clearing in-app notifications: $e');
    }
  }

  /// Get list of read notification IDs
  Future<Set<String>> getReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyReadNotifications) ?? [];
      return list.toSet();
    } catch (e) {
      return {};
    }
  }

  /// Mark single notification as read
  Future<void> markNotificationAsRead(String notifId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current =
          (prefs.getStringList(_keyReadNotifications) ?? []).toSet();
      current.add(notifId);
      await prefs.setStringList(_keyReadNotifications, current.toList());
    } catch (e) {
      debugPrint('[WaliStorage] Error marking notif read: $e');
    }
  }

  /// Mark multiple notifications as read
  Future<void> markAllNotificationsAsRead(Iterable<String> notifIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current =
          (prefs.getStringList(_keyReadNotifications) ?? []).toSet();
      current.addAll(notifIds);
      await prefs.setStringList(_keyReadNotifications, current.toList());
    } catch (e) {
      debugPrint('[WaliStorage] Error marking all notifs read: $e');
    }
  }

  /// Sync OneSignal Tags for all linked children so push notifications arrive
  Future<void> syncOneSignalTags(List<ChildProfile> children) async {
    try {
      if (children.isEmpty) {
        await OneSignalService.logoutUser();
        return;
      }

      final primaryChild = children.first;
      // Login with primary student ID so Web Admin and Mobile aliases match directly
      await OneSignalService.loginUser('${primaryChild.id}');

      try {
        OneSignal.User.addAlias('siswa_id', '${primaryChild.id}');
        OneSignal.User.addAlias('siswa_tag', 'siswa_${primaryChild.id}');
        if (primaryChild.nis.isNotEmpty) {
          OneSignal.User.addAlias('nis', primaryChild.nis);
          OneSignal.User.addAlias('nis_tag', 'nis_${primaryChild.nis}');
        }
      } catch (e) {
        debugPrint('[WaliStorage] Info alias: $e');
      }

      // Only send maximum 2 essential tags to stay strictly within OneSignal's free tier tag limits (max 3)
      final tags = <String, String>{
        'role': 'wali_murid',
        'siswa_id': '${primaryChild.id}',
      };

      await OneSignalService.setTags(tags);
      debugPrint('[WaliStorage] OneSignal Tags synced for child ${primaryChild.nama} (ID: ${primaryChild.id}): $tags');
    } catch (e) {
      debugPrint('[WaliStorage] Error syncing OneSignal tags: $e');
    }
  }

  // ===========================================================================
  // OFFLINE SNAPSHOT CACHING (Instant Perceived Load)
  // ===========================================================================

  static const String _prefixTodayAttendance = 'cache_today_att_';
  static const String _prefixMonthlyStats = 'cache_month_stats_';

  /// Cache today's attendance data for instant offline view
  Future<void> cacheTodayAttendance(int childId, TodayAttendance data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefixTodayAttendance$childId', jsonEncode(data.toJson()));
    } catch (_) {}
  }

  /// Get cached today's attendance data
  Future<TodayAttendance?> getCachedTodayAttendance(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_prefixTodayAttendance$childId');
      if (str == null || str.isEmpty) return null;
      final map = jsonDecode(str) as Map<String, dynamic>;
      return TodayAttendance.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Cache monthly attendance stats for instant offline view
  Future<void> cacheMonthlyStats(int childId, int month, int year, MonthlyAttendanceStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefixMonthlyStats${childId}_${month}_$year', jsonEncode(stats.toJson()));
    } catch (_) {}
  }

  /// Get cached monthly attendance stats
  Future<MonthlyAttendanceStats?> getCachedMonthlyStats(int childId, int month, int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_prefixMonthlyStats${childId}_${month}_$year');
      if (str == null || str.isEmpty) return null;
      final map = jsonDecode(str) as Map<String, dynamic>;
      return MonthlyAttendanceStats.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

final waliStorageService = WaliStorageService();
