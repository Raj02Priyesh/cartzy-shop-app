import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../state/wishlist_provider.dart';
import 'auth_gate.dart';
import 'common.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.width});

  final Product product;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wished = context.select<WishlistProvider, bool>((w) => w.contains(product.id));

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id, initial: product)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The image takes whatever height the grid/list slot leaves after the text.
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(product.imageUrl),
                    if (product.percentOff > 0)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${product.percentOff}% OFF',
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        tooltip: wished ? 'Remove from wishlist' : 'Add to wishlist',
                        icon: Icon(wished ? Icons.favorite : Icons.favorite_border, size: 20, color: wished ? Colors.redAccent : null),
                        onPressed: () => toggleWishlist(context, product),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brandName != null)
                      Text(product.brandName!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    PriceRow(price: product.price, mrp: product.mrp, percentOff: 0),
                    if (!product.inStock)
                      Text('Out of stock', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> toggleWishlist(BuildContext context, Product product) async {
  if (!await ensureSignedIn(context)) return;
  if (!context.mounted) return;
  final wishlist = context.read<WishlistProvider>();
  final adding = !wishlist.contains(product.id);
  try {
    await wishlist.toggle(product);
    if (context.mounted) showMessage(context, adding ? 'Saved to wishlist' : 'Removed from wishlist');
  } catch (e) {
    if (context.mounted) showMessage(context, '$e');
  }
}

/// Responsive grid of product cards for use inside a CustomScrollView.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 280,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => ProductCard(product: products[i]),
            childCount: products.length,
          ),
        ),
      );
}
