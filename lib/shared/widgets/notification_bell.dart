import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../features/notifications/data/notifications_repository.dart';

/// Cloche de notification réutilisable (à mettre dans `AppBar.actions`).
/// Affiche un badge avec le nombre de notifications non lues et navigue vers
/// la liste des notifications au tap.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  /// Couleur de l'icône (par défaut : couleur d'icône de l'AppBar).
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: color),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
        Positioned(
          top: 8, right: 6,
          child: unread.maybeWhen(
            data: (n) => n > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: EbiColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      n > 99 ? '99+' : '$n',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
