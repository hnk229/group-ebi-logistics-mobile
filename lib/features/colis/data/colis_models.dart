// Modèles métiers Colis pour l'app client (lecture seule).

class Colis {
  Colis({
    required this.id,
    required this.codesfGlobal,
    this.trackingNumber,
    required this.statut,
    required this.transport,
    required this.poidsTotal,
    required this.cbmTotal,
    required this.prixTotal,
    required this.ville,
    this.telephoneDestinataire,
    this.createdAt,
    this.colisPayeAt,
    this.colisTransitAt,
    this.colisArriveAt,
    this.colisLivreAt,
    this.paysNom,
    this.articles = const [],
    this.events = const [],
  });

  final int id;
  final String codesfGlobal;
  final String? trackingNumber;
  final String statut;
  final String transport;
  final double poidsTotal;
  final double cbmTotal;
  final double prixTotal;
  final String ville;
  final String? telephoneDestinataire;
  final String? createdAt;
  final String? colisPayeAt;
  final String? colisTransitAt;
  final String? colisArriveAt;
  final String? colisLivreAt;
  final String? paysNom;
  final List<ColisArticle> articles;
  final List<ColisEvent> events;

  factory Colis.fromJson(Map<String, dynamic> j) => Colis(
    id: j['id'] as int,
    codesfGlobal: (j['codesf_global'] ?? '') as String,
    trackingNumber: j['tracking_number'] as String?,
    statut: (j['statut'] ?? 'En attente') as String,
    transport: (j['transport'] ?? 'Avion') as String,
    poidsTotal: ((j['poids_total'] ?? 0) as num).toDouble(),
    cbmTotal: ((j['cbm_total'] ?? 0) as num).toDouble(),
    prixTotal: ((j['prix_total'] ?? 0) as num).toDouble(),
    ville: (j['ville'] ?? '') as String,
    telephoneDestinataire: j['telephone_destinataire'] as String?,
    createdAt: j['created_at'] as String?,
    colisPayeAt: j['colis_paye_at'] as String?,
    colisTransitAt: j['colis_transit_at'] as String?,
    colisArriveAt: j['colis_arrive_at'] as String?,
    colisLivreAt: j['colis_livre_at'] as String?,
    paysNom: j['pays']?['nom'] as String?,
    articles: (j['articles'] as List?)
        ?.map((a) => ColisArticle.fromJson(a as Map<String, dynamic>))
        .toList() ?? [],
    events: (j['events'] as List?)
        ?.map((e) => ColisEvent.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class ColisArticle {
  ColisArticle({
    required this.id,
    required this.name,
    this.qte = 1,
    this.poids = 0,
    this.cbm = 0,
    this.photoPath,
    this.lienAchat,
  });

  final int id;
  final String name;
  final int qte;
  final double poids;
  final double cbm;
  final String? photoPath;
  final String? lienAchat;

  factory ColisArticle.fromJson(Map<String, dynamic> j) => ColisArticle(
    id: j['id'] as int,
    name: (j['name'] ?? '') as String,
    qte: (j['qte'] ?? 1) as int,
    poids: ((j['poids'] ?? 0) as num).toDouble(),
    cbm: ((j['cbm'] ?? 0) as num).toDouble(),
    photoPath: j['photo_url'] as String? ?? j['photo_path'] as String?,
    lienAchat: j['lien_achat'] as String?,
  );
}

class ColisEvent {
  ColisEvent({
    required this.id,
    required this.type,
    this.statusFrom,
    this.statusTo,
    this.note,
    this.createdAt,
  });

  final int id;
  final String type;
  final String? statusFrom;
  final String? statusTo;
  final String? note;
  final String? createdAt;

  factory ColisEvent.fromJson(Map<String, dynamic> j) => ColisEvent(
    id: j['id'] as int,
    type: (j['type'] ?? '') as String,
    statusFrom: j['status_from'] as String?,
    statusTo: j['status_to'] as String?,
    note: j['note'] as String?,
    createdAt: j['created_at'] as String?,
  );
}

class ColisStats {
  ColisStats({
    required this.total,
    required this.enAttente,
    required this.paye,
    required this.enTransit,
    required this.arrive,
    required this.livre,
  });

  final int total;
  final int enAttente;
  final int paye;
  final int enTransit;
  final int arrive;
  final int livre;

  factory ColisStats.fromJson(Map<String, dynamic> j) => ColisStats(
    total: (j['total'] ?? 0) as int,
    enAttente: (j['en_attente'] ?? 0) as int,
    paye: (j['paye'] ?? 0) as int,
    enTransit: (j['en_transit'] ?? 0) as int,
    arrive: (j['arrive'] ?? 0) as int,
    livre: (j['livre'] ?? 0) as int,
  );
}
