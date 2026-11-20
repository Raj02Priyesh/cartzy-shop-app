import 'json.dart';

class Address {
  const Address({
    required this.street,
    required this.city,
    required this.district,
    required this.area,
    required this.locality,
    required this.state,
    required this.pinCode,
    required this.country,
    this.id,
  });

  final String? id;
  final String street;
  final String city;
  final String district;

  /// Stored by the API as `subordinate` (sub-district / taluk).
  final String area;

  /// Stored by the API as `branch` (post office / locality).
  final String locality;
  final String state;
  final String pinCode;
  final String country;

  String get oneLine => [street, locality, city, state, pinCode].where((s) => s.isNotEmpty).join(', ');

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['_id']?.toString(),
        street: asString(json['street']),
        city: asString(json['city']),
        district: asString(json['district']),
        area: asString(json['subordinate']),
        locality: asString(json['branch']),
        state: asString(json['state']),
        pinCode: asString(json['zipCode']),
        country: asString(json['country']),
      );

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'district': district,
        'subordinate': area,
        'branch': locality,
        'state': state,
        'zipCode': pinCode,
        'country': country,
      };

  static List<Address> listFrom(Object? json) => asList(json)
      .whereType<Map>()
      .map((e) => Address.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

class AppUser {
  const AppUser({required this.id, required this.name, required this.email, this.phone});

  final String id;
  final String name;
  final String email;
  final String? phone;

  AppUser copyWith({String? name, String? phone}) =>
      AppUser(id: id, name: name ?? this.name, email: email, phone: phone ?? this.phone);

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: asString(json['_id'] ?? json['id']),
        name: asString(json['name']),
        email: asString(json['email']),
        phone: json['phone']?.toString(),
      );

  Map<String, dynamic> toJson() => {'_id': id, 'name': name, 'email': email, 'phone': phone};
}
