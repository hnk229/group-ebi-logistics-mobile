import 'dart:io';

/// Article en cours de saisie côté client (avant envoi au backend).
///
/// Le client renseigne uniquement les infos qu'il connaît : nom, quantité,
/// code suivi expéditeur, transporteur, URL d'achat, prix d'achat, notes, photo.
/// Le poids, les dimensions et le prix de transport sont remplis par le
/// partenaire à la réception du colis.
class ArticleDraft {
  ArticleDraft({
    this.name = '',
    this.qte = 1,
    this.codesf = '',
    this.transporteur = '',
    this.urlAchat = '',
    this.prixAchat = '',
    this.devise = 'CFA',
    this.notes = '',
    this.photo,
    this.photoPath,
  });

  String name;
  int qte;
  String codesf;
  String transporteur;
  String urlAchat;
  String prixAchat;
  String devise; // CFA | USD | EUR | RMB
  String notes;
  File? photo;
  String? photoPath; // chemin retourné par /upload-article-photo

  bool get isEmpty => name.trim().isEmpty;

  ArticleDraft copy() => ArticleDraft(
        name: name,
        qte: qte,
        codesf: codesf,
        transporteur: transporteur,
        urlAchat: urlAchat,
        prixAchat: prixAchat,
        devise: devise,
        notes: notes,
        photo: photo,
        photoPath: photoPath,
      );

  Map<String, dynamic> toApi() {
    final map = <String, dynamic>{
      'name': name.trim(),
      'qte': qte,
    };
    if (codesf.trim().isNotEmpty) map['codesf'] = codesf.trim();
    if (transporteur.trim().isNotEmpty) map['transporteur'] = transporteur.trim();
    if (urlAchat.trim().isNotEmpty) map['url_achat'] = urlAchat.trim();
    if (notes.trim().isNotEmpty) map['notes'] = notes.trim();
    if (photoPath != null && photoPath!.isNotEmpty) map['photo_path'] = photoPath;

    final prix = double.tryParse(prixAchat.replaceAll(',', '.').trim());
    if (prix != null && prix > 0) {
      switch (devise) {
        case 'USD': map['prix_achat_usd'] = prix;
        case 'EUR': map['prix_achat_eur'] = prix;
        case 'RMB': map['prix_achat_rmb'] = prix;
        case 'CFA':
        default: map['prix_achat_cfa'] = prix;
      }
    }
    return map;
  }
}

class TransportTypeRef {
  TransportTypeRef({required this.id, required this.code, required this.label, required this.mode});
  final int id;
  final String code;
  final String label;
  final String mode;

  factory TransportTypeRef.fromJson(Map<String, dynamic> j) => TransportTypeRef(
        id: j['id'] as int,
        code: (j['code'] ?? '') as String,
        label: (j['label'] ?? '') as String,
        mode: (j['mode'] ?? 'kg') as String,
      );
}
