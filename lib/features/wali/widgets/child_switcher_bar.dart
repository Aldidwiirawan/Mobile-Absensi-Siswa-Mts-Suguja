import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/ui/bouncing_widget.dart';
import '../../../data/models/wali_murid_models.dart';

/// Interactive bar allowing parents to switch between children profiles or add a new child
class ChildSwitcherBar extends StatelessWidget {
  final List<ChildProfile> children;
  final ChildProfile? activeChild;
  final ValueChanged<ChildProfile> onChildSelected;
  final VoidCallback onAddChild;
  final ValueChanged<ChildProfile>? onRemoveChild;

  const ChildSwitcherBar({
    super.key,
    required this.children,
    required this.activeChild,
    required this.onChildSelected,
    required this.onAddChild,
    this.onRemoveChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Profil Ananda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                if (children.length > 1)
                  Text(
                    '${children.length} Anak Terhubung',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal scrollable avatar pills
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: children.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                // Last item is "+ Tambah Anak" button
                if (index == children.length) {
                  return _buildAddChildButton(context);
                }

                final child = children[index];
                final isActive = activeChild?.id == child.id;

                return _buildChildCard(context, child, isActive, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(
    BuildContext context,
    ChildProfile child,
    bool isActive,
    int index,
  ) {
    return BouncingWidget(
      onTap: () => onChildSelected(child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF1D4ED8)
                : const Color(0xFFE2E8F0),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Student Avatar Initials
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isActive
                      ? [const Color(0xFF60A5FA), const Color(0xFF1D4ED8)]
                      : [const Color(0xFFE0E7FF), const Color(0xFFC7D2FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  child.initials,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF3730A3),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name & Class
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    child.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    child.namaKelas,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            if (isActive) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, delay: (index * 60).ms).slideX(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildAddChildButton(BuildContext context) {
    return BouncingWidget(
      onTap: onAddChild,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFEEF2F6),
              child: Icon(
                Icons.add_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Tambah\nAnak',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
