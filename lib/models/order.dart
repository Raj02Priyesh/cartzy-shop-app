import 'json.dart';
import 'product.dart';

class OrderItem {
  const OrderItem({required this.productId, required this.quantity, required this.price, this.product});

  final String productId;
  final int quantity;
  final double price;
  final Product? product;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final ref = json['productId'];
    return OrderItem(
      productId: refId(ref) ?? '',
      quantity: asInt(json['quantity']),
      price: asDouble(json['price']),
      product: ref is Map ? Product.fromJson(Map<String, dynamic>.from(ref)) : null,
    );
  }
}

/// One step of the delivery timeline.
class TrackingStep {
  const TrackingStep(this.label, this.date, {required this.done});

  final String label;
  final DateTime? date;
  final bool done;
}

class Order {
  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.shipTo,
    required this.shipPhone,
    required this.shipAddress,
    this.orderDate,
    this.processingDate,
    this.shippedDate,
    this.outForDeliveryDate,
    this.deliveredDate,
    this.estimatedDelivery,
    this.deliveryAgentName,
    this.deliveryAgentContact,
  });

  static const statuses = ['Pending', 'Processing', 'Shipped', 'Out for Delivery', 'Delivered'];

  final String id;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String paymentStatus;
  final String shipTo;
  final String shipPhone;
  final String shipAddress;
  final DateTime? orderDate;
  final DateTime? processingDate;
  final DateTime? shippedDate;
  final DateTime? outForDeliveryDate;
  final DateTime? deliveredDate;
  final DateTime? estimatedDelivery;
  final String? deliveryAgentName;
  final String? deliveryAgentContact;

  bool get isCancelled => status == 'Cancelled';
  bool get canCancel => status == 'Pending';
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Short, human-friendly order number.
  String get shortId => id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();

  List<TrackingStep> get timeline {
    final reached = statuses.indexOf(status);
    final dates = [orderDate, processingDate, shippedDate, outForDeliveryDate, deliveredDate];
    const labels = ['Order placed', 'Processing', 'Shipped', 'Out for delivery', 'Delivered'];
    return List.generate(labels.length, (i) => TrackingStep(labels[i], dates[i], done: i <= reached || dates[i] != null));
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final ship = asMap(json['shippingAddress']);
    final tracking = asMap(json['trackingDetails']);
    final agent = asMap(json['deliveryAgent']);
    final addressParts = [ship['street'], ship['branch'], ship['city'], ship['state'], ship['zipCode']]
        .where((p) => p != null && '$p'.isNotEmpty)
        .join(', ');
    return Order(
      id: asString(json['_id'] ?? json['orderId']),
      items: asList(json['items'])
          .whereType<Map>()
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: asDouble(json['totalAmount']),
      status: asString(json['status'], 'Pending'),
      paymentStatus: asString(json['paymentStatus'], 'Unpaid'),
      shipTo: asString(ship['name']),
      shipPhone: asString(ship['phone']),
      shipAddress: addressParts,
      orderDate: asDate(json['orderDate'] ?? json['createdAt']),
      processingDate: asDate(tracking['processingDate']),
      shippedDate: asDate(tracking['shippedDate']),
      outForDeliveryDate: asDate(tracking['outForDeliveryDate']),
      deliveredDate: asDate(tracking['deliveredDate']),
      estimatedDelivery: asDate(tracking['estimatedDelivery']),
      deliveryAgentName: agent['name']?.toString(),
      deliveryAgentContact: agent['contact']?.toString(),
    );
  }
}
