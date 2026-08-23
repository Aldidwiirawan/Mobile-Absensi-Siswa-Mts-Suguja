import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../core/constants.dart';

/// Service to handle OneSignal Push Notifications and Attendance Alerts
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  static bool _isInitialized = false;

  /// Initialize OneSignal SDK
  static Future<void> initialize() async {
    final appId = AppConstants.onesignalAppId;
    if (appId.isEmpty) {
      debugPrint('[OneSignal] Info: ONESIGNAL_APP_ID belum diisi di file .env');
      return;
    }

    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      }

      // Initialize OneSignal with App ID
      OneSignal.initialize(appId);

      // Request push notification permissions (Android 13+ & iOS)
      await OneSignal.Notifications.requestPermission(true);

      // Register notification listeners
      _setupListeners();

      _isInitialized = true;
      debugPrint('[OneSignal] Berhasil diinisialisasi dengan App ID: $appId');
    } catch (e) {
      debugPrint('[OneSignal] Gagal inisialisasi: $e');
    }
  }

  /// Setup notification event listeners
  static void _setupListeners() {
    // When notification is received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint(
        '[OneSignal] Notifikasi diterima (Foreground): ${event.notification.title} - ${event.notification.body}',
      );
    });

    // When user taps/clicks a notification
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('[OneSignal] Notifikasi diklik: ${event.notification.title}');
      final additionalData = event.notification.additionalData;
      if (additionalData != null) {
        debugPrint('[OneSignal] Data payload: $additionalData');
      }
    });

    // Permission change observer
    OneSignal.Notifications.addPermissionObserver((state) {
      debugPrint('[OneSignal] Status izin notifikasi berubah: $state');
    });
  }

  /// Login user to OneSignal (set External User ID)
  static Future<void> loginUser(String userId) async {
    if (!_isInitialized && !AppConstants.isOneSignalConfigured) return;
    try {
      await OneSignal.login(userId);
      debugPrint('[OneSignal] User login: $userId');
    } catch (e) {
      debugPrint('[OneSignal] Error login user: $e');
    }
  }

  /// Logout user from OneSignal
  static Future<void> logoutUser() async {
    if (!_isInitialized && !AppConstants.isOneSignalConfigured) return;
    try {
      await OneSignal.logout();
      debugPrint('[OneSignal] User logout');
    } catch (e) {
      debugPrint('[OneSignal] Error logout user: $e');
    }
  }

  /// Set user tags for segmentation/targeting
  static Future<void> setTags(Map<String, String> tags) async {
    if (!_isInitialized && !AppConstants.isOneSignalConfigured) return;
    try {
      for (final entry in tags.entries) {
        OneSignal.User.addTagWithKey(entry.key, entry.value);
      }
      debugPrint('[OneSignal] Tags berhasil diset: $tags');
    } catch (e) {
      debugPrint('[OneSignal] Error set tags: $e');
    }
  }

  /// Set user role tag (guru / admin / wali_murid)
  static Future<void> setUserRole(String role) async {
    await setTags({'role': role});
  }

  /// Register current device as a parent of a specific student
  static Future<void> registerParentForStudent({
    required int siswaId,
    String? namaSiswa,
  }) async {
    await setTags({
      'role': 'wali_murid',
      'siswa_id': siswaId.toString(),
      if (namaSiswa != null) 'nama_siswa': namaSiswa,
    });
    debugPrint('[OneSignal] Device terdaftar sebagai wali murid siswa ID: $siswaId');
  }

  // ===========================================================================
  // PUSH NOTIFICATION SENDING (REST API)
  // ===========================================================================

  /// Send attendance notification to parents when student arrives at school
  static Future<bool> sendAbsensiMasukNotification({
    required int siswaId,
    required String namaSiswa,
    required String jamMasuk,
    bool isLate = false,
    int? lateMinutes,
  }) async {
    final statusText = isLate
        ? 'Terlambat ${lateMinutes ?? 0} menit'
        : 'Tepat Waktu';

    final heading = isLate
        ? '⚠️ Presensi Masuk: $namaSiswa'
        : '✅ Presensi Masuk: $namaSiswa';

    final content = isLate
        ? 'Ananda $namaSiswa telah tiba di sekolah pukul $jamMasuk WIB (Status: Terlambat $lateMinutes mnt).'
        : 'Alhamdulillah, Ananda $namaSiswa telah tiba di sekolah pukul $jamMasuk WIB (Status: $statusText).';

    return await sendNotificationToStudentParents(
      siswaId: siswaId,
      heading: heading,
      content: content,
      data: {
        'type': 'absensi',
        'action': 'masuk',
        'siswa_id': siswaId,
        'nama_siswa': namaSiswa,
        'jam': jamMasuk,
        'is_late': isLate,
        'late_minutes': lateMinutes,
      },
    );
  }

  /// Send attendance notification to parents when student checks out (leaves school)
  static Future<bool> sendAbsensiPulangNotification({
    required int siswaId,
    required String namaSiswa,
    required String jamPulang,
  }) async {
    final heading = '👋 Presensi Pulang: $namaSiswa';
    final content =
        'Ananda $namaSiswa telah melakukan absensi pulang pukul $jamPulang WIB. Semoga selamat sampai di rumah!';

    return await sendNotificationToStudentParents(
      siswaId: siswaId,
      heading: heading,
      content: content,
      data: {
        'type': 'absensi',
        'action': 'pulang',
        'siswa_id': siswaId,
        'nama_siswa': namaSiswa,
        'jam': jamPulang,
      },
    );
  }

  /// Send notification to parents when student attendance status is manually updated (Sakit, Izin, Alfa)
  static Future<bool> sendAbsensiStatusUpdateNotification({
    required int siswaId,
    required String namaSiswa,
    required String status,
    required String tanggal,
    String? keterangan,
  }) async {
    final heading = '📋 Update Presensi: $namaSiswa';
    final ketText = keterangan != null && keterangan.isNotEmpty ? ' ($keterangan)' : '';
    final content =
        'Status presensi ananda $namaSiswa untuk tanggal $tanggal telah tercatat sebagai: ${status.toUpperCase()}$ketText.';

    return await sendNotificationToStudentParents(
      siswaId: siswaId,
      heading: heading,
      content: content,
      data: {
        'type': 'absensi_status_update',
        'siswa_id': siswaId,
        'nama_siswa': namaSiswa,
        'status': status,
        'tanggal': tanggal,
      },
    );
  }

  /// Send push notification targeting parents of a specific student (via tag filter)
  static Future<bool> sendNotificationToStudentParents({
    required int siswaId,
    required String heading,
    required String content,
    Map<String, dynamic>? data,
  }) async {
    return await sendPushNotification(
      filters: [
        {
          'field': 'tag',
          'key': 'siswa_id',
          'relation': '=',
          'value': siswaId.toString(),
        },
      ],
      heading: heading,
      content: content,
      data: data,
    );
  }

  /// Core method to send push notification via OneSignal REST API
  static Future<bool> sendPushNotification({
    required List<Map<String, dynamic>> filters,
    required String heading,
    required String content,
    Map<String, dynamic>? data,
  }) async {
    final appId = AppConstants.onesignalAppId;
    final restApiKey = AppConstants.onesignalRestApiKey;

    if (appId.isEmpty) {
      debugPrint('[OneSignal Push] Batal kirim: ONESIGNAL_APP_ID kosong');
      return false;
    }

    if (restApiKey.isEmpty) {
      debugPrint(
        '[OneSignal Push] Batal kirim: ONESIGNAL_REST_API_KEY belum dikonfigurasi di .env. '
        'Isi REST API Key di .env untuk mengaktifkan pengiriman notifikasi dari aplikasi.',
      );
      return false;
    }

    try {
      final url = Uri.parse('https://onesignal.com/api/v1/notifications');
      final payload = {
        'app_id': appId,
        'filters': filters,
        'headings': {
          'en': heading,
          'id': heading,
        },
        'contents': {
          'en': content,
          'id': content,
        },
        if (data != null) 'data': data,
        'android_accent_color': 'FF2F6CB0',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('[OneSignal Push] Notifikasi berhasil dikirim: ${response.body}');
        return true;
      } else {
        debugPrint(
          '[OneSignal Push] Gagal mengirim notifikasi (${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[OneSignal Push] Error saat mengirim notifikasi: $e');
      return false;
    }
  }

  // ===========================================================================
  // SUBSCRIPTION & STATUS GETTERS
  // ===========================================================================

  /// Check if user has opted into push notifications
  static bool get isSubscribed =>
      OneSignal.User.pushSubscription.optedIn ?? false;

  /// Get OneSignal Subscription ID / Player ID
  static String? get subscriptionId => OneSignal.User.pushSubscription.id;

  /// Get push notification token
  static String? get pushToken => OneSignal.User.pushSubscription.token;
}
