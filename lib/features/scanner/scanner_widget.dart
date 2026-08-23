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

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.front,
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  // Local debounce
  String? _lastScanned;
  DateTime _lastScanTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
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
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final result = barcodes.first.rawValue;
                final now = DateTime.now();

                // Local debounce
                if (result != null &&
                    (result != _lastScanned ||
                        now.difference(_lastScanTime).inMilliseconds > 1500)) {
                  _lastScanned = result;
                  _lastScanTime = now;
                  widget.onResult(result);
                }
              }
            },
          ),

          // Animated Laser Scanner Overlay
          RepaintBoundary(
            child: AnimatedScannerOverlay(
              borderColor: widget.borderColor,
              isScanning: true,
            ),
          ),

          // Instruction Hint Badge
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
