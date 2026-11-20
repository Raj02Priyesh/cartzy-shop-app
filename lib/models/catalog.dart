import 'json.dart';

class Category {
  const Category({required this.id, required this.name, this.parentId, this.image});

  final String id;
  final String name;
  final String? parentId;
  final String? image;

  bool get isTopLevel => parentId == null;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: asString(json['_id']),
        name: asString(json['name']),
        parentId: refId(json['parent']),
        image: json['image']?.toString(),
      );

  static List<Category> listFrom(Object? json) => asList(json)
      .whereType<Map>()
      .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

class HomeBanner {
  const HomeBanner({required this.title, required this.image, this.text, this.buttonText, this.buttonLink});

  final String title;
  final String image;
  final String? text;
  final String? buttonText;
  final String? buttonLink;

  /// Banner links look like `/category/<id>`; returns that id when present.
  String? get categoryId {
    final match = RegExp(r'/category/([a-f0-9]{24})').firstMatch(buttonLink ?? '');
    return match?.group(1);
  }

  factory HomeBanner.fromJson(Map<String, dynamic> json) => HomeBanner(
        title: asString(json['name']),
        image: asString(json['image']),
        text: json['text']?.toString(),
        buttonText: json['buttonText']?.toString(),
        buttonLink: json['buttonLink']?.toString(),
      );
}

class TopCategory {
  const TopCategory({required this.name, required this.categoryId, this.image});

  final String name;
  final String categoryId;
  final String? image;

  factory TopCategory.fromJson(Map<String, dynamic> json) => TopCategory(
        name: asString(json['name']),
        categoryId: refId(json['categoryId']) ?? '',
        image: json['image']?.toString(),
      );
}
