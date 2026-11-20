import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/order_service.dart';
import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'address_form_screen.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  String? _addressId;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _name = TextEditingController(text: auth.user?.name ?? '');
    _phone = TextEditingController(text: auth.user?.phone ?? '');
    final addresses = auth.addresses;
    if (addresses.isNotEmpty) _addressId = addresses.last.id;
    auth.loadAddresses().then((_) {
      if (!mounted) return;
      final latest = context.read<AuthProvider>().addresses;
      if (_addressId == null && latest.isNotEmpty) setState(() => _addressId = latest.last.id);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _addAddress() async {
    final saved = await Navigator.of(context).push<Address>(MaterialPageRoute(builder: (_) => const AddressFormScreen()));
    if (saved != null && mounted) setState(() => _addressId = saved.id);
  }

  Future<void> _placeOrder() async {
    if (!_form.currentState!.validate()) return;
    if (_addressId == null) {
      showMessage(context, 'Please add a delivery address.');
      return;
    }
    setState(() => _placing = true);
    final orders = context.read<OrderService>();
    final cart = context.read<CartProvider>();
    try {
      final order = await orders.placeOrder(addressId: _addressId!, name: _name.text.trim(), phone: _phone.text.trim());
      cart.clearLocal();
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => _OrderPlacedScreen(order: order)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        showMessage(context, '$e');
        setState(() => _placing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = context.watch<AuthProvider>().addresses;
    final cart = context.watch<CartProvider>().cart;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _Section(
              title: 'Delivery address',
              trailing: TextButton.icon(onPressed: _addAddress, icon: const Icon(Icons.add), label: const Text('Add new')),
              child: addresses.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: OutlinedButton.icon(
                        onPressed: _addAddress,
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Add a delivery address'),
                      ),
                    )
                  : RadioGroup<String>(
                      groupValue: _addressId,
                      onChanged: (v) => setState(() => _addressId = v),
                      child: Column(
                        children: [
                          for (final a in addresses)
                            RadioListTile<String>(
                              value: a.id ?? '',
                              title: Text(a.street),
                              subtitle: Text(a.oneLine),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Contact details',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Receiver name'),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the receiver\'s name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 ', counterText: ''),
                      validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid 10-digit mobile number',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Payment',
              child: ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Cash on delivery'),
                subtitle: const Text('Pay when your order arrives'),
                trailing: Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Order summary',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  children: [
                    for (final item in cart.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text('${item.product?.name ?? 'Item'} × ${item.quantity}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text(formatPrice(item.lineTotal)),
                          ],
                        ),
                      ),
                    const Divider(height: 20),
                    if (cart.savings > 0)
                      Row(children: [
                        const Expanded(child: Text('You save')),
                        Text(formatPrice(cart.savings), style: const TextStyle(color: dealColor, fontWeight: FontWeight.w600)),
                      ]),
                    Row(children: [
                      const Expanded(child: Text('Delivery')),
                      const Text('FREE', style: TextStyle(color: dealColor, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                      Text(formatPrice(cart.total), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: (_placing || cart.isEmpty) ? null : _placeOrder,
            child: _placing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text('Place order · ${formatPrice(cart.total)}'),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  ?trailing,
                ],
              ),
            ),
            child,
          ],
        ),
      );
}

class _OrderPlacedScreen extends StatelessWidget {
  const _OrderPlacedScreen({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 88, color: dealColor),
                const SizedBox(height: 16),
                Text('Order placed!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Order #${order.shortId} · ${formatPrice(order.total)}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Pay with cash when it arrives. You can track it from My orders.',
                    textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
                  ),
                  child: const Text('Track order'),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Continue shopping')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
