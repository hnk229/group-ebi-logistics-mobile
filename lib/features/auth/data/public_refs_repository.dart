import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class PublicCargo {
  PublicCargo({required this.id, required this.nom, this.codePrefix, this.paysNom});
  final int id;
  final String nom;
  final String? codePrefix;
  final String? paysNom;

  factory PublicCargo.fromJson(Map<String, dynamic> j) => PublicCargo(
    id: j['id'] as int,
    nom: (j['nom'] ?? '') as String,
    codePrefix: j['code_prefix'] as String?,
    paysNom: j['pays']?['nom'] as String?,
  );
}

class PublicPays {
  PublicPays({required this.id, required this.nom, this.codeIso});
  final int id;
  final String nom;
  final String? codeIso;

  factory PublicPays.fromJson(Map<String, dynamic> j) => PublicPays(
    id: j['id'] as int,
    nom: (j['nom'] ?? '') as String,
    codeIso: j['code_iso'] as String?,
  );
}

/// Repository des endpoints publics utilisés par le formulaire d'inscription :
/// liste des cargos actifs (= partenaires chez qui s'inscrire) + pays africains.
class PublicRefsRepository {
  PublicRefsRepository(this._api);
  final ApiClient _api;

  Future<List<PublicCargo>> cargos() async {
    final resp = await _api.get('/api/public/cargos');
    final data = (resp.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => PublicCargo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PublicPays>> pays() async {
    final resp = await _api.get('/api/public/pays');
    final data = (resp.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => PublicPays.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final publicRefsRepositoryProvider = Provider<PublicRefsRepository>((ref) {
  return PublicRefsRepository(ref.watch(apiClientProvider));
});

final cargosFutureProvider = FutureProvider<List<PublicCargo>>((ref) {
  return ref.watch(publicRefsRepositoryProvider).cargos();
});

final paysFutureProvider = FutureProvider<List<PublicPays>>((ref) {
  return ref.watch(publicRefsRepositoryProvider).pays();
});
