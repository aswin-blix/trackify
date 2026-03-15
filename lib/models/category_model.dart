class CategoryModel {
  final int? id;
  final String name;
  final String colorCode;
  final String iconCode;

  CategoryModel({
    this.id,
    required this.name,
    required this.colorCode,
    required this.iconCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_code': colorCode,
      'icon_code': iconCode,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      colorCode: map['color_code'],
      iconCode: map['icon_code'],
    );
  }
}
