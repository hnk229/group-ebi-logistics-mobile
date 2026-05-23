import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/utils/date_format.dart';
import '../data/notifications_repository.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsListProvider);
    final repo = ref.read(notificationsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await repo.markAllRead();
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: const Text('Tout marquer lu'),
          ),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur de chargement.')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_off, size: 64, color: EbiColors.ink3),
                SizedBox(height: 12),
                Text('Aucune notification', style: TextStyle(color: EbiColors.ink3)),
              ]),
            ));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsListProvider);
              await ref.read(notificationsListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = list[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.isRead ? EbiColors.surface2 : EbiColors.bluePale,
                      child: Icon(
                        _iconFor(n.type),
                        color: n.isRead ? EbiColors.ink3 : EbiColors.blue,
                        size: 18,
                      ),
                    ),
                    title: Text(n.title, style: TextStyle(
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                    )),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(formatRelativeFr(n.createdAt),
                          style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
                      ],
                    ),
                    onTap: () async {
                      if (!n.isRead) {
                        await repo.markRead(n.id);
                        ref.invalidate(notificationsListProvider);
                        ref.invalidate(unreadCountProvider);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.startsWith('payment.')) return Icons.payment;
    if (type.startsWith('shipment.')) return Icons.local_shipping;
    if (type.startsWith('colis.')) return Icons.inventory_2;
    if (type.startsWith('message.') || type.startsWith('chat.')) return Icons.chat;
    if (type.startsWith('kyb.') || type.startsWith('document.')) return Icons.description;
    return Icons.notifications;
  }
}
