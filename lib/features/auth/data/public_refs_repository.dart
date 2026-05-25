import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class PublicCargoTarif {
  PublicCargoTarif({
    required this.transportTypeId,
    required this.code,
    required this.label,
    required this.mode,
    this.prix,
    this.transitDays,
  });

  final int transportTypeId;
  final String code;
  final String label;
  final String mode; // kg | cbm
  final double? prix;
  final int? transitDays;

  factory PublicCargoTarif.fromJson(Map<String, dynamic> j) => PublicCargoTarif(
        transportTypeId: j['transport_type_id'] as int,
        code: (j['code'] ?? '') as String,
        label: (j['label'] ?? '') as String,
        mode: (j['mode'] ?? 'kg') as String,
        prix: j['prix'] != null ? (j['prix'] as num).toDouble() : null,
        transitDays: j['transit_days'] as int?,
      );
}

class PublicCargo {
  PublicCargo({
    required this.id,
    required this.nom,
    required this.slug,
    this.codePrefix,
    this.paysNom,
    this.ville,
    this.logoUrl,
    this.description,
    this.rating = 0,
    this.totalColis = 0,
    this.totalClients = 0,
    this.tarifs = const [],
  });

  final int id;
  final String nom;
  final String slug;
  final String? codePrefix;
  final String? paysNom;
  final String? ville;
  final String? logoUrl;
  final String? description;
  final double rating;
  final int totalColis;
  final int totalClients;
  final List<PublicCargoTarif> tarifs;

  String get initial => nom.isNotEmpty ? nom.substring(0, 1).toUpperCase() : '?';

  PublicCargoTarif? tarifFor(String mode) {
    for (final t in tarifs) {
      if (t.mode == mode && t.prix != null) return t;
    }
    return null;
  }

  factory PublicCargo.fromJson(Map<String, dynamic> j) => PublicCargo(
        id: j['id'] as int,
        nom: (j['nom'] ?? '') as String,
        slug: (j['slug'] ?? '') as String,
        codePrefix: j['code_prefix'] as String?,
        paysNom: j['pays']?['nom'] as String?,
        ville: j['ville'] as String?,
        logoUrl: j['logo_url'] as String?,
        description: j['description'] as String?,
        rating: ((j['rating'] ?? 0) as num).toDouble(),
        totalColis: (j['total_colis'] ?? 0) as int,
        totalClients: (j['total_clients'] ?? 0) as int,
        tarifs: (j['tarifs'] as List?)
                ?.map((t) => PublicCargoTarif.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PublicCargoDetail extends PublicCargo {
  PublicCargoDetail({
    required super.id,
    required super.nom,
    required super.slug,
    super.codePrefix,
    super.paysNom,
    super.ville,
    super.logoUrl,
    super.description,
    super.rating,
    super.totalColis,
    super.totalClients,
    super.tarifs,
    this.adresse,
    this.telephone,
    this.whatsapp,
    this.emailPublic,
  });

  final String? adresse;
  final String? telephone;
  final String? whatsapp;
  final String? emailPublic;

  factory PublicCargoDetail.fromJson(Map<String, dynamic> j) => PublicCargoDetail(
        id: j['id'] as int,
        nom: (j['nom'] ?? '') as String,
        slug: (j['slug'] ?? '') as String,
        codePrefix: j['code_prefix'] as String?,
        paysNom: j['pays']?['nom'] as String?,
        ville: j['ville'] as String?,
        logoUrl: j['logo_url'] as String?,
        description: j['description'] as String?,
        rating: ((j['rating'] ?? 0) as num).toDouble(),
        totalColis: (j['total_colis'] ?? 0) as int,
        totalClients: (j['total_clients'] ?? 0) as int,
        tarifs: (j['tarifs'] as List?)
                ?.map((t) => PublicCargoTarif.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        adresse: j['adresse'] as String?,
        telephone: j['telephone'] as String?,
        whatsapp: j['whatsapp'] as String?,
        emailPublic: j['email_public'] as String?,
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

  Future<List<PublicCargo>> cargos({int? paysId}) async {
    final query = paysId != null ? {'pays_id': paysId} : null;
    final resp = await _api.get('/api/public/cargos', query: query);
    final data = (resp.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => PublicCargo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PublicCargoDetail> cargoDetail(String slug) async {
    final resp = await _api.get('/api/public/cargos/$slug');
    final data = (resp.data as Map<String, dynamic>)['cargo'] as Map<String, dynamic>;
    return PublicCargoDetail.fromJson(data);
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
