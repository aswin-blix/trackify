import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_model.dart';
import '../../core/constants/app_constants.dart';

class CategoryRepository {
  Box<CategoryModel> get _box => Hive.box<CategoryModel>(kCategoriesBox);

  List<CategoryModel> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  List<CategoryModel> getByType(CategoryType type) {
    return getAll()
        .where((c) => c.type == type || c.type == CategoryType.both)
        .toList();
  }

  CategoryModel? getById(String id) {
    return _box.get(id);
  }

  Future<void> add(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> update(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> reorder(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final cat = _box.get(orderedIds[i]);
      if (cat != null) {
        cat.sortOrder = i;
        await cat.save();
      }
    }
  }

  Future<void> seedDefaults() async {
    if (_box.isEmpty) {
      for (final cat in defaultCategories) {
        await _box.put(cat.id, cat);
      }
    }
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  ValueListenable<Box<CategoryModel>> get listenable => _box.listenable();
}
