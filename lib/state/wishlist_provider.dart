import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/json.dart';
import '../models/product.dart';

/// The signed-in user's wishlist.
class WishlistProvider extends ChangeNotifier {
  WishlistProvider(this._api);

  final ApiClient _api;

  List<Product> _items = const [];
  final Set<String> _ids = {};
  bool _loading = false;
  bool _signedIn = false;

  List<Product> get items => _items;
  bool get isLoading => _loading;
  bool contains(String productId) => _ids.contains(productId);

  /// Called from a ProxyProvider during build, so notifications are deferred.
  void onAuthChanged(bool signedIn) {
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    Future.microtask(() {
      if (_signedIn) {
        load();
      } else {
        _items = const [];
        _ids.clear();
        notifyListeners();
      }
    });
  }

  Future<void> load() async {
    if (!_signedIn) return;
    _loading = true;
    notifyListeners();
    try {
      final data = asMap(await _api.get('/user/wishlist'));
      _items = asList(data['items'])
          .whereType<Map>()
          .map((e) => e['productId'])
          .whereType<Map>()
          .map((p) => Product.fromJson(Map<String, dynamic>.from(p)))
          .toList();
      _ids
        ..clear()
        ..addAll(_items.map((p) => p.id));
    } on ApiException {
      // Leave the current list in place.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Adds or removes a product; updates the UI immediately and rolls back on failure.
  Future<void> toggle(Product product) async {
    final adding = !_ids.contains(product.id);
    if (adding) {
      _ids.add(product.id);
      _items = [..._items, product];
    } else {
      _ids.remove(product.id);
      _items = _items.where((p) => p.id != product.id).toList();
    }
    notifyListeners();
    try {
      if (adding) {
        await _api.post('/user/wishlist/add', {'productId': product.id});
      } else {
        await _api.delete('/user/wishlist/delete/${product.id}');
      }
    } on ApiException {
      await load();
      rethrow;
    }
  }

  Future<void> moveToCart(String productId) async {
    await _api.post('/user/wishlist/move-to-cart/$productId');
    await load();
  }
}
