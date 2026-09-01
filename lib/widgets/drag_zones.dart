import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../notes_provider.dart';

class DragZonesRow extends StatelessWidget {
  final String dragKind; // 'note' | 'kanban'
  const DragZonesRow({super.key, required this.dragKind});

  @override
  Widget build(BuildContext context) {
    final isNote = dragKind == 'note';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Zone(
          key:   const ValueKey('trash'),
          zoneKey: 'trash',
          color: AppColors.colorTrash,
          icon:  Icons.delete_outline_rounded,
          label: isNote ? 'Trash' : 'Remove',
          onDrop: (data) {
            final prov = context.read<NotesProvider>();
            if (data is NoteDragData) {
              prov.trashNote(data.noteId);
            } else if (data is KanbanDragData) {
              prov.removeFromKanban(data.noteId);
            }
            prov.setDragging(false);
          },
        ),
        if (isNote) ...[
          const SizedBox(width: 24),
          _Zone(
            key:   const ValueKey('clone'),
            zoneKey: 'clone',
            color: AppColors.colorClone,
            icon:  Icons.copy_rounded,
            label: 'Duplicate',
            onDrop: (data) {
              final prov = context.read<NotesProvider>();
              if (data is NoteDragData) prov.cloneNote(data.noteId);
              prov.setDragging(false);
            },
          ),
          const SizedBox(width: 24),
          _Zone(
            key:   const ValueKey('archive'),
            zoneKey: 'archive',
            color: AppColors.colorArchive,
            icon:  Icons.inventory_2_outlined,
            label: 'Archive',
            onDrop: (data) {
              final prov = context.read<NotesProvider>();
              if (data is NoteDragData) prov.archiveNote(data.noteId);
              prov.setDragging(false);
            },
          ),
        ],
      ],
    );
  }
}

class _Zone extends StatelessWidget {
  final String   zoneKey;
  final Color    color;
  final IconData icon;
  final String   label;
  final void Function(DragData) onDrop;

  const _Zone({
    super.key,
    required this.zoneKey,
    required this.color,
    required this.icon,
    required this.label,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails:     (d) => onDrop(d.data),
      builder: (ctx, candidates, rejected) {
        final active = candidates.isNotEmpty;
        return AnimatedScale(
          scale:    active ? 1.18 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve:    Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape:     BoxShape.circle,
                  color:     active ? color : AppColors.cardBg,
                  border:    Border.all(color: active ? color : AppColors.border, width: 1.5),
                  boxShadow: active
                    ? [BoxShadow(color: color.withAlpha(0x88), blurRadius: 22, offset: const Offset(0, 8))]
                    : [const BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 5))],
                ),
                child: Icon(icon, color: active ? Colors.white : AppColors.sub, size: 20),
              ),
              const SizedBox(height: 7),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 140),
                style: TextStyle(
                  fontSize:      10.5,
                  fontWeight:    FontWeight.w600,
                  letterSpacing: 0.4,
                  color:         active ? color : AppColors.sub.withAlpha(0xA6),
                ),
                child: Text(label),
              ),
            ],
          ),
        );
      },
    );
  }
}
