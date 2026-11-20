import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import '../state/wishlist_provider.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    final wishlist = context.watch<WishlistProvider>();
    final theme = Theme.of(context);

    Widget body;
    if (!signedIn) {
      body = EmptyState(
        icon: Icons.favorite_border,
        title: 'Save items you love',
        message: 'Sign in to keep a wishlist across devices.',
        actionLabel: 'Sign in',
        onAction: () => ensureSignedIn(context),
      );
    } else if (wishlist.isLoading && wishlist.items.isEmpty) {
      body = const LoadingView();
    } else if (wishlist.items.isEmpty) {
      body = const EmptyState(icon: Icons.favorite_border, title: 'Your wishlist is empty', message: 'Tap the heart on any product to save it here.');
    } else {
      body = RefreshIndicator(
        onRefresh: wishlist.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: wishlist.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = wishlist.items[i];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id, initial: p))),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      SizedBox.square(dimension: 80, child: NetImage(p.imageUrl, radius: 10)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 4),
                            PriceRow(price: p.price, mrp: p.mrp, percentOff: p.percentOff),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                                  label: const Text('Move to cart'),
                                  onPressed: !p.inStock
                                      ? null
                                      : () async {
                                          final cart = context.read<CartProvider>();
                                          try {
                                            await wishlist.moveToCart(p.id);
                                            await cart.load();
                                            if (context.mounted) showMessage(context, 'Moved to cart');
                                          } catch (e) {
                                            if (context.mounted) showMessage(context, '$e');
                                          }
                                        },
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    try {
                                      await wishlist.toggle(p);
                                    } catch (e) {
                                      if (context.mounted) showMessage(context, '$e');
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Wishlist')), body: body);
  }
}
