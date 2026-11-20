import 'package:cartzy_shop/models/cart.dart';
import 'package:cartzy_shop/models/catalog.dart';
import 'package:cartzy_shop/models/order.dart';
import 'package:cartzy_shop/models/product.dart';
import 'package:cartzy_shop/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> productJson({Object? category = 'c1', Object? brand}) => {
      '_id': 'p1',
      'name': 'Nova X5 Smartphone',
      'description': 'A phone',
      'category': category,
      'brand': brand,
      'MRP': 24999,
      'price': 21999,
      'discountedPrice': 21999,
      'stock': 3,
      'images': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      'discount': {'percentage': 12},
      'isActive': true,
      'specifications': {'color': 'black', 'ram': '8 GB'},
      'ratings': [
        {'userId': 'u1', 'rating': 5},
      ],
      'overallRating': 5,
    };

void main() {
  group('Product.fromJson', () {
    test('parses prices, images, specs and rating', () {
      final p = Product.fromJson(productJson());
      expect(p.id, 'p1');
      expect(p.mrp, 24999);
      expect(p.price, 21999);
      expect(p.percentOff, 12);
      expect(p.imageUrl, 'https://example.com/a.jpg');
      expect(p.specifications['ram'], '8 GB');
      expect(p.rating, 5);
      expect(p.ratingCount, 1);
      expect(p.inStock, isTrue);
    });

    test('accepts category/brand as an id or a populated object', () {
      expect(Product.fromJson(productJson(category: 'c1')).categoryId, 'c1');
      final populated = Product.fromJson(productJson(
        category: {'_id': 'c2', 'name': 'Mobiles'},
        brand: {'_id': 'b1', 'name': 'Nova'},
      ));
      expect(populated.categoryId, 'c2');
      expect(populated.categoryName, 'Mobiles');
      expect(populated.brandName, 'Nova');
    });

    test('derives percent off from prices when no discount is stored', () {
      final json = productJson()..remove('discount');
      json['MRP'] = 2000;
      json['price'] = 1500;
      expect(Product.fromJson(json).percentOff, 25);
    });

    test('is out of stock when stock is 0 or inactive', () {
      expect(Product.fromJson(productJson()..['stock'] = 0).inStock, isFalse);
      expect(Product.fromJson(productJson()..['isActive'] = false).inStock, isFalse);
    });
  });

  group('Cart.fromJson', () {
    test('parses a populated cart and computes count and savings', () {
      final cart = Cart.fromJson({
        'items': [
          {'productId': productJson(), 'quantity': 2, 'price': 21999},
        ],
        'totalPrice': 43998,
      });
      expect(cart.count, 2);
      expect(cart.total, 43998);
      expect(cart.savings, (24999 - 21999) * 2);
      expect(cart.items.single.product?.name, 'Nova X5 Smartphone');
    });

    test('handles the empty-cart response and deleted products', () {
      expect(Cart.fromJson({'message': 'Cart is empty', 'items': []}).isEmpty, isTrue);
      final cart = Cart.fromJson({
        'items': [
          {'productId': 'gone-id', 'quantity': 1, 'price': 100},
        ],
      });
      expect(cart.items.single.product, isNull);
      expect(cart.total, 100);
      expect(cart.savings, 0);
    });
  });

  group('Order', () {
    test('parses shipping, status and builds the tracking timeline', () {
      final order = Order.fromJson({
        '_id': '6aff5bbe5584ae68a3651578',
        'items': [
          {'productId': productJson(), 'quantity': 1, 'price': 21999},
        ],
        'totalAmount': 21999,
        'status': 'Shipped',
        'paymentStatus': 'Unpaid',
        'shippingAddress': {'name': 'Asha', 'phone': '9876543210', 'street': '1 MG Road', 'city': 'Bengaluru', 'zipCode': '560001'},
        'trackingDetails': {'shippedDate': '2026-11-20T10:00:00.000Z'},
        'orderDate': '2026-11-19T10:00:00.000Z',
      });
      expect(order.shortId, 'A3651578');
      expect(order.canCancel, isFalse);
      expect(order.shipAddress, contains('Bengaluru'));
      final done = order.timeline.where((s) => s.done).map((s) => s.label).toList();
      expect(done, ['Order placed', 'Processing', 'Shipped']);
    });
  });

  test('Address maps app field names to API field names', () {
    const address = Address(
      street: '1 MG Road',
      city: 'Bengaluru',
      district: 'Bengaluru Urban',
      area: 'Bengaluru South',
      locality: 'Koramangala',
      state: 'Karnataka',
      pinCode: '560034',
      country: 'India',
    );
    final json = address.toJson();
    expect(json['subordinate'], 'Bengaluru South');
    expect(json['branch'], 'Koramangala');
    expect(json['zipCode'], '560034');
    expect(Address.fromJson({...json, '_id': 'a1'}).locality, 'Koramangala');
  });

  test('HomeBanner extracts the category id from its link', () {
    final banner = HomeBanner.fromJson({
      'name': 'Sale',
      'image': 'https://example.com/b.jpg',
      'buttonLink': '/category/6aff5bbd5584ae68a3651524',
    });
    expect(banner.categoryId, '6aff5bbd5584ae68a3651524');
  });
}
