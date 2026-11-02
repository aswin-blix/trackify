import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_model.dart';
import '../../core/constants/app_constants.dart';

class RecurringRepository {
  Box<RecurringModel> get _box => Hive.box<RecurringModel>(kRecurringBox);

  /// Active rules first, then by next due date.
  List<RecurringModel> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) {
      if (a.active != b.active) return a.active ? -1 : 1;
      return a.nextDate.compareTo(b.nextDate);
    });
    return list;
  }

  RecurringModel? getById(String id) => _box.get(id);

  Future<void> save(RecurringModel rule) async => _box.put(rule.id, rule);

  Future<void> delete(String id) async => _box.delete(id);

  Future<void> deleteAll() async => _box.clear();
}
