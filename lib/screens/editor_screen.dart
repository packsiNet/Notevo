import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../notes_provider.dart';
import '../widgets/status_sheet.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _ctrl;
  final _focus = FocusNode();
  bool _editingTitle = false;
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    final note = context.read<NotesProvider>().openNote!;
    _ctrl      = TextEditingController(text: note.content);
    _titleCtrl = TextEditingController(text: note.title == 'Untitled' ? '' : note.title);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _titleCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commitTitle(NotesProvider prov) {
    final val  = _titleCtrl.text.trim().isEmpty ? 'Untitled' : _titleCtrl.text.trim();
    final note = prov.openNote!;
    final old  = note.content;
    final lines = old.split('\n');
    final newFirst   = '# $val';
    final newContent = old.trim().isEmpty
        ? newFirst
        : (lines.first.startsWith('#')
            ? [newFirst, ...lines.skip(1)].join('\n')
            : [newFirst, ...lines].join('\n'));
    prov.updateContent(note.id, newContent);
    setState(() => _editingTitle = false);
  }

  void _applyFormat(NotesProvider prov, _ToolbarAction action) {
    final note = prov.openNote!;
    final sel  = _ctrl.selection;
    final text = _ctrl.text;
    final s    = sel.isValid ? sel.start : text.length;
    final e    = sel.isValid ? sel.end   : text.length;
    String newText;
    int    newCursor;
    switch (action) {
      case _ToolbarAction.h1:
        final ls = text.lastIndexOf('\n', s - 1) + 1;
        newText   = '${text.substring(0, ls)}# ${text.substring(ls)}';
        newCursor = s + 2;
      case _ToolbarAction.h2:
        final ls = text.lastIndexOf('\n', s - 1) + 1;
        newText   = '${text.substring(0, ls)}## ${text.substring(ls)}';
        newCursor = s + 3;
      case _ToolbarAction.bold:
        if (s == e) { newText = '${text.substring(0, s)}****${text.substring(s)}'; newCursor = s + 2; }
        else        { newText = '${text.substring(0, s)}**${text.substring(s, e)}**${text.substring(e)}'; newCursor = e + 4; }
      case _ToolbarAction.italic:
        if (s == e) { newText = '${text.substring(0, s)}__${text.substring(s)}'; newCursor = s + 1; }
        else        { newText = '${text.substring(0, s)}_${text.substring(s, e)}_${text.substring(e)}'; newCursor = e + 2; }
      case _ToolbarAction.code:
        if (s == e) { newText = '${text.substring(0, s)}``${text.substring(s)}'; newCursor = s + 1; }
        else        { newText = '${text.substring(0, s)}`${text.substring(s, e)}`${text.substring(e)}'; newCursor = e + 2; }
      case _ToolbarAction.codeBlock:
        final ls = text.lastIndexOf('\n', s - 1) + 1;
        newText   = '${text.substring(0, ls)}```\n${text.substring(ls)}\n```\n';
        newCursor = s + 4;
      case _ToolbarAction.bullet:
        final ls = text.lastIndexOf('\n', s - 1) + 1;
        newText   = '${text.substring(0, ls)}- ${text.substring(ls)}';
        newCursor = s + 2;
      case _ToolbarAction.ordered:
        final ls = text.lastIndexOf('\n', s - 1) + 1;
        newText   = '${text.substring(0, ls)}1. ${text.substring(ls)}';
        newCursor = s + 3;
      case _ToolbarAction.checkbox:
        final ls = text.lastIndexOf('\n', s - 1) + 1;
        newText   = '${text.substring(0, ls)}- [ ] ${text.substring(ls)}';
        newCursor = s + 6;
      case _ToolbarAction.quote:
        final ls = text.lastIndexOf('\n', s - 1) + 1;
        newText   = '${text.substring(0, ls)}> ${text.substring(ls)}';
        newCursor = s + 2;
      case _ToolbarAction.divider:
        newText   = '${text.substring(0, s)}\n---\n${text.substring(s)}';
        newCursor = s + 5;
    }
    prov.updateContent(note.id, newText);
    _ctrl.value = TextEditingValue(
      text:      newText,
      selection: TextSelection.collapsed(offset: newCursor.clamp(0, newText.length)),
    );
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotesProvider>();
    final note = prov.openNote;
    if (note == null) return const SizedBox.shrink();

    final top     = MediaQuery.of(context).padding.top;
    final editing = prov.isEditing;

    // Sync controller when content updated externally (e.g. checkbox toggle)
    if (_ctrl.text != note.content && !editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ctrl.value = _ctrl.value.copyWith(text: note.content);
      });
    }

    final colId    = prov.kanbanColOf(note.id);
    final colColor = colId != null ? AppColors.kanbanColor(colId) : null;

    return Material(
      color: AppColors.bg,
      child: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(12, top + 10, 12, 10),
            decoration: BoxDecoration(
              color:  AppColors.bg,
              border: editing ? null : Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // Back button
                _TopBarBtn(
                  onTap: () => prov.closeNoteEditor(),
                  child: const Icon(Icons.chevron_left_rounded, color: AppColors.fg, size: 22),
                ),
                const SizedBox(width: 4),

                // Title
                Expanded(
                  child: _editingTitle
                    ? TextField(
                        controller: _titleCtrl,
                        autofocus:  true,
                        style:      const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.fg, letterSpacing: -0.3),
                        decoration: const InputDecoration(
                          hintText:       'Untitled',
                          hintStyle:      TextStyle(color: AppColors.sub),
                          border:         InputBorder.none,
                          isDense:        true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _commitTitle(prov),
                        onEditingComplete: () => _commitTitle(prov),
                      )
                    : GestureDetector(
                        onTap: editing ? () {
                          _titleCtrl.text = note.title == 'Untitled' ? '' : note.title;
                          setState(() => _editingTitle = true);
                        } : null,
                        child: Text(
                          note.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.fg, letterSpacing: -0.3),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ),

                // Kanban dot / board icon
                _TopBarBtn(
                  onTap: () => showStatusSheet(context, note),
                  child: colColor != null
                    ? Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color:     colColor,
                          shape:     BoxShape.circle,
                          boxShadow: [BoxShadow(color: colColor.withAlpha(0xAA), blurRadius: 5)],
                        ),
                      )
                    : const Icon(Icons.dashboard_customize_outlined, color: AppColors.sub, size: 16),
                ),
                const SizedBox(width: 6),

                // Edit / Preview toggle
                _SegmentedControl(
                  editing: editing,
                  onEdit:    () { prov.setEditing(true);  _focus.requestFocus(); },
                  onPreview: () { prov.setEditing(false); _focus.unfocus(); },
                ),
              ],
            ),
          ),

          // ── Formatting toolbar ─────────────────────────────────────────────
          if (editing)
            Container(
              height: 44,
              decoration: BoxDecoration(
                color:  AppColors.bg,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                children: _ToolbarAction.values.map((action) => _ToolBtn(
                  action: action,
                  onTap:  () => _applyFormat(prov, action),
                )).toList(),
              ),
            ),

          // ── Content area ───────────────────────────────────────────────────
          Expanded(
            child: editing
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: TextField(
                    controller:   _ctrl,
                    focusNode:    _focus,
                    maxLines:     null,
                    expands:      true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontSize:      14,
                      height:        1.8,
                      color:         AppColors.fg,
                      letterSpacing: -0.1,
                    ),
                    decoration: const InputDecoration(
                      border:         InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => prov.updateContent(note.id, v),
                  ),
                )
              : Markdown(
                  data:            note.content,
                  selectable:      false,
                  padding:         const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  styleSheet:      _markdownStyle(),
                  checkboxBuilder: (checked) => _CheckboxWidget(checked: checked),
                  onTapLink:       (_, __, ___) {},
                ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle() => MarkdownStyleSheet(
    h1:             const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.fg, letterSpacing: -0.5, height: 1.3),
    h2:             const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.fg, letterSpacing: -0.2, height: 1.3),
    h3:             const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.fg, height: 1.3),
    h4:             const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.fg, height: 1.3),
    h5:             const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.fg),
    h6:             const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fg),
    p:              const TextStyle(fontSize: 14, height: 1.75, color: AppColors.fg),
    em:             const TextStyle(fontStyle: FontStyle.italic, color: AppColors.fg),
    strong:         const TextStyle(fontWeight: FontWeight.w600, color: AppColors.fg),
    del:            const TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.sub),
    code:           const TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: Color(0xFFE6C07B), backgroundColor: Color(0x1AFFFFFF)),
    codeblockDecoration: BoxDecoration(
      color: const Color(0x40000000),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    blockquoteDecoration: BoxDecoration(
      border: const Border(left: BorderSide(color: AppColors.colorDoing, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 14),
    blockquote:      const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.sub, height: 1.7),
    listBullet:      const TextStyle(fontSize: 14, color: AppColors.colorDoing),
    tableHead:       const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.fg),
    tableBody:       const TextStyle(fontSize: 13, color: AppColors.sub),
    tableBorder:     TableBorder.all(color: AppColors.border, width: 1, borderRadius: BorderRadius.circular(8)),
    horizontalRuleDecoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    blockSpacing: 8,
  );
}

