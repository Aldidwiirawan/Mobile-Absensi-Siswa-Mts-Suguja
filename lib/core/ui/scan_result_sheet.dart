import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ScanFeedbackType { success, late, pulang, error, warning }

/// Animated celebration card popup shown directly on top of the QR scanner
class ScanResultPopup extends StatelessWidget {
  final String namaSiswa;
  final String? nis;
  final String statusTitle;
  final String statusSubtitle;
  final String time;
  final ScanFeedbackType type;
  final VoidCallback onDismiss;

  const ScanResultPopup({
    super.key,
    required this.namaSiswa,
    this.nis,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.time,
    required this.type,
    required this.onDismiss,
  });

  Color get _primaryColor {
    switch (type) {
      case ScanFeedbackType.success:
        return const Color(0xFF10B981); // Emerald Green
      case ScanFeedbackType.late:
        return const Color(0xFFF59E0B); // Amber / Orange
      case ScanFeedbackType.pulang:
        return const Color(0xFF06B6D4); // Cyan Blue
      case ScanFeedbackType.warning:
        return const Color(0xFFF97316); // Bright Orange
      case ScanFeedbackType.error:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get _icon {
    switch (type) {
      case ScanFeedbackType.success:
        return Icons.verified_rounded;
      case ScanFeedbackType.late:
        return Icons.timer_outlined;
      case ScanFeedbackType.pulang:
        return Icons.waving_hand_rounded;
      case ScanFeedbackType.warning:
        return Icons.warning_amber_rounded;
      case ScanFeedbackType.error:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDismiss,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate dark
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _primaryColor.withValues(alpha: 0.8),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated Icon Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _icon,
                    size: 32,
                    color: _primaryColor,
                  ),
                )
                    .animate()
                    .scale(
                      duration: 350.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1, 1),
                    )
                    .shimmer(duration: 800.ms, color: Colors.white24),

                const SizedBox(width: 16),

                // Student Details & Status Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              statusTitle,
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              time,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Student Name
                      Text(
                        namaSiswa,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Subtitle
                      Text(
                        statusSubtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Close icon button
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  onPressed: onDismiss,
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .slideY(
            begin: 0.4,
            end: 0,
            duration: 350.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 250.ms),
    );
  }
}
