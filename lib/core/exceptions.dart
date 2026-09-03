/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Exception thrown by repository operations
class RepositoryException extends AppException {
  RepositoryException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown during form validation
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    this.fieldErrors,
    super.code,
    super.stackTrace,
  });
}

/// Exception thrown for network-related errors
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for authentication-related errors
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for not found errors (404)
class NotFoundException extends AppException {
  NotFoundException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when access is denied (403)
class AccessDeniedException extends AppException {
  AccessDeniedException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for server errors (500+)
class ServerException extends AppException {
  ServerException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for timeout errors
class TimeoutException extends AppException {
  TimeoutException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when QR scan fails
class ScanException extends AppException {
  ScanException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when student is not found
class StudentNotFoundException extends AppException {
  final String? nis;

  StudentNotFoundException({
    required super.message,
    this.nis,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for attendance-related errors
class AttendanceException extends AppException {
  AttendanceException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Helper to convert technical exceptions, Supabase/Network errors, or database faults into clean, concise Indonesian messages
class ErrorFormatter {
  static String format(dynamic error) {
    if (error == null) return 'Terjadi kesalahan tidak dikenal.';

    final raw = error.toString();

    // 1. Auth & Credentials
    if (raw.contains('Invalid login credentials') ||
        raw.contains('invalid_grant') ||
        raw.contains('Invalid email or password')) {
      return 'Email atau kata sandi salah. Silakan periksa kembali.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Silakan cek kotak masuk email Anda.';
    }
    if (raw.contains('User already registered') ||
        raw.contains('user_already_exists')) {
      return 'Email sudah terdaftar. Silakan masuk menggunakan akun tersebut.';
    }
    if (raw.contains('Password should be at least')) {
      return 'Kata sandi minimal harus 6 karakter.';
    }
    if (raw.toLowerCase().contains('nis') &&
        (raw.contains('tidak ditemukan') ||
         raw.contains('tidak terdaftar') ||
         raw.contains('Gagal memverifikasi') ||
         raw.contains('ValidationException') ||
         raw.contains('StudentNotFoundException'))) {
      return 'NIS siswa tidak terdaftar di sistem sekolah.';
    }
    if (raw.contains('NIS tidak boleh kosong') || raw.contains('NIS siswa wajib diisi')) {
      return 'Mohon masukkan NIS siswa terlebih dahulu.';
    }

    // 2. Network & Connectivity
    if (raw.contains('SocketException') ||
        raw.contains('ClientException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network is unreachable') ||
        raw.contains('Connection refused') ||
        raw.contains('Connection timed out') ||
        raw.contains('NetworkException')) {
      return 'Koneksi internet bermasalah. Periksa jaringan Anda dan coba lagi.';
    }
    if (raw.contains('TimeoutException') || raw.contains('timed out')) {
      return 'Waktu koneksi habis. Silakan coba beberapa saat lagi.';
    }

    // 3. Database / Postgrest / Permissions
    if (raw.contains('JWT expired') || raw.contains('session expired')) {
      return 'Sesi login telah berakhir. Silakan masuk kembali.';
    }
    if (raw.contains('permission denied') ||
        raw.contains('row-level security') ||
        raw.contains('42501')) {
      return 'Akses ditolak. Anda tidak memiliki izin untuk tindakan ini.';
    }
    if (raw.contains('duplicate key value') || raw.contains('unique constraint')) {
      return 'Data ini sudah pernah dicatat sebelumnya.';
    }
    if (raw.contains('column') || raw.contains('does not exist') || raw.contains('PGRST') || raw.contains('PostgrestException')) {
      return 'NIS siswa tidak terdaftar di sistem sekolah.';
    }

    // 4. Custom App Exceptions
    if (error is AppException) {
      final msg = error.message;
      if (msg.contains('PostgrestException') ||
          msg.contains('SocketException') ||
          msg.contains('Invalid login credentials') ||
          msg.contains('column') ||
          msg.contains('Gagal memverifikasi')) {
        return format(msg);
      }
      return msg;
    }

    // 5. Clean any general prefixes (Exception:, PostgrestException:, etc.)
    var result = raw
        .replaceAll(RegExp(r'^(Exception|AppException|RepositoryException|AuthException|PostgrestException|ValidationException):\s*'), '')
        .replaceAll(RegExp(r'PostgrestException\(.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'AuthException\(.*?\)', caseSensitive: false), '')
        .trim();

    if (result.isEmpty) {
      return 'NIS siswa tidak terdaftar di sistem sekolah.';
    }

    // If message is still overly long/technical (e.g. contains JSON or stack code), provide friendly fallback
    if (result.length > 80 && (result.contains('{') || result.contains('Error:') || result.contains('Postgrest'))) {
      return 'NIS siswa tidak terdaftar di sistem sekolah.';
    }

    return result;
  }
}
