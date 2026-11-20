import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../models/cart.dart';
import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import '../theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.standalone = false, this.onShop});

  /// True when pushed as its own route (shows a back button).
  final bool standalone;

  /// Switches to the shopping tab when the cart is empty.
  final VoidCallback? onShop;

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    final cartState = context.watch<CartProvider>();
    final cart = cartState.cart;

    Widget body;
    if (!signedIn) {
      body = EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Your cart is waiting',
        message: 'Sign in to add products and see your cart.',
        actionLabel: 'Sign in',
        onAction: () => ensureSignedIn(context),
      );
    } else if (cartState.isLoading && cart.isEmpty) {
      body = const LoadingView();
    } else if (cartState.error != null && cart.isEmpty) {
      body = ErrorRetry(message: cartState.error!, onRetry: cartState.load);
    } else if (cart.isEmpty) {
      body = EmptyState(
        icon: Icons.remove_shopping_cart_outlined,
        title: 'Your cart is empty',
        message: 'Find something you love and add it here.',
        actionLabel: onShop != null || standalone ? 'Start shopping' : null,
        onAction: () => standalone ? Navigator.of(context).popUntil((r) => r.isFirst) : onShop?.call(),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: cartState.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: cart.items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => i == cart.items.length ? _Summary(cart: cart) : _CartLine(item: cart.items[i]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: standalone,
        title: Text(cart.isEmpty ? 'Cart' : 'Cart (${cart.count})'),
      ),
      body: body,
      bottomNavigationBar: (!signedIn || cart.isEmpty)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatPrice(cart.total), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          if (cart.savings > 0)
                            Text('You save ${formatPrice(cart.savings)}', style: const TextStyle(color: dealColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Checkout')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartLine extends StatefulWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  State<_CartLine> createState() => _CartLineState();
}

class _CartLineState extends State<_CartLine> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final product = item.product;
    final cart = context.read<CartProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: product == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id, initial: product)),
                      ),
              child: SizedBox.square(dimension: 84, child: NetImage(product?.imageUrl, radius: 10)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product?.name ?? 'Product no longer available', maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(formatPrice(item.price), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (product != null && product.mrp > item.price)
                    Text(formatPrice(product.mrp),
                        style: theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough, color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyStepper(
                        quantity: item.quantity,
                        busy: _busy,
                        onMinus: () => _run(() => cart.setQuantity(item.productId, item.quantity - 1)),
                        onPlus: () => _run(() => cart.setQuantity(item.productId, item.quantity + 1)),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _busy ? null : () => _run(() => cart.remove(item.productId)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.quantity, required this.busy, required this.onMinus, required this.onPlus});

  final int quantity;
  final bool busy;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Decrease',
            icon: const Icon(Icons.remove, size: 18),
            // At 1, the separate delete button removes the item.
            onPressed: (busy || quantity <= 1) ? null : onMinus,
          ),
          SizedBox(
            width: 28,
            child: busy
                ? const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                : Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Increase',
            icon: const Icon(Icons.add, size: 18),
            onPressed: busy ? null : onPlus,
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mrpTotal = cart.total + cart.savings;
    Widget row(String label, String value, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.w700) : null)),
              Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            row('Price (${cart.count} ${cart.count == 1 ? 'item' : 'items'})', formatPrice(mrpTotal)),
            if (cart.savings > 0) row('Discount', '− ${formatPrice(cart.savings)}', color: dealColor),
            row('Delivery', 'FREE', color: dealColor),
            const Divider(height: 20),
            row('Total amount', formatPrice(cart.total), bold: true),
          ],
        ),
      ),
    );
  }
}
