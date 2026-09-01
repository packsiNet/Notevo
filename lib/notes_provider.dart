import 'package:flutter/foundation.dart';
import 'models.dart';

class NotesProvider extends ChangeNotifier {

  // ── Data ──────────────────────────────────────────────────────────────────

  List<Note> _notes = [
    Note(id: 1, title: "Meeting notes",
      content: "# Meeting notes\n\nDiscussed Q3 roadmap and deployment strategy for next quarter.\n\n## Action items\n\n- Review backend architecture\n- Schedule follow-up with design team\n- **Deadline:** End of month\n\n## Notes\n\nThe team agreed on a _minimal approach_ for the first release.\n\n---\n\n> Speed is a feature, not a bonus.",
      date: "Today"),
    Note(id: 2, title: "Book ideas",
      content: "# Book ideas\n\nA story about a lighthouse keeper who discovers an old manuscript hidden in the walls.\n\n## Themes\n\n- Isolation\n- Discovery\n- Memory\n\n> \"The sea remembers everything the land forgets.\"\n\n## Checklist\n\n- [x] First draft outline\n- [ ] Character sketches\n- [ ] Setting research",
      date: "Yesterday"),
    Note(id: 3, title: "Grocery list",
      content: "# Grocery list\n\n- [ ] Eggs\n- [ ] Milk\n- [ ] Sourdough bread\n- [ ] Olive oil\n- [ ] Cherry tomatoes\n- [x] Coffee\n- [x] Butter",
      date: "Mon"),
    Note(id: 4, title: "Design thoughts",
      content: "# Design thoughts\n\nMinimal doesn't mean empty. It means **nothing unnecessary** remains.\n\n## Principles\n\n1. Every element earns its place\n2. Whitespace is not wasted space\n3. Speed is a feature\n\n---\n\n_Good design is as little design as possible._",
      date: "Sun"),
    Note(id: 5, title: "Travel plans",
      content: "# Travel plans\n\nIstanbul in **April**.\n\n## Must visit\n\n- Kapalıçarşı\n- Balat\n- Boğaz turu\n- Kadıköy\n\n## Budget\n\n| Item | Cost |\n|------|------|\n| Flight | ~\$400 |\n| Hotel | ~\$80/night |",
      date: "Mar 12"),
  ];

  // kanban: column id → list of note ids (ordered)
  Map<String, List<int>> _kanban = {
    'todo':  [2, 3],
    'doing': [1],
    'done':  [],
  };

  List<Note> _archived = [];
  List<Note> _trash    = [];

  // ── UI state ──────────────────────────────────────────────────────────────

  AppView _view      = AppView.notes;
  Note?   _openNote;
  bool    _isEditing = false;
  bool    _isDragging   = false;
  String  _dragKind     = '';   // 'note' | 'kanban'

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Note>              get notes      => _notes;
  Map<String, List<int>>  get kanban     => _kanban;
  List<Note>              get archived   => _archived;
  List<Note>              get trash      => _trash;
  AppView                 get view       => _view;
  Note?                   get openNote   => _openNote;
  bool                    get isEditing  => _isEditing;
  bool                    get isDragging => _isDragging;
  String                  get dragKind   => _dragKind;

  // ── Navigation ────────────────────────────────────────────────────────────

  void setView(AppView v)       { _view = v;      notifyListeners(); }
  void openNoteEditor(Note n)   { _openNote = n; _isEditing = false; notifyListeners(); }
  void closeNoteEditor()        { _openNote = null; _isEditing = false; notifyListeners(); }
  void setEditing(bool v)       { _isEditing = v;   notifyListeners(); }

