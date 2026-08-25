import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../../core/ui/bouncing_widget.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/wali_storage_service.dart';
import '../wali/wali_dashboard_screen.dart';
import 'auth_wrapper.dart';

enum LoginMode { guru, wali }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _guruFormKey = GlobalKey<FormState>();
  final _waliFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nisController = TextEditingController();

  final _authRepository = AuthRepository();
  final _waliRepository = WaliRepository();

  LoginMode _selectedMode = LoginMode.guru;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nisController.dispose();
    super.dispose();
  }

  Future<void> _handleGuruLogin() async {
    if (!_guruFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('--- [LOGIN GURU] Email: ${_emailController.text.trim()} ---');
      await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login credentials')) {
        msg = 'Email atau password salah. Pastikan akun guru sudah terdaftar.';
      } else if (msg.contains('Email not confirmed')) {
        msg = 'Email belum dikonfirmasi di Supabase.';
      }
      _showErrorSnackbar(msg);
    } catch (e) {
      _showErrorSnackbar('Gagal login: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWaliLogin() async {
    if (!_waliFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nis = _nisController.text.trim();

      debugPrint('--- [LOGIN WALI] NIS: $nis ---');
      final child = await _waliRepository.loginWithNis(
        nis: nis,
      );

      // Save child to local storage and sync OneSignal
      await waliStorageService.saveChild(child, makeActive: true);

      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WaliDashboardScreen()),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _showErrorSnackbar(msg);
      HapticFeedback.vibrate();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(),
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: _buildMainForm(),
                    ),
                    const Spacer(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 55),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E3A8A), // Deep Navy
            Color(0xFF2563EB), // Vibrant Royal Blue
            Color(0xFF3B82F6), // Sky Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          // Logo / Icon with glowing ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/logoMts.png',
                  width: 66,
                  height: 66,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school_rounded,
                    size: 44,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .shimmer(delay: 700.ms, duration: 1200.ms, color: Colors.white38),

          const SizedBox(height: 14),

          // App / School Title
          Text(
            AppConstants.schoolName,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 6),

          // Subtitle Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Sistem Presensi Digital Siswa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 350.ms, duration: 500.ms)
              .scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    );
  }

  Widget _buildMainForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Selector Tabs (Guru / Admin vs Wali Murid)
              _buildModeSelector(),
              const SizedBox(height: 24),

              // Animated Form Switcher
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _selectedMode == LoginMode.guru
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _buildGuruForm(),
                secondChild: _buildWaliForm(),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Tab Guru
          Expanded(
            child: BouncingWidget(
              onTap: () {
                if (_selectedMode != LoginMode.guru) {
                  setState(() => _selectedMode = LoginMode.guru);
                  HapticFeedback.selectionClick();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedMode == LoginMode.guru
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedMode == LoginMode.guru
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: 16,
                      color: _selectedMode == LoginMode.guru
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Guru / Admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedMode == LoginMode.guru
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Wali Murid
          Expanded(
            child: BouncingWidget(
              onTap: () {
                if (_selectedMode != LoginMode.wali) {
                  setState(() => _selectedMode = LoginMode.wali);
                  HapticFeedback.selectionClick();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedMode == LoginMode.wali
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedMode == LoginMode.wali
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.family_restroom_rounded,
                      size: 16,
                      color: _selectedMode == LoginMode.wali
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Wali Murid',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedMode == LoginMode.wali
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuruForm() {
    return Form(
      key: _guruFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portal Guru & Petugas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Masukkan email dan password akun terdaftar',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Email Akun',
              hintText: 'nama@sekolah.sch.id',
              prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF2563EB)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!value.contains('@')) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleGuruLogin(),
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Kata Sandi',
              hintText: 'Masukkan password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              if (value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          BouncingWidget(
            onTap: _isLoading ? null : _handleGuruLogin,
            child: _buildSubmitButton(label: 'MASUK SEBAGAI GURU'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaliForm() {
    return Form(
      key: _waliFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portal Wali Murid',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pantau presensi kehadiran ananda secara langsung',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // NIS Field
          TextFormField(
            controller: _nisController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleWaliLogin(),
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Nomor Induk Siswa (NIS)',
              hintText: 'Contoh: 12345',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'NIS siswa wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          BouncingWidget(
            onTap: _isLoading ? null : _handleWaliLogin,
            child: _buildSubmitButton(label: 'MASUK SEBAGAI WALI MURID'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({required String label}) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Center(
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                '© ${DateTime.now().year} ${AppConstants.schoolName}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
