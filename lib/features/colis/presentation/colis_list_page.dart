import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/utils/date_format.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../data/colis_models.dart';
import '../data/colis_repository.dart';

class ColisListPage extends ConsumerWidget {
  const ColisListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(colisListProvider);

    return Scaffold(
      backgroundColor: EbiColors.surface,
      appBar: AppBar(
        title: const Text('Mes colis'),
        backgroundColor: EbiColors.white,
        actions: const [NotificationBell()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/colis/new'),
        backgroundColor: EbiColors.blue,
        foregroundColor: EbiColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Déclarer un colis'),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(onRetry: () => ref.invalidate(colisListProvider)),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState(onRefresh: () async {
              ref.invalidate(colisListProvider);
              await ref.read(colisListProvider.future);
            });
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(colisListProvider);
              await ref.read(colisListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ColisTile(colis: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ColisTile extends StatelessWidget {
  const _ColisTile({required this.colis});
  final Colis colis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/colis/${colis.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // Avatar transport
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: colis.transport == 'Avion' ? EbiColors.bluePale : EbiColors.successPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                colis.transport == 'Avion' ? Icons.flight : Icons.directions_boat,
                color: colis.transport == 'Avion' ? EbiColors.blue : EbiColors.success,
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        colis.codesfGlobal,
                        style: EbiTypography.mono(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(status: colis.statut),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${colis.ville}${colis.paysNom != null ? ' · ${colis.paysNom}' : ''}',
                    style: const TextStyle(fontSize: 12, color: EbiColors.ink2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${colis.poidsTotal.toStringAsFixed(2)} kg · ${colis.prixTotal.toStringAsFixed(0)} XOF · ${formatRelativeFr(colis.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: EbiColors.ink3),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _color {
    if (status == 'Livré') return EbiColors.success;
    if (status == 'Arrivé') return EbiColors.success;
    if (status == 'En transit') return EbiColors.blue;
    if (status == 'Payé') return EbiColors.blue;
    if (status == 'En attente') return EbiColors.warning;
    return EbiColors.ink3;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      status,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _color),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(children: const [
      SizedBox(height: 100),
      Icon(Icons.inventory_2_outlined, size: 80, color: EbiColors.ink3),
      SizedBox(height: 16),
      Center(child: Text('Aucun colis pour le moment',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
      SizedBox(height: 6),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 48),
        child: Text(
          'Vos colis enregistrés par votre cargo apparaîtront ici. Tirez pour actualiser.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: EbiColors.ink3),
        ),
      ),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off, size: 64, color: EbiColors.ink3),
      const SizedBox(height: 12),
      const Text('Impossible de charger vos colis.'),
      TextButton(onPressed: onRetry, child: const Text('Réessayer')),
    ]),
  );
}
