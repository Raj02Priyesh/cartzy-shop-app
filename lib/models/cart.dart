import 'json.dart';
import 'product.dart';

class CartItem {
  const CartItem({required this.productId, required this.quantity, required this.price, this.product});

  final String productId;
  final int quantity;

  /// Unit price stored when the item was added.
  final double price;

  /// Populated product details; null if the product has since been deleted.
  final Product? product;

  double get lineTotal => price * quantity;

  /// Amount saved against MRP for this line.
  double get lineSavings {
    final p = product;
    if (p == null || p.mrp <= price) return 0;
    return (p.mrp - price) * quantity;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final ref = json['productId'];
    return CartItem(
      productId: refId(ref) ?? '',
      quantity: asInt(json['quantity']),
      price: asDouble(json['price']),
      product: ref is Map ? Product.fromJson(Map<String, dynamic>.from(ref)) : null,
    );
  }
}

class Cart {
  const Cart({required this.items, required this.total});

  static const empty = Cart(items: [], total: 0);

  final List<CartItem> items;
  final double total;

  int get count => items.fold(0, (sum, i) => sum + i.quantity);
  double get savings => items.fold(0, (sum, i) => sum + i.lineSavings);
  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Object? json) {
    final map = asMap(json);
    final items = asList(map['items'])
        .whereType<Map>()
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
        .where((i) => i.productId.isNotEmpty)
        .toList();
    final total = map.containsKey('totalPrice')
        ? asDouble(map['totalPrice'])
        : items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    return Cart(items: items, total: total);
  }
}
