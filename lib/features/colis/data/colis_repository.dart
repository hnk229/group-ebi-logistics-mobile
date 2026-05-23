import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'colis_models.dart';

class ColisRepository {
  ColisRepository(this._api);
  final ApiClient _api;

  Future<List<Colis>> list({String? statut, String? transport}) async {
    final resp = await _api.get('/api/client/colis', query: {
      if (statut != null) 'statut': statut,
      if (transport != null) 'transport': transport,
      'per_page': 50,
    });
    final list = (resp.data as Map<String, dynamic>)['data'] as List;
    return list.map((e) => Colis.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Colis> show(int id) async {
    final resp = await _api.get('/api/client/colis/$id');
    final data = (resp.data as Map<String, dynamic>)['colis'] as Map<String, dynamic>;
    return Colis.fromJson(data);
  }

  Future<ColisStats> stats() async {
    final resp = await _api.get('/api/client/colis/stats');
    return ColisStats.fromJson(resp.data as Map<String, dynamic>);
  }
}

final colisRepositoryProvider = Provider<ColisRepository>((ref) {
  return ColisRepository(ref.watch(apiClientProvider));
});

final colisListProvider = FutureProvider.autoDispose<List<Colis>>((ref) {
  return ref.watch(colisRepositoryProvider).list();
});

final colisStatsProvider = FutureProvider.autoDispose<ColisStats>((ref) {
  return ref.watch(colisRepositoryProvider).stats();
});

final colisDetailProvider = FutureProvider.autoDispose.family<Colis, int>((ref, id) {
  return ref.watch(colisRepositoryProvider).show(id);
});
