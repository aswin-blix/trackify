import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../../core/constants/app_constants.dart';

class SettingsRepository {
  static const String _settingsKey = 'app_settings';

  Box<AppSettings> get _box => Hive.box<AppSettings>(kSettingsBox);

  AppSettings get settings {
    return _box.get(_settingsKey) ?? AppSettings();
  }

  Future<void> save(AppSettings settings) async {
    await _box.put(_settingsKey, settings);
  }

  Future<void> updateField(void Function(AppSettings) updater) async {
    final current = settings;
    updater(current);
    await _box.put(_settingsKey, current);
  }

  Future<void> reset() async {
    await _box.put(_settingsKey, AppSettings());
  }

  ValueListenable<Box<AppSettings>> get listenable => _box.listenable();
}