// ── Checkbox widget for markdown ───────────────────────────────────────────────

class _CheckboxWidget extends StatelessWidget {
  final bool checked;
  const _CheckboxWidget({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16, height: 16,
      margin: const EdgeInsets.only(right: 8, top: 2),
      decoration: BoxDecoration(
        color:        checked ? AppColors.colorDoing : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border:       checked ? null : Border.all(color: AppColors.sub.withAlpha(0x8F), width: 1.5),
      ),
      child: checked
        ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
        : null,
    );
  }
}

// ── Segmented control (Edit / Preview) ────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  const _SegmentedControl({required this.editing, required this.onEdit, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:        AppColors.pillBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _Seg(label: 'Edit',    active: editing,  onTap: onEdit),
          _Seg(label: 'Preview', active: !editing, onTap: onPreview),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool   active;
  final VoidCallback onTap;
  const _Seg({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color:        active ? AppColors.pillActive : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow:    active ? [const BoxShadow(color: Color(0x59000000), blurRadius: 3, offset: Offset(0, 1))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: active ? AppColors.fg : AppColors.sub),
        ),
      ),
    );
  }
}

// ── Top bar button ─────────────────────────────────────────────────────────────

class _TopBarBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TopBarBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────────

enum _ToolbarAction {
  h1, h2, bold, italic, code, codeBlock,
  bullet, ordered, checkbox, quote, divider,
}