  void setDragging(bool v, [String kind = '']) {
    _isDragging = v;
    _dragKind   = kind;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? kanbanColOf(int noteId) {
    for (final e in _kanban.entries) {
      if (e.value.contains(noteId)) return e.key;
    }
    return null;
  }

  String plainPreview(String content) {
    for (final raw in content.split('\n')) {
      var l = raw.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      if (RegExp(r'^([-*_])\1\1+$').hasMatch(l)) continue;
      l = l.replaceFirst(RegExp(r'^>\s?'), '');
      l = l.replaceAll(RegExp(r'^[-*+]\s+\[[ xX]\]\s+'), '');
      l = l.replaceAll(RegExp(r'^[-*+]\s+'), '');
      l = l.replaceAll(RegExp(r'^\d+\.\s+'), '');
      l = l.replaceAll(RegExp(r'\*\*\*([^*]+)\*\*\*'), r'$1');
      l = l.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
      l = l.replaceAll(RegExp(r'_([^_]+)_'), r'$1');
      l = l.replaceAll(RegExp(r'~~([^~]+)~~'), r'$1');
      l = l.replaceAll(r'|', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (l.isNotEmpty) return l;
    }
    return '';
  }

  // ── Note CRUD ─────────────────────────────────────────────────────────────

  void createNote() {
    final n = Note(
      id:      DateTime.now().millisecondsSinceEpoch,
      title:   'Untitled',
      content: '',
      date:    'Now',
    );
    _notes = [n, ..._notes];
    _openNote  = n;
    _isEditing = true;
    notifyListeners();
  }

  void updateContent(int id, String content) {
    final rawTitle = content.split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim();
    final title    = rawTitle.isEmpty ? 'Untitled' : rawTitle;
    _notes = _notes.map((n) => n.id == id ? n.copyWith(content: content, title: title) : n).toList();
    if (_openNote?.id == id) {
      _openNote = _notes.firstWhere((n) => n.id == id);
    }
    notifyListeners();
  }

  void toggleCheckbox(int noteId, int lineIdx) {
    final note  = _notes.firstWhere((n) => n.id == noteId);
    final lines = note.content.split('\n');
    if (lineIdx < lines.length) {
      lines[lineIdx] = lines[lineIdx].replaceFirstMapped(
        RegExp(r'\[([ xX])\]'),
        (m) => m[1]!.trim().isEmpty ? '[x]' : '[ ]',
      );
    }
    updateContent(noteId, lines.join('\n'));
  }

  // ── Kanban ────────────────────────────────────────────────────────────────

  void moveToKanban(int noteId, String colId) {
    final next = _copyKanban();
    for (final k in next.keys) next[k]!.remove(noteId);
    next[colId]!.add(noteId);
    _kanban = next;
    notifyListeners();
  }

  void removeFromKanban(int noteId) {
    final next = _copyKanban();
    for (final k in next.keys) next[k]!.remove(noteId);
    _kanban = next;
    notifyListeners();
  }

  void moveKanbanCard({
    required int    noteId,
    required String fromColId,
    required String toColId,
    required int    insertAt,
  }) {
    final next = _copyKanban();
    next[fromColId]!.remove(noteId);
    final col = next[toColId]!;
    if (insertAt < 0 || insertAt > col.length) {
      col.add(noteId);
    } else {
      col.insert(insertAt, noteId);
    }
    _kanban = next;
    notifyListeners();
  }

  Map<String, List<int>> _copyKanban() =>
      _kanban.map((k, v) => MapEntry(k, List<int>.from(v)));

  // ── Trash / Archive ───────────────────────────────────────────────────────

  void trashNote(int noteId) {
    final note = _notes.firstWhere((n) => n.id == noteId);
    _notes   = _notes.where((n) => n.id != noteId).toList();
    _kanban  = _copyKanban().map((k, v) { v.remove(noteId); return MapEntry(k, v); });
    _trash   = [note, ..._trash];
    if (_openNote?.id == noteId) { _openNote = null; _isEditing = false; }
    notifyListeners();
  }

  void archiveNote(int noteId) {
    final note = _notes.firstWhere((n) => n.id == noteId);
    _notes    = _notes.where((n) => n.id != noteId).toList();
    _kanban   = _copyKanban().map((k, v) { v.remove(noteId); return MapEntry(k, v); });
    _archived = [note, ..._archived];
    if (_openNote?.id == noteId) { _openNote = null; _isEditing = false; }
    notifyListeners();
  }

  void cloneNote(int noteId) {
    final src  = _notes.firstWhere((n) => n.id == noteId);
    final copy = Note(
      id:      DateTime.now().millisecondsSinceEpoch,
      title:   src.title,
      content: src.content,
      date:    'Now',
    );
    final idx    = _notes.indexWhere((n) => n.id == noteId);
    final newList = List<Note>.from(_notes);
    newList.insert(idx + 1, copy);
    _notes = newList;
    // Also clone in kanban if present
    final colId = kanbanColOf(noteId);
    if (colId != null) {
      final next = _copyKanban();
      final col  = next[colId]!;
      final ci   = col.indexOf(noteId);
      col.insert(ci + 1, copy.id);
      _kanban = next;
    }
    notifyListeners();
  }

  void restoreFromTrash(int noteId) {
    final note = _trash.firstWhere((n) => n.id == noteId);
    _trash = _trash.where((n) => n.id != noteId).toList();
    _notes = [note.copyWith(date: 'Now'), ..._notes];
    notifyListeners();
  }

  void deleteFromTrash(int noteId) {
    _trash = _trash.where((n) => n.id != noteId).toList();
    notifyListeners();
  }

  void restoreFromArchive(int noteId) {
    final note = _archived.firstWhere((n) => n.id == noteId);
    _archived = _archived.where((n) => n.id != noteId).toList();
    _notes    = [note.copyWith(date: 'Now'), ..._notes];
    notifyListeners();
  }
}
