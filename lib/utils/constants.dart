import '../models/category_model.dart';

class AppConstants {
  static final List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: 1, // Pre-seeded IDs
      name: 'Rent',
      colorCode: '#135bec', // Primary Blue
      iconCode: 'home',
    ),
    CategoryModel(
      id: 2,
      name: 'Food',
      colorCode: '#39ff14', // Neon Green
      iconCode: 'restaurant',
    ),
    CategoryModel(
      id: 3,
      name: 'Travel',
      colorCode: '#ff7f50', // Coral
      iconCode: 'directions_car',
    ),
    CategoryModel(
      id: 4,
      name: 'Shopping',
      colorCode: '#a855f7', // Purple
      iconCode: 'shopping_bag',
    ),
    CategoryModel(
      id: 5,
      name: 'Others',
      colorCode: '#94a3b8', // Slate grey
      iconCode: 'category',
    ),
  ];
}
