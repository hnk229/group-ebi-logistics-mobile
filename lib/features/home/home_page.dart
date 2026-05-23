import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../auth/presentation/auth_controller.dart';
import '../colis/data/colis_repository.dart';
import '../notifications/data/notifications_repository.dart';

/// Dashboard client : salutation, stats colis, raccourcis vers les actions.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(colisStatsProvider);
    final unread = ref.watch(unreadCountProvider);

    final greeting = _greetingFor(user?.name ?? '');

    return Scaffold(
      backgroundColor: EbiColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(colisStatsProvider);
          ref.invalidate(unreadCountProvider);
          await ref.read(colisStatsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            // Header bleu avec salutation + cloche notifs
            SliverAppBar(
              backgroundColor: EbiColors.blue,
              foregroundColor: EbiColors.white,
              expandedHeight: 130,
              pinned: true,
              elevation: 0,
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: EbiColors.white),
                      onPressed: () => context.push('/notifications'),
                    ),
                    Positioned(
                      top: 10, right: 8,
                      child: unread.maybeWhen(
                        data: (n) => n > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: EbiColors.danger,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  n > 99 ? '99+' : '$n',
                                  style: const TextStyle(
                                    color: EbiColors.white, fontSize: 9, fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: const TextStyle(fontSize: 12, color: EbiColors.white)),
                    Text(
                      user?.name.split(' ').first ?? 'Bienvenue',
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: EbiColors.white,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [EbiColors.blue, EbiColors.blueDark],
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // KPI carte
                  stats.when(
                    loading: () => const _StatsSkeleton(),
                    error: (_, __) => _ErrorBox(onRetry: () => ref.invalidate(colisStatsProvider)),
                    data: (s) => _StatsCard(stats: s),
                  ),

                  const SizedBox(height: 20),

                  // Section : actions rapides
                  const _SectionTitle('Actions rapides'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _QuickAction(
                      icon: Icons.location_on, label: 'Adresse Chine',
                      bg: EbiColors.bluePale, fg: EbiColors.blue,
                      onTap: () => context.go('/address'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAction(
                      icon: Icons.inventory_2, label: 'Mes colis',
                      bg: EbiColors.warningPale, fg: EbiColors.warning,
                      onTap: () => context.go('/colis'),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _QuickAction(
                      icon: Icons.chat_outlined, label: 'Discuter',
                      bg: EbiColors.successPale, fg: EbiColors.success,
                      onTap: () => context.push('/chat'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAction(
                      icon: Icons.person_outline, label: 'Mon profil',
                      bg: EbiColors.surface2, fg: EbiColors.ink2,
                      onTap: () => context.push('/profile'),
                    )),
                  ]),

                  if (user?.cargo != null) ...[
                    const SizedBox(height: 20),
                    const _SectionTitle('Mon cargo'),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: EbiColors.bluePale,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_shipping, color: EbiColors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user!.cargo!.nom,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                if (user.cargo!.codePrefix != null)
                                  Text(
                                    'Préfixe : ${user.cargo!.codePrefix}',
                                    style: EbiTypography.mono(fontSize: 11),
                                  ),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingFor(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final dynamic stats;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MES COLIS',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: EbiColors.ink3, letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.total}',
              style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.w700, color: EbiColors.ink,
              ),
            ),
            const Text('Total enregistrés', style: TextStyle(color: EbiColors.ink3, fontSize: 12)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _StatChip(label: 'En attente', value: stats.enAttente, color: EbiColors.warning),
              _StatChip(label: 'Payés', value: stats.paye, color: EbiColors.blue),
              _StatChip(label: 'En transit', value: stats.enTransit, color: EbiColors.blue),
              _StatChip(label: 'Arrivés', value: stats.arrive, color: EbiColors.success),
              _StatChip(label: 'Livrés', value: stats.livre, color: EbiColors.success),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$label : $value',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, required this.bg, required this.fg});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Material(
    color: EbiColors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EbiColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    ),
  );
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) => Card(
    child: Container(height: 180, padding: const EdgeInsets.all(14),
      child: const Center(child: CircularProgressIndicator())),
  );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        const Icon(Icons.cloud_off, color: EbiColors.ink3, size: 32),
        const SizedBox(height: 8),
        const Text('Impossible de charger les stats.', style: TextStyle(fontSize: 13)),
        TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ]),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: EbiColors.ink3, letterSpacing: 0.6,
    ),
  );
}
