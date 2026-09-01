import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../notes_provider.dart';
import 'add_column_sheet.dart';

class KanbanTab extends StatelessWidget {
  final double topPad;
  const KanbanTab({super.key, required this.topPad});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotesProvider>();

    return ListView(
      padding: EdgeInsets.only(top: topPad + 48, bottom: 100),
      children: [
        // Hint text
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.drag_indicator_rounded, size: 13, color: AppColors.sub),
              const SizedBox(width: 5),
              Text(
                'Hold & drag a card to move it between lists',
                style: const TextStyle(fontSize: 11.5, color: AppColors.sub, letterSpacing: 0.1),
              ),
            ],
          ),
        ),

        // Columns
        ...kanbanColumns.asMap().entries.map((entry) {
          final idx = entry.key;
          final col = entry.value;
          return _KanbanColumnSection(col: col, isFirst: idx == 0);
        }),
      ],
    );
  }
}

// ── Column section ─────────────────────────────────────────────────────────────

class _KanbanColumnSection extends StatelessWidget {
  final KanbanColumn col;
  final bool         isFirst;
  const _KanbanColumnSection({required this.col, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final prov    = context.watch<NotesProvider>();
    final noteIds = prov.kanban[col.id] ?? [];

    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        return details.data is KanbanDragData;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is KanbanDragData) {
          prov.moveKanbanCard(
            noteId:    data.noteId,
            fromColId: data.fromColId,
            toColId:   col.id,
            insertAt:  noteIds.length,
          );
        }
      },
      builder: (ctx, candidates, _) {
        final isTarget = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            border: Border(top: isFirst ? BorderSide.none : BorderSide(color: AppColors.border)),
            color:  isTarget ? AppColors.colorDoing.withAlpha(0x0D) : Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(color: col.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      col.label.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.sub, letterSpacing: 0.5),
                    ),
                    const Spacer(),
                    Text(
                      '${noteIds.length}',
                      style: TextStyle(fontSize: 11, color: AppColors.sub.withAlpha(0x80)),
                    ),
                  ],
                ),
              ),

              // Horizontal card row
              SizedBox(
                height: 116,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:         const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount:       noteIds.length + 1,
                  itemBuilder:     (ctx, i) {
                    if (i == noteIds.length) {
                      return _AddCardBtn(colId: col.id, color: col.color);
                    }
                    final noteId = noteIds[i];
                    final note   = prov.notes.firstWhere(
                      (n) => n.id == noteId,
                      orElse: () => Note(id: noteId, title: '?', content: '', date: ''),
                    );
                    return _KanbanCard(
                      note:    note,
                      preview: prov.plainPreview(note.content),
                      colId:   col.id,
                      color:   col.color,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Kanban card ────────────────────────────────────────────────────────────────

class _KanbanCard extends StatelessWidget {
  final Note   note;
  final String preview;
  final String colId;
  final Color  color;
  const _KanbanCard({required this.note, required this.preview, required this.colId, required this.color});

  @override
  Widget build(BuildContext context) {
    final prov     = context.watch<NotesProvider>();
    final isDragged = prov.isDragging && prov.dragKind == 'kanban';
    final dragData  = KanbanDragData(note.id, colId);

    Widget card = Container(
      width:  110,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w500,
                    letterSpacing: -0.2, height: 1.3, color: AppColors.fg,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // Preview
              Text(
                preview,
                style: const TextStyle(fontSize: 11, color: AppColors.sub, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Grip icon
          Positioned(
            top: 0, right: 0,
            child: _GripIcon(),
          ),
        ],
      ),
    );

    return LongPressDraggable<DragData>(
      data:  dragData,
      delay: const Duration(milliseconds: 200),
      feedback: _KanbanDragFeedback(note: note, preview: preview, color: color),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: Container(
          width: 110, height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color:        AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: color),
          ),
        ),
      ),
      onDragStarted:       () => prov.setDragging(true, 'kanban'),
      onDragEnd:           (_) => prov.setDragging(false),
      onDraggableCanceled: (_, __) => prov.setDragging(false),
      child: GestureDetector(
        onTap: () => prov.openNoteEditor(note),
        child: card,
      ),
    );
  }
}

// ── Drag feedback for kanban ───────────────────────────────────────────────────

class _KanbanDragFeedback extends StatelessWidget {
  final Note   note;
  final String preview;
  final Color  color;
  const _KanbanDragFeedback({required this.note, required this.preview, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: -0.05,
        child: Container(
          width: 110, height: 100,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color:        AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: color),
            boxShadow:    const [BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 12))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, letterSpacing: -0.2, color: AppColors.fg), maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Text(preview, style: const TextStyle(fontSize: 11, color: AppColors.sub), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add card button ────────────────────────────────────────────────────────────

class _AddCardBtn extends StatefulWidget {
  final String colId;
  final Color  color;
  const _AddCardBtn({required this.colId, required this.color});
  @override
  State<_AddCardBtn> createState() => _AddCardBtnState();
}

class _AddCardBtnState extends State<_AddCardBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showAddColumnSheet(context, widget.colId),
      child: MouseRegion(
        onEnter:  (_) => setState(() => _hovered = true),
        onExit:   (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 110, height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(
              color: _hovered ? AppColors.fg : AppColors.border,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Text(
              '+ Add',
              style: TextStyle(fontSize: 12, color: _hovered ? AppColors.fg : AppColors.sub),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grip icon ──────────────────────────────────────────────────────────────────

class _GripIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (row) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(2, (col) => Container(
            width: 3, height: 3,
            margin: const EdgeInsets.all(1),
            decoration: const BoxDecoration(color: AppColors.sub, shape: BoxShape.circle),
          )),
        )),
      ),
    );
  }
}
