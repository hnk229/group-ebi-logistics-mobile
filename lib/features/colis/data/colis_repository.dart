import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'article_draft.dart';
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

  /// Liste des types de transport actifs (pour le wizard de déclaration).
  Future<List<TransportTypeRef>> transportTypes() async {
    final resp = await _api.get('/api/client/transport-types');
    final list = (resp.data as Map<String, dynamic>)['data'] as List;
    return list.map((e) => TransportTypeRef.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Récupère l'entrepôt actif du cargo pour le mode demandé (aerial|maritime).
  /// On passe par l'endpoint shipping-address déjà existant — il vérifie qu'un
  /// entrepôt est loué pour ce mode et renvoie l'adresse + l'ID indirectement.
  /// Pour la déclaration, on a besoin de l'entrepot_id : on lit /api/client/colis
  /// d'abord ou on utilise un endpoint dédié si nécessaire.
  Future<int?> entrepotIdForMode(String mode) async {
    // Mapping legacy : Avion=aerial, Bateau=maritime
    final type = mode == 'kg' ? 'aerial' : 'maritime';
    try {
      final resp = await _api.get('/api/client/shipping-address', query: {'type': type});
      // L'endpoint ne renvoie pas l'id directement, on récupère via le cargo
      final data = resp.data as Map<String, dynamic>;
      return data['entrepot_id'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// Upload de la photo d'un article. Retourne le path stocké côté serveur.
  Future<String> uploadArticlePhoto(File file) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path),
    });
    final resp = await _api.raw.post(
      '/api/client/colis/upload-article-photo',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (resp.data as Map<String, dynamic>)['path'] as String;
  }

  /// Création d'un colis client avec ses articles.
  Future<Colis> create({
    required int entrepotId,
    required int? transportTypeId,
    String? transport,
    required String ville,
    required String telephoneDestinataire,
    String? trackingNumber,
    required List<ArticleDraft> articles,
  }) async {
    final payload = <String, dynamic>{
      'entrepot_id': entrepotId,
      'ville': ville.trim(),
      'telephone_destinataire': telephoneDestinataire.trim(),
      if (transportTypeId != null) 'transport_type_id': transportTypeId,
      if (transport != null) 'transport': transport,
      if (trackingNumber != null && trackingNumber.trim().isNotEmpty) 'tracking_number': trackingNumber.trim(),
      'articles': articles.map((a) => a.toApi()).toList(),
    };

    final resp = await _api.post('/api/client/colis', data: payload);
    final data = (resp.data as Map<String, dynamic>)['colis'] as Map<String, dynamic>;
    return Colis.fromJson(data);
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
