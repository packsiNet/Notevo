import 'package:flutter/material.dart';
import 'app_theme.dart';

// ── Note ──────────────────────────────────────────────────────────────────────

class Note {
  int    id;
  String title;
  String content;
  String date;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  Note copyWith({String? title, String? content, String? date}) => Note(
    id:      id,
    title:   title   ?? this.title,
    content: content ?? this.content,
    date:    date    ?? this.date,
  );
}

// ── Kanban ────────────────────────────────────────────────────────────────────

class KanbanColumn {
  final String id;
  final String label;
  final Color  color;
  const KanbanColumn({required this.id, required this.label, required this.color});
}

const kanbanColumns = <KanbanColumn>[
  KanbanColumn(id: 'todo',  label: 'To Do',       color: AppColors.colorTodo),
  KanbanColumn(id: 'doing', label: 'In Progress',  color: AppColors.colorDoing),
  KanbanColumn(id: 'done',  label: 'Done',         color: AppColors.colorDone),
];

// ── App views ─────────────────────────────────────────────────────────────────

enum AppView { notes, kanban, shared, archive, trash }

// ── Drag data (sealed union) ──────────────────────────────────────────────────

sealed class DragData {
  const DragData();
}

class NoteDragData extends DragData {
  final int noteId;
  const NoteDragData(this.noteId);
}

class KanbanDragData extends DragData {
  final int    noteId;
  final String fromColId;
  const KanbanDragData(this.noteId, this.fromColId);
}
