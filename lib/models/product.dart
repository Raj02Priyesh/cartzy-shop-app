import 'json.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.mrp,
    required this.price,
    required this.stock,
    required this.images,
    required this.discountPercent,
    required this.isActive,
    required this.specifications,
    required this.rating,
    required this.ratingCount,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
  });

  final String id;
  final String name;
  final String description;
  final double mrp;
  final double price;
  final int stock;
  final List<String> images;
  final int discountPercent;
  final bool isActive;
  final Map<String, String> specifications;
  final double rating;
  final int ratingCount;
  final String? categoryId;
  final String? categoryName;
  final String? brandId;
  final String? brandName;

  bool get inStock => isActive && stock > 0;
  bool get hasDiscount => mrp > price;
  String? get imageUrl => images.isEmpty ? null : images.first;

  /// Percentage off MRP, preferring the stored discount and falling back to the prices.
  int get percentOff {
    if (discountPercent > 0) return discountPercent;
    if (mrp <= 0 || !hasDiscount) return 0;
    return ((mrp - price) / mrp * 100).round();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final specs = asMap(json['specifications']).map((k, v) => MapEntry(k, asString(v)));
    final ratings = asList(json['ratings']);
    final price = asDouble(json['price']);
    final mrp = asDouble(json['MRP']);
    return Product(
      id: asString(json['_id']),
      name: asString(json['name'], 'Unnamed product'),
      description: asString(json['description']),
      mrp: mrp > 0 ? mrp : price,
      price: price,
      stock: asInt(json['stock']),
      images: asList(json['images']).map((e) => '$e').where((e) => e.isNotEmpty).toList(),
      discountPercent: asInt(asMap(json['discount'])['percentage']),
      isActive: json['isActive'] != false,
      specifications: specs,
      rating: asDouble(json['overallRating']),
      ratingCount: ratings.length,
      categoryId: refId(json['category']),
      categoryName: refName(json['category']),
      brandId: refId(json['brand']),
      brandName: refName(json['brand']),
    );
  }

  static List<Product> listFrom(Object? json) => asList(json)
      .whereType<Map>()
      .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
