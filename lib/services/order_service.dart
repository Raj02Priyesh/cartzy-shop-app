import '../core/api_client.dart';
import '../models/json.dart';
import '../models/order.dart';

class OrderService {
  OrderService(this._api);

  final ApiClient _api;

  /// Places a cash-on-delivery order for everything in the cart.
  Future<Order> placeOrder({required String addressId, required String name, required String phone}) async {
    final data = await _api.post('/user/orders/place', {
      'addressId': addressId,
      'name': name,
      'phone': phone,
      'paymentMethod': 'COD',
    });
    return Order.fromJson(asMap(asMap(data)['order']));
  }

  Future<List<Order>> myOrders() async {
    final data = await _api.get('/user/orders');
    final orders = asList(data)
        .whereType<Map>()
        .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    orders.sort((a, b) => (b.orderDate ?? DateTime(0)).compareTo(a.orderDate ?? DateTime(0)));
    return orders;
  }

  Future<Order> order(String id) async => Order.fromJson(asMap(await _api.get('/user/orders/$id')));

  Future<void> cancel(String id) => _api.put('/user/orders/cancel/$id');
}
