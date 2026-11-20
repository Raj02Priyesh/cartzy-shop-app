import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/catalog_service.dart';
import '../state/cart_provider.dart';
import '../state/wishlist_provider.dart';
import '../theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId, this.initial});

  final String productId;

  /// Shown immediately while the full details load.
  final Product? initial;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> _future = context.read<CatalogService>().product(widget.productId);
  late final Future<List<Product>> _similar =
      context.read<CatalogService>().similar(widget.productId).catchError((_) => <Product>[]);
  final _pages = PageController();
  int _page = 0;
  bool _adding = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _addToCart(Product product) async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    setState(() => _adding = true);
    try {
      await context.read<CartProvider>().add(product.id);
      if (mounted) {
        showMessage(
          context,
          'Added to cart',
          actionLabel: 'View cart',
          onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen(standalone: true))),
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _future,
      initialData: widget.initial,
      builder: (context, snap) {
        final product = snap.data;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: snap.hasError
                ? ErrorRetry(
                    message: '${snap.error}',
                    onRetry: () => setState(() => _future = context.read<CatalogService>().product(widget.productId)),
                  )
                : const LoadingView(),
          );
        }
        return _buildProduct(context, product);
      },
    );
  }

  Widget _buildProduct(BuildContext context, Product p) {
    final theme = Theme.of(context);
    final wished = context.select<WishlistProvider, bool>((w) => w.contains(p.id));
    final inCart = context.select<CartProvider, int>((c) => c.quantityOf(p.id));
    final images = p.images.isEmpty ? <String?>[null] : p.images;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: wished ? 'Remove from wishlist' : 'Add to wishlist',
            icon: Icon(wished ? Icons.favorite : Icons.favorite_border, color: wished ? Colors.redAccent : null),
            onPressed: () => toggleWishlist(context, p),
          ),
        ],
      ),
      body: ListView(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pages,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => NetImage(images[i]),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _page ? theme.colorScheme.primary : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.brandName != null || p.categoryName != null)
                  Text(
                    [p.brandName, p.categoryName].whereType<String>().join(' · '),
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                  ),
                const SizedBox(height: 4),
                Text(p.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (p.rating > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: dealColor, borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            const Icon(Icons.star, size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${p.ratingCount} ratings', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                PriceRow(price: p.price, mrp: p.mrp, percentOff: p.percentOff, large: true),
                Text('Inclusive of all taxes', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 10),
                _StockChip(product: p),
                const SizedBox(height: 20),
                Text('About this item', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(p.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                if (p.specifications.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Specifications', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Card(
                    child: Column(
                      children: [
                        for (final e in p.specifications.entries)
                          ListTile(
                            dense: true,
                            title: Text(_label(e.key), style: TextStyle(color: theme.colorScheme.outline)),
                            trailing: Text(_label(e.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const _Perks(),
              ],
            ),
          ),
          FutureBuilder<List<Product>>(
            future: _similar,
            builder: (context, snap) {
              final similar = snap.data ?? const [];
              if (similar.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('You may also like'),
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: similar.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ProductCard(product: similar[i], width: 170),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (inCart > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text('In cart ($inCart)'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen(standalone: true))),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  icon: _adding
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(p.inStock ? (inCart > 0 ? 'Add more' : 'Add to cart') : 'Out of stock'),
                  onPressed: (!p.inStock || _adding) ? null : () => _addToCart(p),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (text, color) = !product.inStock
        ? ('Out of stock', theme.colorScheme.error)
        : product.stock <= 5
            ? ('Only ${product.stock} left — order soon', Colors.orange.shade800)
            : ('In stock', dealColor);
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Perks extends StatelessWidget {
  const _Perks();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget perk(IconData icon, String text) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(text, textAlign: TextAlign.center, style: theme.textTheme.labelSmall),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            perk(Icons.local_shipping_outlined, 'Free delivery'),
            perk(Icons.payments_outlined, 'Cash on delivery'),
            perk(Icons.assignment_return_outlined, '14-day returns'),
          ],
        ),
      ),
    );
  }
}
