/// Représentation de l'utilisateur connecté (extrait de UserResource côté API).
class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    required this.status,
    this.cargoId,
    this.cargo,
    this.paysId,
    this.ville,
    this.locale = 'fr',
    this.emailVerified = false,
    this.phoneVerified = false,
    this.needsProfileCompletion = false,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;            // client | partner | sub_admin | super_admin
  final String status;          // active | pending_email | suspended | ...
  final int? cargoId;
  final CargoSummary? cargo;
  final int? paysId;
  final String? ville;
  final String locale;
  final bool emailVerified;
  final bool phoneVerified;
  final bool needsProfileCompletion;

  bool get isClient => role == 'client';

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'] as int,
    name: (j['name'] ?? '') as String,
    email: (j['email'] ?? '') as String,
    phone: j['phone'] as String?,
    avatar: j['avatar'] as String?,
    role: (j['role'] ?? 'client') as String,
    status: (j['status'] ?? 'active') as String,
    cargoId: j['cargo_id'] as int?,
    cargo: j['cargo'] is Map ? CargoSummary.fromJson(j['cargo'] as Map<String, dynamic>) : null,
    paysId: j['pays_id'] as int?,
    ville: j['ville'] as String?,
    locale: (j['locale'] ?? 'fr') as String,
    emailVerified: (j['email_verified'] ?? false) as bool,
    phoneVerified: (j['phone_verified'] ?? false) as bool,
    needsProfileCompletion: (j['needs_profile_completion'] ?? false) as bool,
  );
}

class CargoSummary {
  CargoSummary({required this.id, required this.nom, this.codePrefix, this.status});
  final int id;
  final String nom;
  final String? codePrefix;
  final String? status;

  factory CargoSummary.fromJson(Map<String, dynamic> j) => CargoSummary(
    id: j['id'] as int,
    nom: (j['nom'] ?? '') as String,
    codePrefix: j['code_prefix'] as String?,
    status: j['status'] as String?,
  );
}
