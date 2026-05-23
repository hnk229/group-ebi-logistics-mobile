import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.readAt,
    this.createdAt,
    this.data,
  });

  final int id;
  final String title;
  final String body;
  final String type;
  String? readAt;
  final String? createdAt;
  final Map<String, dynamic>? data;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as int,
    title: (j['title'] ?? '') as String,
    body: (j['body'] ?? '') as String,
    type: (j['type'] ?? '') as String,
    readAt: j['read_at'] as String?,
    createdAt: j['created_at'] as String?,
    data: j['data'] as Map<String, dynamic>?,
  );
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<List<AppNotification>> list() async {
    final resp = await _api.get('/api/notifications', query: {'per_page': 50});
    final list = (resp.data as Map<String, dynamic>)['data'] as List;
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount() async {
    try {
      final resp = await _api.get('/api/notifications/unread-count');
      return ((resp.data as Map<String, dynamic>)['count'] ?? 0) as int;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(int id) async {
    await _api.patch('/api/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.post('/api/notifications/read-all');
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/notifications/$id');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

final notificationsListProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).list();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});
