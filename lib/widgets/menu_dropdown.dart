import 'dart:ui';
import 'package:flutter/material.dart';

import '../app_theme.dart';

class MenuDropdown extends StatelessWidget {
  final int          archived;
  final int          trash;
  final VoidCallback onClose;
  final VoidCallback onArchive;
  final VoidCallback onTrash;
  final double       topPadding;

  const MenuDropdown({
    super.key,
    required this.archived,
    required this.trash,
    required this.onClose,
    required this.onArchive,
    required this.onTrash,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withAlpha(0x59),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Dropdown panel
        Positioned(
          top:   topPadding + 48,
          right: 6,
          child: Container(
            width: 182,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow:    const [
                BoxShadow(color: Color(0x80000000), blurRadius: 28, offset: Offset(0, 6)),
                BoxShadow(color: AppColors.border, blurRadius: 0, spreadRadius: 1),
              ],
            ),
            child: Column(
              children: [
                // Archive
                _MenuItem(
                  iconBg:    const Color(0x1AFBBF24),
                  iconColor: AppColors.colorArchive,
                  icon:      Icons.inventory_2_outlined,
                  label:     'Archive',
                  badge:     archived > 0 ? '$archived' : null,
                  badgeColor: AppColors.colorArchive,
                  onTap:     onArchive,
                ),

                // Divider
                Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 5), color: AppColors.border),

                // Trash
                _MenuItem(
                  iconBg:    const Color(0x1AF87171),
                  iconColor: AppColors.colorTrash,
                  icon:      Icons.delete_outline_rounded,
                  label:     'Trash',
                  badge:     trash > 0 ? '$trash' : null,
                  badgeColor: AppColors.colorTrash,
                  onTap:     onTrash,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatefulWidget {
  final Color    iconBg;
  final Color    iconColor;
  final IconData icon;
  final String   label;
  final String?  badge;
  final Color    badgeColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.iconBg, required this.iconColor, required this.icon,
    required this.label, this.badge, required this.badgeColor, required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter:  (_) => setState(() => _hovered = true),
        onExit:   (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:     const EdgeInsets.all(8),
          decoration:  BoxDecoration(
            color:        _hovered ? AppColors.pillBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: widget.iconBg, shape: BoxShape.circle),
                child: Icon(widget.icon, size: 14, color: widget.iconColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.fg, letterSpacing: -0.15)),
              ),
              if (widget.badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color:        widget.badgeColor.withAlpha(0x1F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(widget.badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.badgeColor)),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.sub),
            ],
          ),
        ),
      ),
    );
  }
}