class _ToolBtn extends StatelessWidget {
  final _ToolbarAction action;
  final VoidCallback   onTap;
  const _ToolBtn({required this.action, required this.onTap});

  Widget _icon() => switch (action) {
    _ToolbarAction.h1       => const Text('H1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    _ToolbarAction.h2       => const Text('H2', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
    _ToolbarAction.bold     => const Text('B',  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'serif')),
    _ToolbarAction.italic   => const Text('I',  style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, fontFamily: 'serif')),
    _ToolbarAction.code     => const Text('`',  style: TextStyle(fontSize: 15, fontFamily: 'monospace')),
    _ToolbarAction.codeBlock => const Icon(Icons.code_rounded, size: 16),
    _ToolbarAction.bullet   => const Icon(Icons.format_list_bulleted_rounded, size: 16),
    _ToolbarAction.ordered  => const Text('1.', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
    _ToolbarAction.checkbox => const Icon(Icons.check_box_outline_blank_rounded, size: 15),
    _ToolbarAction.quote    => const Icon(Icons.format_quote_rounded, size: 16),
    _ToolbarAction.divider  => const Text('—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 34),
        height: 32,
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color:        AppColors.pillBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: AppColors.sub),
            child: IconTheme(
              data: const IconThemeData(color: AppColors.sub, size: 16),
              child: _icon(),
            ),
          ),
        ),
      ),
    );
  }
}
