import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';

/// Shell principal avec bottom navigation pour l'app client.
/// 4 onglets : Accueil, Mes colis, Adresse Chine, Plus (menu)
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  int get _currentIndex {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/colis')) return 1;
    if (location.startsWith('/address')) return 2;
    if (location.startsWith('/menu')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int idx) {
    switch (idx) {
      case 0: context.go('/home'); break;
      case 1: context.go('/colis'); break;
      case 2: context.go('/address'); break;
      case 3: context.go('/menu'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: EbiColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => _onTap(context, i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2),
              label: 'Mes colis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on),
              label: 'Adresse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu), activeIcon: Icon(Icons.menu_open),
              label: 'Plus',
            ),
          ],
        ),
      ),
    );
  }
}
