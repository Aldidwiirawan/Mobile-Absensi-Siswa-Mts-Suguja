import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive segmented status pill selector with animated active indicator
class StatusSelectorPills extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const StatusSelectorPills({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const _statusList = [
    (
      key: 'hadir',
      label: 'Hadir',
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF10B981),
    ),
    (
      key: 'terlambat',
      label: 'Telat',
      icon: Icons.schedule_rounded,
      color: Color(0xFFF59E0B),
    ),
    (
      key: 'sakit',
      label: 'Sakit',
      icon: Icons.healing_rounded,
      color: Color(0xFF3B82F6),
    ),
    (
      key: 'izin',
      label: 'Izin',
      icon: Icons.assignment_outlined,
      color: Color(0xFF8B5CF6),
    ),
    (
      key: 'alfa',
      label: 'Alfa',
      icon: Icons.cancel_outlined,
      color: Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Status Kehadiran',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _statusList.map((item) {
            final isSelected = selectedStatus.toLowerCase() == item.key;
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onStatusChanged(item.key);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? item.color
                        : Colors.grey.shade300,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 18,
                      color: isSelected ? item.color : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? item.color : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
