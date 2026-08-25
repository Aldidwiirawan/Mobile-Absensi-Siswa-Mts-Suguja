import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/ui/bouncing_widget.dart';
import '../../data/models/guru.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/form_login.dart';

/// Comprehensive Teacher Profile screen for viewing and updating personal info,
/// email, password, and profile avatar.
class ProfilGuruScreen extends StatefulWidget {
  const ProfilGuruScreen({super.key});

  @override
  State<ProfilGuruScreen> createState() => _ProfilGuruScreenState();
}

class _ProfilGuruScreenState extends State<ProfilGuruScreen> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _imagePicker = ImagePicker();
  File? _selectedAvatarFile;
  String? _currentAvatarUrl;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Guru? _guruProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authRepository.getCurrentGuruProfile();
      if (profile != null && mounted) {
        setState(() {
          _guruProfile = profile;
          _namaController.text = profile.nama;
          _noHpController.text = profile.noHp ?? '';
          _emailController.text = profile.email ?? '';
          _currentAvatarUrl = profile.displayAvatarUrl;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Gagal memuat profil: $e', isError: true);
      }
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      // Compress avatar image
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/avatar_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 80,
        minWidth: 500,
        minHeight: 500,
      );

      if (compressedFile != null && mounted) {
        setState(() {
          _selectedAvatarFile = File(compressedFile.path);
        });
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      _showSnackbar('Gagal memilih foto: $e', isError: true);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF2563EB)),
                ),
                title: const Text('Ambil Foto dari Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF8B5CF6)),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (_selectedAvatarFile != null || _currentAvatarUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444)),
                  ),
                  title: const Text('Hapus Foto Profil',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedAvatarFile = null;
                      _currentAvatarUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      String? newAvatarUrl = _currentAvatarUrl;

      // 1. Upload new avatar if selected
      if (_selectedAvatarFile != null) {
        newAvatarUrl = await _authRepository.uploadAvatar(_selectedAvatarFile!);
      }

      // 2. Update Personal Profile (Nama, No HP, Foto URL)
      await _authRepository.updateProfile(
        nama: _namaController.text.trim(),
        noHp: _noHpController.text.trim().isNotEmpty
            ? _noHpController.text.trim()
            : null,
        fotoUrl: newAvatarUrl,
      );

      // 3. Update Email if changed
      final currentEmail = _guruProfile?.email ?? '';
      final newEmail = _emailController.text.trim();
      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        await _authRepository.updateEmail(newEmail);
      }

      // 4. Update Password if entered
      final newPassword = _passwordController.text;
      if (newPassword.isNotEmpty) {
        await _authRepository.updatePassword(newPassword);
        _passwordController.clear();
        _confirmPasswordController.clear();
      }

      HapticFeedback.lightImpact();
      _showSnackbar('Profil Anda berhasil diperbarui!');
      await _loadProfile();
    } catch (e) {
      _showSnackbar('Gagal menyimpan profil: $e', isError: true);
      HapticFeedback.vibrate();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Keluar Akun Guru',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun guru di perangkat ini?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await _authRepository.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profil & Akun Guru',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Segarkan',
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar Header Section
                    _buildAvatarHeader(),
                    const SizedBox(height: 24),

                    // Data Pribadi Card
                    _buildDataPribadiCard(),
                    const SizedBox(height: 18),

                    // Daftar Kelas yang Diampu
                    _buildKelasDiampuCard(),
                    const SizedBox(height: 18),

                    // Akun & Keamanan (Email & Password)
                    _buildKeamananCard(),
                    const SizedBox(height: 26),

                    // Save Button
                    _buildSaveButton(),
                    const SizedBox(height: 16),

                    // Logout Tile Button
                    _buildLogoutButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarHeader() {
    ImageProvider? imageProvider;
    if (_selectedAvatarFile != null) {
      imageProvider = FileImage(_selectedAvatarFile!);
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentAvatarUrl!);
    }

    final nama = _guruProfile?.nama ?? 'Bapak/Ibu Guru';
    final nip = _guruProfile?.nip.isNotEmpty == true
        ? 'NIP. ${_guruProfile!.nip}'
        : 'NIP belum diatur';
    final roleName = _guruProfile?.role.displayName ?? 'Guru Pengampu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFEFF6FF),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: Color(0xFF2563EB),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showAvatarOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nama,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            nip,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded,
                    size: 13, color: Color(0xFF67E8F9)),
                const SizedBox(width: 6),
                Text(
                  roleName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDataPribadiCard() {
    return _buildSectionCard(
      title: 'Data Pribadi',
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF2563EB),
      children: [
        // Nama Lengkap Field
        TextFormField(
          controller: _namaController,
          decoration: _inputDecoration(
            labelText: 'Nama Lengkap *',
            hintText: 'Nama lengkap beserta gelar',
            prefixIcon: Icons.badge_outlined,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nama lengkap tidak boleh kosong';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Nomor WhatsApp / HP
        TextFormField(
          controller: _noHpController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            labelText: 'Nomor WhatsApp / HP',
            hintText: 'Contoh: 081234567890',
            prefixIcon: Icons.phone_android_rounded,
          ),
        ),
        const SizedBox(height: 14),

        // NIP (Read-Only)
        TextFormField(
          initialValue: _guruProfile?.nip ?? '-',
          readOnly: true,
          decoration: _inputDecoration(
            labelText: 'Nomor Induk Pegawai (NIP)',
            hintText: 'NIP terdaftar',
            prefixIcon: Icons.fingerprint_rounded,
            suffixIcon: const Tooltip(
              message: 'NIP dikelola oleh Administrator',
              child: Icon(Icons.lock_outline_rounded,
                  size: 18, color: Color(0xFF94A3B8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKelasDiampuCard() {
    final classes = _guruProfile?.allClassNames ?? [];

    return _buildSectionCard(
      title: 'Kelas yang Diampu',
      icon: Icons.school_outlined,
      iconColor: const Color(0xFF10B981),
      children: [
        if (classes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada kelas yang ditugaskan.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: classes.map((k) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded,
                        size: 15, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      k,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildKeamananCard() {
    return _buildSectionCard(
      title: 'Akun & Keamanan',
      icon: Icons.security_rounded,
      iconColor: const Color(0xFF8B5CF6),
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            labelText: 'Email Akun *',
            hintText: 'email@guru.sch.id',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Email tidak boleh kosong';
            }
            if (!val.contains('@') || !val.contains('.')) {
              return 'Format email tidak valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Password Baru
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            labelText: 'Kata Sandi Baru (Opsional)',
            hintText: 'Biarkan kosong jika tidak ingin diubah',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (val) {
            if (val != null && val.isNotEmpty && val.length < 6) {
              return 'Kata sandi minimal 6 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Konfirmasi Password Baru
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: _inputDecoration(
            labelText: 'Konfirmasi Kata Sandi Baru',
            hintText: 'Ulangi kata sandi baru',
            prefixIcon: Icons.lock_reset_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          validator: (val) {
            if (_passwordController.text.isNotEmpty) {
              if (val == null || val.isEmpty) {
                return 'Konfirmasi kata sandi wajib diisi';
              }
              if (val != _passwordController.text) {
                return 'Kata sandi tidak cocok';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
    );
  }

  Widget _buildSaveButton() {
    return BouncingWidget(
      onTap: _isSaving ? () {} : _handleSave,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return BouncingWidget(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 8),
              Text(
                'Keluar dari Akun Guru',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
