import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';

/// Shell principal avec une bottom navigation **flottante** pour l'app client.
/// 4 onglets : Accueil, Mes colis, Adresse Chine, Plus (menu).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  static const _items = [
    (icon: Icons.home_outlined, active: Icons.home, label: 'Accueil', route: '/home'),
    (icon: Icons.inventory_2_outlined, active: Icons.inventory_2, label: 'Colis', route: '/colis'),
    (icon: Icons.location_on_outlined, active: Icons.location_on, label: 'Adresse', route: '/address'),
    (icon: Icons.menu, active: Icons.menu_open, label: 'Plus', route: '/menu'),
  ];

  int get _currentIndex {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/colis')) return 1;
    if (location.startsWith('/address')) return 2;
    if (location.startsWith('/menu')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Le body s'étend derrière la barre flottante.
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: EbiColors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _items[i].icon,
                      activeIcon: _items[i].active,
                      label: _items[i].label,
                      selected: _currentIndex == i,
                      onTap: () => context.go(_items[i].route),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? EbiColors.blue : EbiColors.ink3;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pastille bleu pâle derrière l'icône active.
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? EbiColors.bluePale : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(selected ? activeIcon : icon, size: 22, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
