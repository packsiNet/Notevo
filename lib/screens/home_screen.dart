import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../notes_provider.dart';
import '../widgets/bottom_nav_pill.dart';
import '../widgets/notes_tab.dart';
import '../widgets/kanban_tab.dart';
import '../widgets/search_overlay.dart';
import '../widgets/menu_dropdown.dart';
import '../widgets/drag_zones.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _menuOpen    = false;
  bool _searchOpen  = false;
  bool _scrolled    = false;

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final s = _scrollCtrl.offset > 4;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _viewTitle(AppView v) => switch (v) {
    AppView.kanban  => 'Board',
    AppView.shared  => 'Shared',
    AppView.archive => 'Archive',
    AppView.trash   => 'Trash',
    _               => 'All Notes',
  };

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<NotesProvider>();
    final bottom = MediaQuery.of(context).padding.bottom;
    final top    = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [

          // ── Main content ──────────────────────────────────────────────────
          Positioned.fill(
            child: _buildBody(prov, top, bottom),
          ),

          // ── Centered title (fades on scroll) ──────────────────────────────
          if (prov.openNote == null)
            Positioned(
              top:  top + 9,
              left: 0, right: 0,
              child: AnimatedOpacity(
                opacity:  _scrolled ? 0 : 1,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      _viewTitle(prov.view),
                      style: const TextStyle(
                        fontSize:      16,
                        fontWeight:    FontWeight.w600,
                        color:         AppColors.fg,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Hamburger / Back button (top right) ───────────────────────────
          if (prov.openNote == null)
            Positioned(
              top:   top + 9,
              right: 12,
              child: _MenuButton(
                scrolled: _scrolled,
                isBack:   prov.view == AppView.archive || prov.view == AppView.trash,
                onTap: () {
                  if (prov.view == AppView.archive || prov.view == AppView.trash) {
                    prov.setView(AppView.notes);
                  } else {
                    setState(() => _menuOpen = !_menuOpen);
                  }
                },
              ),
            ),

          // ── Bottom nav pill ───────────────────────────────────────────────
          if (prov.openNote == null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: BottomNavPill(
                view:          prov.view,
                bottomPadding: bottom,
                onNotes:    () { prov.setView(AppView.notes);  setState(() { _menuOpen = false; }); },
                onKanban:   () { prov.setView(AppView.kanban); setState(() { _menuOpen = false; }); },
                onShared:   () { prov.setView(AppView.shared); setState(() { _menuOpen = false; }); },
                onSearch:   () => setState(() => _searchOpen = true),
                onAdd:      () => prov.createNote(),
              ),
            ),

          // ── Floating drop zones (visible during drag) ─────────────────────
          if (prov.isDragging)
            Positioned(
              bottom: bottom + 92,
              left: 0, right: 0,
              child: DragZonesRow(dragKind: prov.dragKind),
            ),

          // ── Menu dropdown ─────────────────────────────────────────────────
          if (_menuOpen && prov.openNote == null)
            Positioned.fill(
              child: MenuDropdown(
                archived: prov.archived.length,
                trash:    prov.trash.length,
                onClose:  () => setState(() => _menuOpen = false),
                onArchive: () {
                  prov.setView(AppView.archive);
                  setState(() => _menuOpen = false);
                },
                onTrash: () {
                  prov.setView(AppView.trash);
                  setState(() => _menuOpen = false);
                },
                topPadding: top,
              ),
            ),

          // ── Search overlay ────────────────────────────────────────────────
          if (_searchOpen)
            SearchOverlay(
              onClose: () => setState(() => _searchOpen = false),
            ),

          // ── Editor slide-in ───────────────────────────────────────────────
          if (prov.openNote != null)
            const Positioned.fill(child: EditorScreen()),
        ],
      ),
    );
  }

  Widget _buildBody(NotesProvider prov, double top, double bottom) {
    return switch (prov.view) {
      AppView.notes   => NotesTab(scrollController: _scrollCtrl, topPad: top),
      AppView.kanban  => KanbanTab(topPad: top),
      AppView.shared  => _SharedPlaceholder(topPad: top),
      AppView.archive => _ArchiveView(topPad: top),
      AppView.trash   => _TrashView(topPad: top),
    };
  }
}

