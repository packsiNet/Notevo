import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../notes_provider.dart';
import 'status_sheet.dart';

class NotesTab extends StatelessWidget {
  final ScrollController scrollController;
  final double           topPad;
  const NotesTab({super.key, required this.scrollController, required this.topPad});

  @override
  Widget build(BuildContext context) {
    final prov  = context.watch<NotesProvider>();
    final notes = prov.notes;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.pillBg, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.notes_rounded, color: AppColors.sub, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('No notes yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.fg)),
            const SizedBox(height: 8),
            const Text('Tap + to create your first note', style: TextStyle(fontSize: 13, color: AppColors.sub)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller:  scrollController,
      padding:     EdgeInsets.fromLTRB(12, topPad + 52, 12, 100),
      itemCount:   notes.length,
      itemBuilder: (ctx, i) => _NoteRow(note: notes[i], index: i),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final Note   note;
  final int    index;
  const _NoteRow({required this.note, required this.index});

  @override
  Widget build(BuildContext context) {
    final prov    = context.watch<NotesProvider>();
    final colId   = prov.kanbanColOf(note.id);
    final col     = colId != null ? kanbanColumns.firstWhere((c) => c.id == colId) : null;
    final preview = prov.plainPreview(note.content);

    final dragData = NoteDragData(note.id);

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow:    const [
          BoxShadow(color: Color(0x47000000), blurRadius: 12, offset: Offset(0, 2)),
          BoxShadow(color: AppColors.border, blurRadius: 0, spreadRadius: 1),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                gradient: col != null
                  ? LinearGradient(
                      begin:  Alignment.topCenter,
                      end:    Alignment.bottomCenter,
                      colors: [col.color, col.color.withAlpha(0x99)],
                    )
                  : null,
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(
                              fontSize:      14.5,
                              fontWeight:    FontWeight.w600,
                              letterSpacing: -0.3,
                              color:         AppColors.fg,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          note.date,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.sub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.isEmpty ? 'No additional text' : preview,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.45),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Status button — board icon + colored dot badge
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Center(
                child: GestureDetector(
                  onTap: () => showStatusSheet(context, note),
                  child: SizedBox(
                    width: 34, height: 34,
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.dashboard_customize_outlined,
                            size:  15,
                            color: col != null ? AppColors.fg : AppColors.sub,
                          ),
                        ),
                        if (col != null)
                          Positioned(
                            top: 5, right: 5,
                            child: Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(
                                shape:     BoxShape.circle,
                                color:     col.color,
                                border:    Border.all(color: AppColors.bg, width: 1.5),
                                boxShadow: [BoxShadow(color: col.color.withAlpha(0xAA), blurRadius: 5)],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return LongPressDraggable<DragData>(
      data:  dragData,
      delay: const Duration(milliseconds: 150),
      feedback: _DragFeedback(note: note, preview: preview),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Transform.scale(scale: 0.97, child: card),
      ),
      onDragStarted:  () => prov.setDragging(true, 'note'),
      onDragEnd:      (_) => prov.setDragging(false),
      onDraggableCanceled: (_, __) => prov.setDragging(false),
      child: GestureDetector(
        onTap: () => prov.openNoteEditor(note),
        child: card,
      ),
    );
  }
}

// ── Drag feedback ghost card ───────────────────────────────────────────────────

class _DragFeedback extends StatelessWidget {
  final Note   note;
  final String preview;
  const _DragFeedback({required this.note, required this.preview});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width - 24;
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: -0.05,
        child: Transform.scale(
          scale: 1.04,
          child: Container(
            width:  w,
            padding: const EdgeInsets.fromLTRB(17, 12, 13, 12),
            decoration: BoxDecoration(
              color:        AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow:    const [BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                Text(note.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.fg)),
                const SizedBox(height: 4),
                Text(preview.isEmpty ? 'No additional text' : preview,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
