import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

enum _Sort { relevance, priceLow, priceHigh, discount }

/// A titled grid of products, loaded by [load], with sorting.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.title, required this.load});

  final String title;
  final Future<List<Product>> Function() load;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _future = widget.load();
  _Sort _sort = _Sort.relevance;

  List<Product> _sorted(List<Product> items) {
    final list = [...items];
    switch (_sort) {
      case _Sort.relevance:
        break;
      case _Sort.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
      case _Sort.discount:
        list.sort((a, b) => b.percentOff.compareTo(a.percentOff));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<_Sort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.relevance, child: Text('Relevance')),
              PopupMenuItem(value: _Sort.priceLow, child: Text('Price: low to high')),
              PopupMenuItem(value: _Sort.priceHigh, child: Text('Price: high to low')),
              PopupMenuItem(value: _Sort.discount, child: Text('Biggest discount')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            return ErrorRetry(message: '${snap.error}', onRetry: () => setState(() => _future = widget.load()));
          }
          final products = _sorted(snap.data!);
          if (products.isEmpty) {
            return const EmptyState(icon: Icons.inventory_2_outlined, title: 'Nothing here yet', message: 'Check back soon for new products.');
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text('${products.length} products', style: Theme.of(context).textTheme.labelLarge),
                ),
              ),
              ProductSliverGrid(products: products),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
