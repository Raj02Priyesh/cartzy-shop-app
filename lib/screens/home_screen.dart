import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/catalog.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';
import 'wishlist_screen.dart';

class _HomeData {
  const _HomeData(this.banners, this.topCategories, this.bestSellers, this.products);

  final List<HomeBanner> banners;
  final List<TopCategory> topCategories;
  final List<Product> bestSellers;
  final List<Product> products;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future = _load();

  Future<_HomeData> _load() async {
    final catalog = context.read<CatalogService>();
    // The all-products call goes first so a sleeping server wakes once, then the rest run in parallel.
    final products = await catalog.allProducts();
    final results = await Future.wait([
      catalog.banners().catchError((_) => <HomeBanner>[]),
      catalog.topCategories().catchError((_) => <TopCategory>[]),
      catalog.bestSellers().catchError((_) => <Product>[]),
    ]);
    return _HomeData(
      results[0] as List<HomeBanner>,
      results[1] as List<TopCategory>,
      results[2] as List<Product>,
      products,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  void _openCategory(String id, String title) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductListScreen(title: title, load: () => context.read<CatalogService>().byCategory(id)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_bag_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(appName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Wishlist',
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
              child: InputDecorator(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), isDense: true),
                child: Text('Search phones, shoes, kettles…', style: TextStyle(color: theme.colorScheme.outline)),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _refresh);
          final data = snap.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                if (data.banners.isNotEmpty)
                  SliverToBoxAdapter(child: _BannerCarousel(banners: data.banners, onOpen: _openCategory)),
                if (data.topCategories.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SectionHeader('Shop by category')),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: data.topCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (_, i) {
                          final c = data.topCategories[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openCategory(c.categoryId, c.name),
                            child: SizedBox(
                              width: 76,
                              child: Column(
                                children: [
                                  SizedBox.square(dimension: 64, child: ClipOval(child: NetImage(c.image))),
                                  const SizedBox(height: 6),
                                  Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                if (data.bestSellers.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SectionHeader('Best sellers')),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: data.bestSellers.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => ProductCard(product: data.bestSellers[i], width: 170),
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SectionHeader('All products')),
                if (data.products.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyState(icon: Icons.inventory_2_outlined, title: 'No products yet'),
                  )
                else
                  ProductSliverGrid(products: data.products),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners, required this.onOpen});

  final List<HomeBanner> banners;
  final void Function(String categoryId, String title) onOpen;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        final next = (_page + 1) % widget.banners.length;
        _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 2.4,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(b.image),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(b.title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                            if (b.text != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(b.text!, maxLines: 2, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                              ),
                            if (b.buttonText != null && b.categoryId != null) ...[
                              const SizedBox(height: 10),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                                onPressed: () => widget.onOpen(b.categoryId!, b.title),
                                child: Text(b.buttonText!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
