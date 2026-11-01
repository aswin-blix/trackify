import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account_model.dart';
import '../../core/constants/app_constants.dart';

class AccountRepository {
  Box<AccountModel> get _box => Hive.box<AccountModel>(kAccountsBox);

  List<AccountModel> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  AccountModel? getById(String id) => _box.get(id);

  /// The account flagged as default, falling back to the first one.
  AccountModel? get defaultAccount {
    final all = getAll();
    if (all.isEmpty) return null;
    return all.firstWhere((a) => a.isDefault, orElse: () => all.first);
  }

  Future<void> add(AccountModel account) async {
    await _box.put(account.id, account);
  }

  Future<void> update(AccountModel account) async {
    await _box.put(account.id, account);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Makes [id] the single default account.
  Future<void> setDefault(String id) async {
    for (final a in _box.values) {
      final shouldBe = a.id == id;
      if (a.isDefault != shouldBe) {
        a.isDefault = shouldBe;
        await a.save();
      }
    }
  }

  Future<void> seedDefaults() async {
    if (_box.isEmpty) {
      for (final a in defaultAccounts) {
        await _box.put(a.id, a);
      }
    }
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  ValueListenable<Box<AccountModel>> get listenable => _box.listenable();
}
