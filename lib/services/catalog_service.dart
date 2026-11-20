import '../core/api_client.dart';
import '../models/catalog.dart';
import '../models/json.dart';
import '../models/product.dart';

/// Read-only catalog endpoints (no login needed).
class CatalogService {
  CatalogService(this._api);

  final ApiClient _api;

  Future<List<HomeBanner>> banners() async {
    final data = await _api.get('/user/home-page/banners');
    return asList(asMap(data)['banners'])
        .whereType<Map>()
        .map((e) => HomeBanner.fromJson(Map<String, dynamic>.from(e)))
        .where((b) => b.image.isNotEmpty)
        .toList();
  }

  Future<List<TopCategory>> topCategories() async {
    final data = await _api.get('/user/home-page/top-categories');
    return asList(asMap(data)['topCategories'])
        .whereType<Map>()
        .map((e) => TopCategory.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.categoryId.isNotEmpty)
        .toList();
  }

  Future<List<Product>> bestSellers() async =>
      Product.listFrom(asMap(await _api.get('/user/home-page/best-selling-products'))['products']);

  Future<List<Product>> allProducts() async => Product.listFrom(asMap(await _api.get('/user/products/all'))['products']);

  Future<List<Category>> categories() async =>
      Category.listFrom(asMap(await _api.get('/user/categories/all'))['categories']);

  Future<List<Product>> byCategory(String categoryId) async =>
      Product.listFrom(asMap(await _api.get('/user/products/category/$categoryId'))['products']);

  Future<Product> product(String id) async =>
      Product.fromJson(asMap(asMap(await _api.get('/user/products/id/$id'))['product']));

  Future<List<Product>> similar(String id) async =>
      Product.listFrom(asMap(await _api.get('/user/products/similar/$id'))['products']);

  Future<List<Product>> search(String query) async {
    final q = Uri.encodeQueryComponent(query.trim());
    return Product.listFrom(asMap(await _api.get('/user/products/search?query=$q'))['products']);
  }
}
