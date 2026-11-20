import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order> _future = context.read<OrderService>().order(widget.orderId);
  bool _cancelling = false;

  void _reload() => setState(() => _future = context.read<OrderService>().order(widget.orderId));

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep order')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel order')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await context.read<OrderService>().cancel(widget.orderId);
      if (mounted) {
        showMessage(context, 'Order cancelled');
        _reload();
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Order>(
      future: _future,
      builder: (context, snap) {
        final order = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(order == null ? 'Order' : 'Order #${order.shortId}')),
          body: snap.connectionState != ConnectionState.done
              ? const LoadingView()
              : snap.hasError
                  ? ErrorRetry(message: '${snap.error}', onRetry: _reload)
                  : RefreshIndicator(onRefresh: () async => _reload(), child: _body(context, order!)),
          bottomNavigationBar: (order != null && order.canCancel)
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: OutlinedButton(
                      onPressed: _cancelling ? null : _cancel,
                      child: _cancelling
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Cancel order'),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _body(BuildContext context, Order o) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                    StatusChip(status: o.status),
                  ],
                ),
                if (o.estimatedDelivery != null && !o.isCancelled && o.deliveredDate == null) ...[
                  const SizedBox(height: 6),
                  Text('Expected by ${formatDate(o.estimatedDelivery!)}', style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 14),
                if (o.isCancelled)
                  Row(
                    children: [
                      Icon(Icons.cancel, color: theme.colorScheme.error),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('This order was cancelled.')),
                    ],
                  )
                else
                  _Timeline(steps: o.timeline),
                if (o.deliveryAgentName != null && o.deliveryAgentName!.isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.delivery_dining_outlined),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${o.deliveryAgentName}${o.deliveryAgentContact != null ? ' · ${o.deliveryAgentContact}' : ''}')),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text('Items (${o.itemCount})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              for (final item in o.items)
                ListTile(
                  leading: SizedBox.square(dimension: 48, child: NetImage(item.product?.imageUrl, radius: 8)),
                  title: Text(item.product?.name ?? 'Product no longer available', maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('Qty ${item.quantity} × ${formatPrice(item.price)}'),
                  trailing: Text(formatPrice(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: item.product == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: item.productId, initial: item.product)),
                          ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                    Text(formatPrice(o.total), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(o.shipTo.isEmpty ? 'Delivery address' : o.shipTo),
                subtitle: Text([o.shipAddress, if (o.shipPhone.isNotEmpty) '+91 ${o.shipPhone}'].join('\n')),
                isThreeLine: o.shipPhone.isNotEmpty,
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Payment'),
                subtitle: Text(o.paymentStatus == 'Paid' ? 'Paid' : 'Cash on delivery (unpaid)'),
              ),
              if (o.orderDate != null)
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Ordered on'),
                  subtitle: Text(formatDateTime(o.orderDate!)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<TrackingStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Icon(
                        steps[i].done ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 22,
                        color: steps[i].done ? dealColor : theme.colorScheme.outlineVariant,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: steps[i + 1].done ? dealColor : theme.colorScheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: steps[i].done ? FontWeight.w700 : FontWeight.w400,
                            color: steps[i].done ? null : theme.colorScheme.outline,
                          ),
                        ),
                        if (steps[i].date != null)
                          Text(formatDateTime(steps[i].date!), style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
