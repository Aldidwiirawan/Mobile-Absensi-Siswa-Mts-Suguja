import 'dart:convert';
import 'package:flutter/foundation.dart';
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

      // Logout OneSignal
      await OneSignalService.logoutUser();
      debugPrint('[WaliStorage] Sesi wali murid berhasil dibersihkan');
    } catch (e) {
      debugPrint('[WaliStorage] Error clearing session: $e');
    }
  }

  static const String _keyReadNotifications = 'wali_read_notification_ids';

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

      final tags = <String, String>{
        'role': 'wali_murid',
        'children_count': children.length.toString(),
      };

      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        tags['siswa_id_${child.id}'] = 'true';
        if (child.kelasId != null) {
          tags['kelas_id_${child.id}'] = child.kelasId.toString();
        }
        // Primary student ID for 1st child
        if (i == 0) {
          tags['siswa_id'] = child.id.toString();
          tags['nama_siswa'] = child.nama;
          if (child.kelasId != null) {
            tags['kelas_id'] = child.kelasId.toString();
          }
          if (child.namaKelas.isNotEmpty && child.namaKelas != 'Belum Ditentukan') {
            tags['nama_kelas'] = child.namaKelas;
          }
        }
      }

      await OneSignalService.setTags(tags);
      debugPrint('[WaliStorage] OneSignal Tags synced for ${children.length} anak: $tags');
    } catch (e) {
      debugPrint('[WaliStorage] Error syncing OneSignal tags: $e');
    }
  }
}

final waliStorageService = WaliStorageService();
