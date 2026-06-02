import 'package:flutter/material.dart';

class SubMenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final VoidCallback? onTap; // ✅ Added this

  SubMenuItem({
    required this.title,
    required this.icon,
    required this.screen,
    this.onTap, // ✅ Optional callback
  });
}

class NavItem {
  final String label;
  final IconData icon;
  final Widget? screen; // Use if no sub-menu
  final List<SubMenuItem>? subMenus;

  NavItem({required this.label, required this.icon, this.screen, this.subMenus});
}