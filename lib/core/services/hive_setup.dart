import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/account_model.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/bank_sms_message.dart';
import '../../data/models/category_model.dart';
import '../../data/models/recurring_model.dart';
import '../../data/models/transaction_model.dart';
import '../constants/app_constants.dart';

/// Hive bootstrap shared by the app and the background backup isolate, so
/// both register the same adapters and open the same boxes.
class HiveSetup {
  const HiveSetup._();

  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(kTransactionTypeEnumId)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(kTransactionTypeId)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(kCategoryTypeEnumId)) {
      Hive.registerAdapter(CategoryTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(kCategoryTypeId)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(kSmsStatusEnumId)) {
      Hive.registerAdapter(SmsStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(kBankSmsMessageTypeId)) {
      Hive.registerAdapter(BankSmsMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(kAppSettingsTypeId)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(kAccountTypeEnumId)) {
      Hive.registerAdapter(AccountTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(kAccountTypeId)) {
      Hive.registerAdapter(AccountModelAdapter());
    }
    if (!Hive.isAdapterRegistered(kRecurringTypeId)) {
      Hive.registerAdapter(RecurringModelAdapter());
    }
  }

  /// Opens every box the app uses.
  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<TransactionModel>(kTransactionsBox),
      Hive.openBox<CategoryModel>(kCategoriesBox),
      Hive.openBox<BankSmsMessage>(kSmsMessagesBox),
      Hive.openBox<AppSettings>(kSettingsBox),
      Hive.openBox<bool>(kTipsFavoritesBox),
      Hive.openBox<AccountModel>(kAccountsBox),
      Hive.openBox<RecurringModel>(kRecurringBox),
    ]);
  }

  /// Opens only the boxes a backup snapshot reads.
  static Future<void> openBackupBoxes() async {
    await Future.wait([
      Hive.openBox<TransactionModel>(kTransactionsBox),
      Hive.openBox<CategoryModel>(kCategoriesBox),
      Hive.openBox<AppSettings>(kSettingsBox),
      Hive.openBox<AccountModel>(kAccountsBox),
      Hive.openBox<RecurringModel>(kRecurringBox),
    ]);
  }
}
