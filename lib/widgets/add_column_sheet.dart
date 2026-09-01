import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../notes_provider.dart';

Future<void> showAddColumnSheet(BuildContext context, String colId) {
  return showModalBottomSheet(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder:            (_) => _AddColumnSheet(colId: colId),
  );
}

class _AddColumnSheet extends StatefulWidget {
  final String colId;
  const _AddColumnSheet({required this.colId});
  @override
  State<_AddColumnSheet> createState() => _AddColumnSheetState();
}

class _AddColumnSheetState extends State<_AddColumnSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<NotesProvider>();
    final col    = kanbanColumns.firstWhere((c) => c.id == widget.colId);
    final inCol  = Set<int>.from(prov.kanban[widget.colId] ?? []);
    final allOut = prov.notes.where((n) => !inCol.contains(n.id)).toList();
    final shown  = _query.isEmpty
        ? allOut
        : allOut.where((n) =>
            n.title.toLowerCase().contains(_query.toLowerCase()) ||
            prov.plainPreview(n.content).toLowerCase().contains(_query.toLowerCase())
          ).toList();
    final bottom  = MediaQuery.of(context).padding.bottom;
    final keypad  = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.68 + keypad,
      decoration: const BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
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

          // Column label
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: col.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(col.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.fg, letterSpacing: -0.2)),
            ],
          ),
          const SizedBox(height: 14),

          // New card button
          GestureDetector(
            onTap: () {
              prov.createNote();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              decoration: BoxDecoration(
                color:        AppColors.pillBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color:        col.color.withAlpha(0x22),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.add_rounded, color: col.color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Text('New card', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.fg)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (allOut.isNotEmpty) ...[
            // "From notes" section header
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('FROM NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.sub, letterSpacing: 0.6)),
            ),

            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColors.pillBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 16, color: AppColors.sub),
                  const SizedBox(width: 7),
                  Expanded(
                    child: TextField(
                      controller:  _searchCtrl,
                      onChanged:   (v) => setState(() => _query = v),
                      style:       const TextStyle(fontSize: 13, color: AppColors.fg),
                      decoration:  const InputDecoration(
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
                      onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                      child: const Text('✕', style: TextStyle(fontSize: 14, color: AppColors.sub)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Results list
            Expanded(
              child: shown.isEmpty
                ? Center(child: Text('No results for "$_query"', style: const TextStyle(fontSize: 13, color: AppColors.sub)))
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (ctx, i) {
                      final note    = shown[i];
                      final preview = prov.plainPreview(note.content);
                      final inOther = kanbanColumns.firstWhere(
                        (c) => c.id != widget.colId && (prov.kanban[c.id]?.contains(note.id) ?? false),
                        orElse: () => KanbanColumn(id: '', label: '', color: Colors.transparent),
                      );
                      return GestureDetector(
                        onTap: () {
                          prov.moveToKanban(note.id, widget.colId);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(note.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.fg, letterSpacing: -0.2), overflow: TextOverflow.ellipsis),
                                    if (preview.isNotEmpty)
                                      Text(preview, style: const TextStyle(fontSize: 11.5, color: AppColors.sub), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (inOther.id.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:        inOther.color.withAlpha(0x18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(inOther.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: inOther.color)),
                                ),
                              ],
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.sub),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ] else
            Center(child: Text('All notes are already in this column', style: const TextStyle(fontSize: 13, color: AppColors.sub))),
        ],
      ),
    );
  }
}
