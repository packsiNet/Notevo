import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../notes_provider.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const SearchOverlay({super.key, required this.onClose});
  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> with SingleTickerProviderStateMixin {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  late AnimationController _animCtrl;
  late Animation<double>    _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _fade     = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() async {
    await _animCtrl.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final prov    = context.watch<NotesProvider>();
    final top     = MediaQuery.of(context).padding.top;
    final results = _query.trim().isEmpty ? <Note>[] : prov.notes.where((n) =>
        n.title.toLowerCase().contains(_query.toLowerCase()) ||
        prov.plainPreview(n.content).toLowerCase().contains(_query.toLowerCase())
    ).toList();

    final accentPalette = const [
      AppColors.colorDoing,
      Color(0xFFA78BFA),
      Color(0xFFF472B6),
      AppColors.colorDone,
      AppColors.colorArchive,
      Color(0xFFFB923C),
    ];

    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.black54,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: GestureDetector(
            onTap: _close,
            child: SizedBox.expand(
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(14, top + 10, 14, 12),
                    child: GestureDetector(
                      onTap: () {}, // don't bubble to background close
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color:        Colors.white.withAlpha(0x14),
                          borderRadius: BorderRadius.circular(14),
                          border:       Border.all(color: AppColors.colorDoing.withAlpha(0x73)),
                          boxShadow:    [
                            BoxShadow(color: AppColors.colorDoing.withAlpha(0x1F), blurRadius: 0, spreadRadius: 3),
                            const BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 8)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 18, color: AppColors.colorDoing),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _ctrl,
                                focusNode:  _focus,
                                onChanged:  (v) => setState(() => _query = v),
                                style:      const TextStyle(fontSize: 15, color: AppColors.fg, letterSpacing: -0.2),
                                decoration: const InputDecoration(
                                  hintText:       'Search notes…',
                                  hintStyle:      TextStyle(color: AppColors.sub),
                                  border:         InputBorder.none,
                                  isDense:        true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                                child: const Text('✕', style: TextStyle(fontSize: 16, color: AppColors.sub)),
                              )
                            else
                              GestureDetector(
                                onTap: _close,
                                child: const Text('Cancel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.sub, letterSpacing: 0.2)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Results
                  Expanded(
                    child: GestureDetector(
                      onTap: () {}, // block close
                      child: _query.trim().isEmpty
                        ? Center(
                            child: Opacity(
                              opacity: 0.45,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_rounded, size: 36, color: AppColors.fg),
                                  const SizedBox(height: 12),
                                  const Text('Type to search your notes', style: TextStyle(fontSize: 13, color: AppColors.fg, letterSpacing: 0.1)),
                                ],
                              ),
                            ),
                          )
                        : results.isEmpty
                          ? Center(
                              child: Opacity(
                                opacity: 0.5,
                                child: Text('No results for "$_query"', style: const TextStyle(fontSize: 14, color: AppColors.fg)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                              itemCount: results.length + 1,
                              itemBuilder: (ctx, i) {
                                if (i == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 2, bottom: 6, top: 4),
                                    child: Text(
                                      '${results.length} result${results.length != 1 ? "s" : ""}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.sub, letterSpacing: 0.6),
                                    ),
                                  );
                                }
                                final note    = results[i - 1];
                                final col     = kanbanColumns.firstWhere(
                                  (c) => prov.kanban[c.id]?.contains(note.id) ?? false,
                                  orElse: () => KanbanColumn(id: '', label: '', color: Colors.transparent),
                                );
                                final accent  = col.id.isNotEmpty
                                    ? col.color
                                    : accentPalette[(i - 1) % accentPalette.length];
                                final preview = prov.plainPreview(note.content);

                                return GestureDetector(
                                  onTap: () {
                                    widget.onClose();
                                    prov.openNoteEditor(note);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 7),
                                    decoration: BoxDecoration(
                                      color:        AppColors.cardBg.withAlpha(0xE6),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow:    const [BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 2))],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: col.id.isNotEmpty ? 72 : 58,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end:   Alignment.bottomCenter,
                                              colors: [accent, accent.withAlpha(0x88)],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(children: [
                                                  Expanded(child: Text(note.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.fg), overflow: TextOverflow.ellipsis)),
                                                  Text(note.date, style: const TextStyle(fontSize: 10.5, color: AppColors.sub)),
                                                ]),
                                                if (preview.isNotEmpty) ...[
                                                  const SizedBox(height: 3),
                                                  Text(preview, style: const TextStyle(fontSize: 12.5, color: AppColors.sub), overflow: TextOverflow.ellipsis),
                                                ],
                                                if (col.id.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.fromLTRB(5, 2, 7, 2),
                                                    decoration: BoxDecoration(
                                                      color:        col.color.withAlpha(0x1A),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: col.color)),
                                                        Text(col.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: col.color)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
