import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../auth/presentation/auth_controller.dart';

/// Page Menu (4ᵉ onglet) : raccourcis vers profil, paramètres, aide, déconnexion.
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final initials = (user?.name ?? '?').split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: EbiColors.surface,
      appBar: AppBar(
        title: const Text('Plus'),
        backgroundColor: EbiColors.white,
      ),
      body: ListView(children: [
        // Card user header
        Container(
          color: EbiColors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(children: [
            Container(
              width: 56, height: 56, alignment: Alignment.center,
              decoration: const BoxDecoration(color: EbiColors.blue, shape: BoxShape.circle),
              child: Text(initials, style: const TextStyle(
                color: EbiColors.white, fontSize: 20, fontWeight: FontWeight.w700,
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.name ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              if (user?.email != null) Text(user!.email,
                style: const TextStyle(fontSize: 12, color: EbiColors.ink3)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),

        _Section(title: 'Mon compte', items: [
          _MenuItem(
            icon: Icons.person_outline, label: 'Mon profil',
            onTap: () => context.push('/profile'),
          ),
          _MenuItem(
            icon: Icons.notifications_outlined, label: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          _MenuItem(
            icon: Icons.chat_outlined, label: 'Messages',
            onTap: () => context.push('/chat'),
          ),
        ]),

        _Section(title: 'Application', items: [
          _MenuItem(icon: Icons.info_outline, label: 'À propos', onTap: () {}),
          _MenuItem(icon: Icons.help_outline, label: 'Aide', onTap: () {}),
        ]),

        const SizedBox(height: 16),

        Container(
          color: EbiColors.white,
          child: ListTile(
            leading: const Icon(Icons.logout, color: EbiColors.danger),
            title: const Text('Se déconnecter',
              style: TextStyle(color: EbiColors.danger, fontWeight: FontWeight.w600)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text('Vous devrez vous reconnecter pour accéder à votre espace.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: EbiColors.danger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<_MenuItem> items;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(
        fontSize: 10, color: EbiColors.ink3, letterSpacing: 0.6, fontWeight: FontWeight.w700,
      )),
    ),
    Container(
      color: EbiColors.white,
      child: Column(children: items.map((i) => Column(children: [
        i,
        if (i != items.last) const Divider(height: 1, indent: 56),
      ])).toList()),
    ),
    const SizedBox(height: 16),
  ]);
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: EbiColors.ink2),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right, color: EbiColors.ink3),
    onTap: onTap,
  );
}
