import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'category_model.g.dart';

@HiveType(typeId: kCategoryTypeEnumId)
enum CategoryType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
  @HiveField(2)
  both,
}

@HiveType(typeId: kCategoryTypeId)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCodePoint;

  @HiveField(3)
  String colorHex;

  @HiveField(4)
  bool isCustom;

  @HiveField(5)
  double? budgetLimit;

  @HiveField(6)
  CategoryType type;

  @HiveField(7)
  int sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
    this.isCustom = false,
    this.budgetLimit,
    this.type = CategoryType.expense,
    this.sortOrder = 0,
  });

  Color get color =>
      Color(int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16));

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  CategoryModel copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? colorHex,
    bool? isCustom,
    double? budgetLimit,
    CategoryType? type,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      isCustom: isCustom ?? this.isCustom,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorHex': colorHex,
        'isCustom': isCustom,
        'budgetLimit': budgetLimit,
        'type': type.name,
        'sortOrder': sortOrder,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorHex: json['colorHex'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
      budgetLimit: (json['budgetLimit'] as num?)?.toDouble(),
      type: CategoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CategoryType.expense,
      ),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

// ─── Default Categories ───────────────────────────────────────────────────────
List<CategoryModel> get defaultCategories => [
      CategoryModel(
        id: 'food',
        name: 'Food & Dining',
        iconCodePoint: Icons.restaurant.codePoint,
        colorHex: '#FF6B6B',
        type: CategoryType.expense,
        sortOrder: 0,
      ),
      CategoryModel(
        id: 'transport',
        name: 'Transport',
        iconCodePoint: Icons.directions_car.codePoint,
        colorHex: '#4ECDC4',
        type: CategoryType.expense,
        sortOrder: 1,
      ),
      CategoryModel(
        id: 'shopping',
        name: 'Shopping',
        iconCodePoint: Icons.shopping_bag.codePoint,
        colorHex: '#FFE66D',
        type: CategoryType.expense,
        sortOrder: 2,
      ),
      CategoryModel(
        id: 'bills',
        name: 'Bills & Utilities',
        iconCodePoint: Icons.receipt_long.codePoint,
        colorHex: '#6C5CE7',
        type: CategoryType.expense,
        sortOrder: 3,
      ),
      CategoryModel(
        id: 'entertainment',
        name: 'Entertainment',
        iconCodePoint: Icons.movie.codePoint,
        colorHex: '#FD79A8',
        type: CategoryType.expense,
        sortOrder: 4,
      ),
      CategoryModel(
        id: 'health',
        name: 'Health',
        iconCodePoint: Icons.favorite.codePoint,
        colorHex: '#00B894',
        type: CategoryType.expense,
        sortOrder: 5,
      ),
      CategoryModel(
        id: 'salary',
        name: 'Salary',
        iconCodePoint: Icons.account_balance_wallet.codePoint,
        colorHex: '#00CEC9',
        type: CategoryType.income,
        sortOrder: 6,
      ),
      CategoryModel(
        id: 'freelance',
        name: 'Freelance',
        iconCodePoint: Icons.laptop_mac.codePoint,
        colorHex: '#55EFC4',
        type: CategoryType.income,
        sortOrder: 7,
      ),
      CategoryModel(
        id: 'investment',
        name: 'Investment',
        iconCodePoint: Icons.trending_up.codePoint,
        colorHex: '#0984E3',
        type: CategoryType.both,
        sortOrder: 8,
      ),
      CategoryModel(
        id: 'others',
        name: 'Others',
        iconCodePoint: Icons.more_horiz.codePoint,
        colorHex: '#636E72',
        type: CategoryType.both,
        sortOrder: 9,
      ),
    ];
