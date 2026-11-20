import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../services/catalog_service.dart';
import '../widgets/common.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future = context.read<CatalogService>().categories();

  void _retry() => setState(() => _future = context.read<CatalogService>().categories());

  void _open(Category c) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductListScreen(title: c.name, load: () => context.read<CatalogService>().byCategory(c.id)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _retry);
          final all = snap.data!;
          final parents = all.where((c) => c.isTopLevel).toList();
          if (parents.isEmpty) {
            return const EmptyState(icon: Icons.category_outlined, title: 'No categories yet');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: parents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final parent = parents[i];
              final children = all.where((c) => c.parentId == parent.id).toList();
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      leading: SizedBox.square(dimension: 52, child: NetImage(parent.image, radius: 12)),
                      title: Text(parent.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      subtitle: Text(children.isEmpty ? 'View all products' : '${children.length} sub-categories'),
                      trailing: children.isEmpty ? const Icon(Icons.chevron_right) : null,
                      onTap: children.isEmpty ? () => _open(parent) : null,
                    ),
                    if (children.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final child in children)
                              ActionChip(
                                avatar: SizedBox.square(dimension: 24, child: ClipOval(child: NetImage(child.image))),
                                label: Text(child.name),
                                onPressed: () => _open(child),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