// ── Hamburger / Back button ────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  final bool scrolled;
  final bool isBack;
  final VoidCallback onTap;
  const _MenuButton({required this.scrolled, required this.isBack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 36, height: 36,
      decoration: BoxDecoration(
        color:        scrolled ? AppColors.pillBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow:    scrolled ? [const BoxShadow(color: Color(0x47000000), blurRadius: 12)] : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: isBack
            ? const Icon(Icons.chevron_left_rounded, color: AppColors.fg, size: 22)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Container(
                  margin:       const EdgeInsets.symmetric(vertical: 1.5),
                  width:        18, height: 1.7,
                  decoration:   BoxDecoration(
                    color:        AppColors.fg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ),
        ),
      ),
    );
  }
}

// ── Shared placeholder ─────────────────────────────────────────────────────────

class _SharedPlaceholder extends StatelessWidget {
  final double topPad;
  const _SharedPlaceholder({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.pillBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.people_outline_rounded, color: AppColors.sub, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Shared Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            const Text(
              'Collaborate on notes with others.\nComing in a future update.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.sub, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Archive view ───────────────────────────────────────────────────────────────

class _ArchiveView extends StatelessWidget {
  final double topPad;
  const _ArchiveView({required this.topPad});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotesProvider>();
    if (prov.archived.isEmpty) {
      return _EmptyState(
        topPad:  topPad,
        iconBg:  const Color(0x1AFBBF24),
        iconColor: AppColors.colorArchive,
        icon:    Icons.inventory_2_outlined,
        title:   'Archive is empty',
        subtitle: 'Drag a note to the archive zone\nto store it here.',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(10, topPad + 52, 10, 100),
      itemCount: prov.archived.length,
      itemBuilder: (ctx, i) {
        final note    = prov.archived[i];
        final preview = prov.plainPreview(note.content);
        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            color:        AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow:    const [BoxShadow(color: Color(0x38000000), blurRadius: 12, offset: Offset(0,2))],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [AppColors.colorArchive, AppColors.colorArchive.withAlpha(0x88)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(note.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.fg), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text(note.date, style: const TextStyle(fontSize: 10.5, color: AppColors.sub)),
                      ]),
                      const SizedBox(height: 4),
                      Text(preview.isEmpty ? 'No additional text' : preview,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                        overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _IconBtn(
                  color: AppColors.colorArchive,
                  icon:  Icons.restore_rounded,
                  onTap: () => prov.restoreFromArchive(note.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Trash view ─────────────────────────────────────────────────────────────────

class _TrashView extends StatelessWidget {
  final double topPad;
  const _TrashView({required this.topPad});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotesProvider>();
    if (prov.trash.isEmpty) {
      return _EmptyState(
        topPad:   topPad,
        iconBg:   const Color(0x1AF87171),
        iconColor: AppColors.colorTrash,
        icon:     Icons.delete_outline_rounded,
        title:    'Trash is empty',
        subtitle: 'Drag a note to the trash zone\nto delete it.',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(10, topPad + 52, 10, 100),
      itemCount: prov.trash.length,
      itemBuilder: (ctx, i) {
        final note    = prov.trash[i];
        final preview = prov.plainPreview(note.content);
        return Opacity(
          opacity: 0.7,
          child: Container(
            margin: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(
              color:        AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow:    const [BoxShadow(color: Color(0x38000000), blurRadius: 12, offset: Offset(0,2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end:   Alignment.bottomCenter,
                      colors: [AppColors.colorTrash, AppColors.colorTrash.withAlpha(0x88)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(note.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.fg), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text(note.date, style: const TextStyle(fontSize: 10.5, color: AppColors.sub)),
                        ]),
                        const SizedBox(height: 4),
                        Text(preview.isEmpty ? 'No additional text' : preview,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.sub),
                          overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      _IconBtn(
                        color: AppColors.colorDone,
                        icon:  Icons.restore_rounded,
                        onTap: () => prov.restoreFromTrash(note.id),
                      ),
                      const SizedBox(height: 4),
                      _IconBtn(
                        color: AppColors.colorTrash,
                        icon:  Icons.delete_forever_rounded,
                        onTap: () => prov.deleteFromTrash(note.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final double    topPad;
  final Color     iconBg;
  final Color     iconColor;
  final IconData  icon;
  final String    title;
  final String    subtitle;
  const _EmptyState({
    required this.topPad, required this.iconBg, required this.iconColor,
    required this.icon,   required this.title,  required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.fg)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Color     color;
  final IconData  icon;
  final VoidCallback onTap;
  const _IconBtn({required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
