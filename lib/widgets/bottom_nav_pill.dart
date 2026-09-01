import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models.dart';

class BottomNavPill extends StatelessWidget {
  final AppView      view;
  final double       bottomPadding;
  final VoidCallback onNotes;
  final VoidCallback onKanban;
  final VoidCallback onShared;
  final VoidCallback onSearch;
  final VoidCallback onAdd;

  const BottomNavPill({
    super.key,
    required this.view,
    required this.bottomPadding,
    required this.onNotes,
    required this.onKanban,
    required this.onShared,
    required this.onSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:        AppColors.pillBg,
            borderRadius: BorderRadius.circular(100),
            boxShadow:    const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavBtn(icon: _NotesIcon(), active: view == AppView.notes,  onTap: onNotes),
              _NavBtn(icon: _KanbanIcon(), active: view == AppView.kanban, onTap: onKanban),
              // Vertical divider
              Container(width: 1, height: 20, color: AppColors.sub.withAlpha(0x4D), margin: const EdgeInsets.symmetric(horizontal: 2)),
              _NavBtn(icon: const Icon(Icons.search_rounded, size: 18), active: false, onTap: onSearch),
              _NavBtn(icon: const Icon(Icons.add_rounded, size: 16),    active: false, onTap: onAdd),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final Widget       icon;
  final bool         active;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44, height: 34,
        decoration: BoxDecoration(
          color:        active ? AppColors.pillActive : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow:    active ? [const BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1))] : [],
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: active ? AppColors.fg : AppColors.sub, size: 20),
            child: icon,
          ),
        ),
      ),
    );
  }
}

// ── Custom SVG-matching icons ──────────────────────────────────────────────────

class _NotesIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _LinesPainter(color: IconTheme.of(context).color ?? AppColors.sub),
    );
  }
}

class _LinesPainter extends CustomPainter {
  final Color color;
  _LinesPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1.6..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(3, 5), Offset(17, 5), p);
    canvas.drawLine(Offset(3, 9), Offset(17, 9), p);
    canvas.drawLine(Offset(3, 13), Offset(11, 13), p);
  }
  @override bool shouldRepaint(_LinesPainter old) => old.color != color;
}

class _KanbanIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _KanbanPainter(color: IconTheme.of(context).color ?? AppColors.sub),
    );
  }
}

class _KanbanPainter extends CustomPainter {
  final Color color;
  _KanbanPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1.6..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    // Three columns
    canvas.drawRRect(RRect.fromLTRBR(2, 3, 6, 13, const Radius.circular(1.5)), p);
    canvas.drawRRect(RRect.fromLTRBR(8, 3, 12, 10, const Radius.circular(1.5)), p);
    canvas.drawRRect(RRect.fromLTRBR(14, 3, 18, 16, const Radius.circular(1.5)), p);
  }
  @override bool shouldRepaint(_KanbanPainter old) => old.color != color;
}
