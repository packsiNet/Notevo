import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../notes_provider.dart';

Future<void> showStatusSheet(BuildContext context, Note note) {
  return showModalBottomSheet(
    context:         context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:         (_) => _StatusSheet(note: note),
  );
}

class _StatusSheet extends StatelessWidget {
  final Note note;
  const _StatusSheet({required this.note});

  @override
  Widget build(BuildContext context) {
    final prov      = context.watch<NotesProvider>();
    final currentCol = prov.kanbanColOf(note.id);

    return Container(
      decoration: const BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Subtitle
          Text(
            currentCol != null ? 'Status' : 'Add to board',
            style: const TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 4),

          // Note title
          Text(
            note.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: AppColors.fg),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),

          // Column options
          ...kanbanColumns.map((col) {
            final active = currentCol == col.id;
            return GestureDetector(
              onTap: () {
                prov.moveToKanban(note.id, col.id);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color:        active ? Colors.transparent : AppColors.pillBg,
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(
                    color: active ? col.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape:     BoxShape.circle,
                        color:     col.color,
                        boxShadow: active ? [BoxShadow(color: col.color.withAlpha(0x33), blurRadius: 0, spreadRadius: 3)] : [],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        col.label,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.fg),
                      ),
                    ),
                    if (active)
                      Icon(Icons.check_rounded, size: 16, color: col.color)
                    else
                      Text(
                        '${prov.kanban[col.id]?.length ?? 0}',
                        style: const TextStyle(fontSize: 12, color: AppColors.sub),
                      ),
                  ],
                ),
              ),
            );
          }),

          // Remove from board
          if (currentCol != null)
            GestureDetector(
              onTap: () {
                prov.removeFromKanban(note.id);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                child: const Center(
                  child: Text(
                    'Remove from board',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.sub),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
