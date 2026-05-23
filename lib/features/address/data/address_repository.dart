import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ShippingAddress {
  ShippingAddress({required this.address, required this.type, required this.cargoNom});
  final String address;
  final String type;
  final String cargoNom;

  factory ShippingAddress.fromJson(Map<String, dynamic> j) => ShippingAddress(
    address: (j['address'] ?? '') as String,
    type: (j['type'] ?? 'aerial') as String,
    cargoNom: (j['cargo']?['nom'] ?? '') as String,
  );
}

class AddressRepository {
  AddressRepository(this._api);
  final ApiClient _api;

  /// type = 'aerial' | 'maritime'
  Future<ShippingAddress> get(String type) async {
    final resp = await _api.get('/api/client/shipping-address', query: {'type': type});
    if (resp.statusCode == 404) {
      throw 'Aucune adresse $type configurée pour votre cargo.';
    }
    return ShippingAddress.fromJson(resp.data as Map<String, dynamic>);
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(apiClientProvider));
});

final addressProvider = FutureProvider.autoDispose.family<ShippingAddress, String>((ref, type) {
  return ref.watch(addressRepositoryProvider).get(type);
});
