import 'package:flutter/material.dart';

// ─── Hive Box Names ───────────────────────────────────────────────────────────
const String kTransactionsBox = 'transactions';
const String kCategoriesBox = 'categories';
const String kSmsMessagesBox = 'sms_messages';
const String kSettingsBox = 'settings';
const String kTipsFavoritesBox = 'tips_favorites';
const String kAccountsBox = 'accounts';
const String kRecurringBox = 'recurring';

// ─── Hive Type IDs ────────────────────────────────────────────────────────────
const int kTransactionTypeId = 0;
const int kCategoryTypeId = 1;
const int kBankSmsMessageTypeId = 2;
const int kAppSettingsTypeId = 3;
const int kTransactionTypeEnumId = 4;
const int kSmsStatusEnumId = 5;
const int kCategoryTypeEnumId = 6;
const int kAccountTypeId = 7;
const int kAccountTypeEnumId = 8;
const int kRecurringTypeId = 9;

// ─── Animation Constants ──────────────────────────────────────────────────────
const SpringDescription kSpringFast =
    SpringDescription(mass: 1, stiffness: 400, damping: 28);
const SpringDescription kSpringBouncy =
    SpringDescription(mass: 1, stiffness: 300, damping: 18);
const SpringDescription kSpringSmooth =
    SpringDescription(mass: 1, stiffness: 200, damping: 24);

const Duration kDurationFast = Duration(milliseconds: 220);
const Duration kDurationMed = Duration(milliseconds: 380);
const Duration kDurationSlow = Duration(milliseconds: 560);

const Curve kCurveSnap = Curves.easeOutExpo;
const Curve kCurveSoft = Curves.easeInOutCubic;
const Curve kCurveBounce = Curves.elasticOut;

// ─── App Info ─────────────────────────────────────────────────────────────────
const String kAppName = 'Trackify';
// Keep in sync with the version in pubspec.yaml.
const String kAppVersion = '1.5.0';
// 2: backups carry an `accounts` list and transactions carry accountId.
// 3: backups carry a `recurring` list of scheduled-transaction rules.
const int kBackupSchemaVersion = 3;
const String kBackupFolder = 'TrackifyBackups';

// ─── Accounts ─────────────────────────────────────────────────────────────────
// Fixed ids for the two starter accounts. Transactions with a null accountId
// belong to the default account (normally kDefaultAccountId).
const String kDefaultAccountId = 'acc_bank';
const String kCashAccountId = 'acc_cash';

// ─── Supported Currencies ─────────────────────────────────────────────────────
const List<Map<String, String>> kCurrencies = [
  {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
  {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
  {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
  {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
];

// ─── Known Bank SMS Senders ───────────────────────────────────────────────────
// Brand part of DLT headers ("JX-SBIUPI-S" -> "SBIUPI"). Messages from these
// are trusted; other alphanumeric senders are still scanned but must also
// mention an account, card or wallet. Matching is a substring test.
const List<String> kDefaultBankSenders = [
  // SBI uses a different header per channel.
  'SBIUPI', 'SBIINB', 'CBSSBI', 'ATMSBI', 'SBIBNK', 'SBICRD', 'SBIPSG',
  'SBYONO',
  'HDFCBK', 'ICICIB', 'ICICIT', 'AXISBK', 'KOTAKB', 'INDUSB', 'YESBNK',
  'IDFCFB', 'FEDBNK', 'AUBANK', 'RBLBNK', 'BOBTXN', 'BOBSMS', 'CANBNK',
  'PNBSMS', 'BOIIND', 'UNIONB', 'IOBCHN', 'INDBNK', 'UCOBNK', 'CENTBK',
  'SIBSMS', 'KVBANK', 'CUBANK', 'SCBANK', 'CITIBK', 'HSBCIN', 'DBSBNK',
  'IDBIBK', 'JKBANK', 'KBLBNK', 'EQUTAS', 'UJJIVN', 'AIRBNK', 'FINOBK',
  'PAYTMB', 'JUPITR', 'FIMONY', 'ONECRD',
  'PAYTM', 'PHONPE', 'GPAY', 'AMAZON', 'AMZNPY', 'MOBIKW', 'CRED',
];

// ─── Notification IDs ─────────────────────────────────────────────────────────
const int kDailyReminderNotifId = 1;
const int kWeeklySummaryNotifId = 2;
const int kBudgetAlertNotifId = 3;
const int kTestNotifId = 99;
