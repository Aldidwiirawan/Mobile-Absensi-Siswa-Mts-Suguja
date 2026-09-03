import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/ui/scanner_laser_overlay.dart';

/// QR Code Scanner widget with camera, smooth laser overlay, and clean AppBar
class BarcodeScannerPage extends StatefulWidget {
  final void Function(String) onResult;
  final Color borderColor;
  final Widget? overlayPopup;

  const BarcodeScannerPage({
    super.key,
    required this.onResult,
    required this.borderColor,
    this.overlayPopup,
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isDisposed = false;
  bool _isSleeping = false;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      facing: CameraFacing.front,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.unrestricted,
    );
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isDisposed) return;
    _inactivityTimer = Timer(const Duration(minutes: 2), () {
      if (mounted && !_isDisposed && !_isSleeping) {
        _sleepCamera();
      }
    });
  }

  Future<void> _sleepCamera() async {
    setState(() => _isSleeping = true);
    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _wakeCamera() async {
    setState(() => _isSleeping = false);
    _resetInactivityTimer();
    try {
      await _controller.start();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !mounted) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _inactivityTimer?.cancel();
      unawaited(_controller.stop());
    } else if (state == AppLifecycleState.resumed && !_isSleeping) {
      _resetInactivityTimer();
      unawaited(_controller.start());
    }
  }

  Future<void> _handlePop() async {
    if (_isDisposed) return;
    _inactivityTimer?.cancel();
    try {
      await _controller.stop();
    } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Pemindai Presensi QR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            tooltip: 'Kembali',
            onPressed: _handlePop,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.cameraswitch_rounded),
              tooltip: 'Ganti Kamera',
              onPressed: () => _controller.switchCamera(),
            ),
            IconButton(
              icon: const Icon(Icons.flash_on_rounded),
              tooltip: 'Flash / Senter',
              onPressed: () => _controller.toggleTorch(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            // Camera Scanner
            if (!_isSleeping)
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (_isDisposed || _isSleeping) return;
                  _resetInactivityTimer();
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final result = barcodes.first.rawValue;
                    if (result != null && result.trim().isNotEmpty) {
                      widget.onResult(result.trim());
                    }
                  }
                },
              ),

            // Animated Laser Scanner Overlay
            if (!_isSleeping)
              RepaintBoundary(
                child: AnimatedScannerOverlay(
                  borderColor: widget.borderColor,
                  isScanning: true,
                ),
              ),

            // Inactivity Sleep Screen Overlay
            if (_isSleeping)
              Container(
                color: Colors.black.withValues(alpha: 0.92),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.bedtime_rounded,
                          size: 48,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Kamera Dijeda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Kamera dinonaktifkan otomatis setelah 2 menit tanpa aktivitas untuk menghemat daya baterai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: _wakeCamera,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        icon: const Icon(Icons.videocam_rounded, size: 20),
                        label: const Text(
                          'Aktifkan Kamera Kembali',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Instruction Hint Badge
            if (!_isSleeping)
              Positioned(
                bottom: widget.overlayPopup != null ? 140 : 50,
                left: 24,
                right: 24,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: widget.overlayPopup != null ? 0.3 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Arahkan QR Code siswa ke dalam kotak',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Dynamic Result Popup if available
            if (widget.overlayPopup != null) widget.overlayPopup!,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.stop());
    _controller.dispose();
    super.dispose();
  }
}
