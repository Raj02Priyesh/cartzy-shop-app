import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/catalog_service.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<Product>>? _future;
  String _query = '';

  static const _suggestions = ['phone', 'earbuds', 'shoes', 'shirt', 'laptop', 'coffee'];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  void _search(String value) {
    final q = value.trim();
    setState(() {
      _query = q;
      _future = q.length < 2 ? null : context.read<CatalogService>().search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'Search products',
            isDense: true,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  ),
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: _future == null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Popular searches', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(
                        avatar: const Icon(Icons.trending_up, size: 18),
                        label: Text(s),
                        onPressed: () {
                          _controller.text = s;
                          _search(s);
                        },
                      ),
                  ],
                ),
              ],
            )
          : FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const LoadingView();
                if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: () => _search(_query));
                final results = snap.data!;
                if (results.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'No results for "$_query"',
                    message: 'Try a different word, like "phone" or "shoes".',
                  );
                }
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text('${results.length} results for "$_query"', style: Theme.of(context).textTheme.labelLarge),
                      ),
                    ),
                    ProductSliverGrid(products: results),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            ),
    );
  }
}
