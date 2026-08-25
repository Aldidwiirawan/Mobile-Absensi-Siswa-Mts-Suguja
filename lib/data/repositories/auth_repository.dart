import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../models/models.dart';
import '../services/onesignal_service.dart';
import '../services/supabase_service.dart';

/// Repository for teacher (guru) and authentication operations
class AuthRepository {
  final supabase.SupabaseClient _client = supabaseService.client;

  /// Sign in with email and password
  Future<supabase.AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        await OneSignalService.loginUser(response.user!.id);
      }
      return response;
    } on supabase.AuthException catch (e) {
      throw AuthException(
        message: e.message,
        originalException: e,
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await OneSignalService.logoutUser();
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      debugPrint('Sign out error: ${e.message}');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Get current user's guru profile
  Future<Guru?> getCurrentGuruProfile() async {
    final userId = supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(DbTables.guru)
          .select()
          .eq(GuruColumns.id, userId)
          .maybeSingle();

      if (response == null) return null;
      return Guru.fromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal mengambil profil guru: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Get user role for routing
  Future<UserRole?> getCurrentUserRole() async {
    final userId = supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(DbTables.guru)
          .select(GuruColumns.role)
          .eq(GuruColumns.id, userId)
          .maybeSingle();

      if (response == null) return null;
      return UserRole.fromValue(response[GuruColumns.role] as String?);
    } on supabase.PostgrestException catch (e) {
      debugPrint('Error getting user role: ${e.message}');
      return null;
    }
  }

  /// Get dashboard summary for teacher
  Future<List<ClassSummary>> getDashboardSummary() async {
    final userId = supabaseService.currentUserId;
    if (userId == null) {
      throw AuthException(message: 'User tidak terautentikasi');
    }

    try {
      final response = await _client.rpc(
        RpcFunctions.getGuruDashboardSummary,
        params: {'p_guru_id': userId},
      );

      return (response as List)
          .map((item) => ClassSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal mengambil data dashboard: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Check if current session is valid
  bool get hasValidSession => supabaseService.isAuthenticated;

  /// Get current user ID
  String? get currentUserId => supabaseService.currentUserId;

  /// Update teacher personal info (nama, no_hp, foto_url)
  Future<void> updateProfile({
    required String nama,
    String? noHp,
    String? fotoUrl,
  }) async {
    final userId = supabaseService.currentUserId;
    if (userId == null) {
      throw AuthException(message: 'User tidak terautentikasi');
    }

    try {
      // Attempt 1: Try with all fields including foto_url & avatar_url
      final fullData = <String, dynamic>{
        'nama': nama.trim(),
        if (noHp != null && noHp.isNotEmpty) 'no_hp': noHp.trim(),
        if (fotoUrl != null && fotoUrl.isNotEmpty) ...{
          'foto_url': fotoUrl,
          'avatar_url': fotoUrl,
        },
      };

      try {
        await _client
            .from(DbTables.guru)
            .update(fullData)
            .eq(GuruColumns.id, userId);
        return;
      } catch (e) {
        debugPrint('[AuthRepo] Attempt 1 with foto_url & avatar_url failed ($e), trying avatar_url only...');
      }

      // Attempt 2: Try avatar_url only
      if (fotoUrl != null && fotoUrl.isNotEmpty) {
        final avatarOnlyData = <String, dynamic>{
          'nama': nama.trim(),
          if (noHp != null && noHp.isNotEmpty) 'no_hp': noHp.trim(),
          'avatar_url': fotoUrl,
        };
        try {
          await _client
              .from(DbTables.guru)
              .update(avatarOnlyData)
              .eq(GuruColumns.id, userId);
          return;
        } catch (e) {
          debugPrint('[AuthRepo] Attempt 2 with avatar_url failed ($e), trying foto_url only...');
        }

        // Attempt 3: Try foto_url only
        final fotoOnlyData = <String, dynamic>{
          'nama': nama.trim(),
          if (noHp != null && noHp.isNotEmpty) 'no_hp': noHp.trim(),
          'foto_url': fotoUrl,
        };
        try {
          await _client
              .from(DbTables.guru)
              .update(fotoOnlyData)
              .eq(GuruColumns.id, userId);
          return;
        } catch (e) {
          debugPrint('[AuthRepo] Attempt 3 with foto_url failed ($e), trying without foto...');
        }
      }

      // Attempt 4: Update nama & no_hp without photo columns
      final nameAndPhone = <String, dynamic>{
        'nama': nama.trim(),
        if (noHp != null && noHp.isNotEmpty) 'no_hp': noHp.trim(),
      };
      try {
        await _client
            .from(DbTables.guru)
            .update(nameAndPhone)
            .eq(GuruColumns.id, userId);
        return;
      } catch (e) {
        debugPrint('[AuthRepo] Attempt 4 with no_hp failed ($e), trying nama only...');
      }

      // Attempt 5: Just nama
      await _client
          .from(DbTables.guru)
          .update({'nama': nama.trim()})
          .eq(GuruColumns.id, userId);
    } on supabase.PostgrestException catch (e) {
      throw RepositoryException(
        message: 'Gagal memperbarui profil: ${e.message}',
        originalException: e,
      );
    } catch (e) {
      throw RepositoryException(
        message: 'Gagal memperbarui profil: $e',
      );
    }
  }

  /// Upload avatar image to Supabase Storage
  Future<String?> uploadAvatar(dynamic file) async {
    final userId = supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final ext = file.path.split('.').last;
      final fileName =
          'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = 'avatars/$fileName';

      // Try 'avatars' bucket first, fallback to 'surat_keterangan'
      try {
        await _client.storage.from('avatars').upload(
              filePath,
              file,
              fileOptions: const supabase.FileOptions(upsert: true),
            );
        return _client.storage.from('avatars').getPublicUrl(filePath);
      } catch (e) {
        debugPrint(
            '[AuthRepo] Avatars bucket error, falling back to surat_keterangan: $e');
        await _client.storage.from(StorageBuckets.suratKeterangan).upload(
              filePath,
              file,
              fileOptions: const supabase.FileOptions(upsert: true),
            );
        return _client.storage
            .from(StorageBuckets.suratKeterangan)
            .getPublicUrl(filePath);
      }
    } catch (e) {
      debugPrint('[AuthRepo] Error uploadAvatar: $e');
      throw RepositoryException(message: 'Gagal mengunggah foto profil: $e');
    }
  }

  /// Update teacher email in Supabase Auth and database table
  Future<void> updateEmail(String newEmail) async {
    final userId = supabaseService.currentUserId;
    if (userId == null) {
      throw AuthException(message: 'User tidak terautentikasi');
    }

    try {
      final attrs = supabase.UserAttributes(email: newEmail.trim());
      await _client.auth.updateUser(attrs);

      try {
        await _client
            .from(DbTables.guru)
            .update({
              GuruColumns.email: newEmail.trim(),
              GuruColumns.updatedAt: DateTime.now().toIso8601String(),
            })
            .eq(GuruColumns.id, userId);
      } catch (e) {
        debugPrint(
            '[AuthRepo] Notice: could not update email column in guru table: $e');
      }
    } on supabase.AuthException catch (e) {
      throw AuthException(
        message: 'Gagal memperbarui email: ${e.message}',
        originalException: e,
      );
    }
  }

  /// Update teacher password in Supabase Auth
  Future<void> updatePassword(String newPassword) async {
    try {
      final attrs = supabase.UserAttributes(password: newPassword);
      await _client.auth.updateUser(attrs);
    } on supabase.AuthException catch (e) {
      throw AuthException(
        message: 'Gagal mengubah password: ${e.message}',
        originalException: e,
      );
    }
  }
}
