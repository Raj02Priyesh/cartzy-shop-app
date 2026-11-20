import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/cart.dart';

/// The signed-in user's cart, kept in sync with the server.
class CartProvider extends ChangeNotifier {
  CartProvider(this._api);

  final ApiClient _api;

  Cart _cart = Cart.empty;
  bool _loading = false;
  bool _signedIn = false;
  String? _error;

  Cart get cart => _cart;
  bool get isLoading => _loading;
  String? get error => _error;
  int get count => _cart.count;

  /// Called whenever the auth state changes (from a ProxyProvider, i.e. during build),
  /// so any listener notification is deferred until after the current frame's build.
  void onAuthChanged(bool signedIn) {
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    Future.microtask(() {
      if (_signedIn) {
        load();
      } else {
        _cart = Cart.empty;
        _error = null;
        notifyListeners();
      }
    });
  }

  Future<void> load() async {
    if (!_signedIn) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cart = Cart.fromJson(await _api.get('/user/cart'));
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  int quantityOf(String productId) {
    for (final item in _cart.items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  Future<void> add(String productId) async {
    await _api.post('/user/cart/add', {'productId': productId});
    await load();
  }

  Future<void> setQuantity(String productId, int quantity) async {
    if (quantity < 1) return remove(productId);
    await _api.put('/user/cart/update', {'productId': productId, 'quantity': quantity});
    await load();
  }

  Future<void> remove(String productId) async {
    await _api.delete('/user/cart/delete/$productId');
    await load();
  }

  /// The server empties the cart when an order is placed.
  void clearLocal() {
    _cart = Cart.empty;
    notifyListeners();
  }
}
