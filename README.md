<div align="center">

<img src="docs/assets/logo.png" alt="Trackify Logo" width="100" height="100" style="border-radius:22px"/>

# Trackify

**Track every rupee, own your future.**

A production-grade, offline-first personal finance tracker built with Flutter.
Beautiful glassmorphism UI · Riverpod state · Hive local database · Zero data collection · Optional partner sharing.

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart)](https://dart.dev)
[![CI](https://github.com/aswin-blix/trackify/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/aswin-blix/trackify/actions)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[**Download APK**](../../releases/latest) · [**Landing Page**](https://aswin-blix.github.io/trackify) · [**Report Bug**](../../issues/new?template=bug_report.md) · [**Request Feature**](../../issues/new?template=feature_request.md)

</div>

---

## Features

| | Feature | Description |
|---|---|---|
| 💰 | **Transaction Tracking** | Log income, expenses, and transfers with categories, notes, and tags |
| 🔁 | **Recurring Transactions** | Rent, salary, subscriptions, EMIs: pick Repeat (daily / weekly / monthly / yearly) and due entries are added automatically, catching up missed dates |
| 🤝 | **Lent & Borrowed** | Track money lent to or borrowed from people: running balance per person, partial repayments, due-date reminders. Moves account balances without counting as income or expense |
| 🏦 | **Accounts** | Cash, bank, wallets and cards with opening balances; real total balance and transfers between accounts |
| 📊 | **Analytics** | Bar charts, pie charts, weekly/monthly/yearly breakdowns |
| 🎯 | **Budget Tracking** | Set monthly budgets per category with live progress bars |
| 📱 | **SMS Bank Reader** | Scans bank, card and UPI alerts (SBI, HDFC, ICICI, Axis, Kotak, PhonePe and more) on open; skips OTPs, dues, declines and promotions. 100% local, never uploaded |
| 🔐 | **App Lock** | Biometric / device PIN gate on open and on background resume |
| ☁️ | **Backup & Restore** | Export full data as JSON and restore from file; daily auto-backup runs in the background via WorkManager |
| 👫 | **Shared Tracking** | Optional: one household, one budget, two phones. Each partner's loans are shown on both phones. Google sign-in + Firestore, free tier. See [docs/SHARED_TRACKING_SETUP.md](docs/SHARED_TRACKING_SETUP.md) |
| 🌙 | **Dark / Light Mode** | Instant theme switching, follows system preference |
| 💱 | **Multi-Currency** | INR, USD, EUR, GBP, JPY, AUD, CAD, SGD, AED |
| ✨ | **Glassmorphism UI** | Frosted glass cards with spring animations throughout |
| 🚫 | **Offline First** | Zero network calls and zero telemetry unless you opt in to shared tracking |

---

## Screenshots

> _Screenshots coming soon — contributions welcome!_

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x, Dart 3.x |
| State Management | `flutter_riverpod` (StateNotifierProvider) |
| Local Database | `hive` + `hive_flutter` (generated adapters checked in) |
| Charts | `fl_chart` v1.x |
| Animations | `flutter_animate` |
| Typography | Google Fonts — Plus Jakarta Sans |
| Biometric Auth | `local_auth` |
| SMS Reading | Native `MethodChannel` (`com.blixcode.trackify/sms`) in `MainActivity.kt` |
| Notifications | `flutter_local_notifications`, `flutter_timezone`, `timezone` |
| Background work | `workmanager` (daily auto-backup) |
| File Operations | `path_provider`, `share_plus`, `file_picker` |
| Shared Tracking (optional) | `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.38 (Dart ≥ 3.10)
- Android SDK (for Android builds)
- A physical or virtual Android device

### Clone & Run

```bash
# 1. Clone
git clone https://github.com/aswin-blix/trackify.git
cd trackify

# 2. Install dependencies
flutter pub get

# 3. Run on connected device
flutter run
```

### Build Release APK

```bash
flutter build apk --release --no-tree-shake-icons
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> **Note:** The `--no-tree-shake-icons` flag is required because category icons are stored as integer codepoints in Hive and resolved at runtime via `IconData(codePoint, fontFamily: 'MaterialIcons')`.

### Install on Device (ADB)

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App-wide constants, currencies, default categories
│   ├── theme/          # AppTheme, AppColors, gradients
│   └── utils/          # SmsParser, Recurrence, DebtLedger, balance calculator, formatters
├── data/
│   ├── models/         # Hive models; generated .g.dart adapters checked in (RecurringModel's adapter is hand-written)
│   └── repositories/   # Thin Hive box wrappers
├── features/           # One folder per screen/feature
│   ├── accounts/       # Manage accounts (cash, bank, wallets) and opening balances
│   ├── analytics/
│   ├── app_lock/
│   ├── backup/
│   ├── budget/
│   ├── dashboard/
│   ├── debts/          # Lent & Borrowed: per-person balances, entry sheet, due reminders
│   ├── household/      # Shared tracking: Firebase bootstrap, sync, invite flow
│   ├── onboarding/
│   ├── recurring/      # Recurring rules: list, pause/resume, edit, delete
│   ├── settings/
│   ├── sms/
│   ├── splash/
│   ├── tips/
│   └── transactions/
└── shared/
    ├── providers/      # All Riverpod providers (settings, transactions, categories, accounts, recurring, SMS)
    └── widgets/        # Reusable widgets (GlassCard, TransactionTile, AccountPicker, etc.)
```

---

## Architecture Notes

- **Hive adapters** — the `.g.dart` files are checked in. After changing a `@HiveType` model, run `dart run build_runner build --delete-conflicting-outputs` and review the diff; never change a field number.
- **Settings state** — `AppSettings` is cloned via `fromJson`/`toJson` on every update so Riverpod detects the change. Mutation-in-place won't work.
- **Tab indices** in `HomeShell`: `0`=Dashboard, `1`=Transactions, `2`=FAB (opens sheet), `3`=Analytics, `4`=Settings.
- **Notifications** — `NotificationService.init()` resolves the device IANA timezone with `flutter_timezone` before any `zonedSchedule` call; a fixed UTC-offset zone is only a fallback.
- **App Lock** — `HomeShell` re-locks on resume using a went-to-background flag (not the previous lifecycle state). Wrap any biometric prompt in `AppLockGuard.run` so the system credential screen does not trigger a re-lock.
- **Auto Backup** — a WorkManager periodic job (`core/services/backup_scheduler.dart`) writes the daily backup at the chosen time even when the app is closed. The background isolate only reads Hive and writes the file; it never writes a box the app may have open, and the app derives the last-backup time from the newest file. `BackupRepository.runAutoBackupIfDue` still runs on app open/resume as a safety net.
- **Accounts** — balances are never stored. `computeAccountBalances` derives them from each account's opening balance plus every transaction; entries with a null `accountId` belong to the default account, so data from before accounts existed needs no migration.
- **SMS reader** — `MainActivity.kt` exposes a `queryInbox` method that reads only `_id, address, body, date` for the last 90 days on a background thread. `SmsSender` treats DLT headers (`JX-SBIUPI-S`) as company senders and skips personal numbers and `-P` promotional headers; senders outside `kDefaultBankSenders` must also use a bank verb and mention an account or card. `SmsParser` rules are covered by real (anonymised) alerts in `test/sms_parser_test.dart`; add a case there when a new bank format is missed. Messages are deduplicated by SMS id, and pending ones are re-parsed on each scan.
- **Recurring transactions** — a `RecurringModel` rule numbers its occurrences from the start date; `Recurrence.occurrence` computes each one from the start (so the 31st clamps to short months and comes back). `RecurringNotifier.postDue` runs on app open/resume and posts through the normal transaction path with stable ids `rec_<rule>_<n>`, so an occurrence is never added twice and syncs like any entry. Rules stay on the phone that created them (no double posting in a household).
- **Lent & Borrowed** — stored as ordinary transactions with types `lend`, `borrow`, `collect`, `repay` plus `counterparty` and `dueDate`. `DebtLedger.balances` groups them by (owner uid, person) so each partner keeps their own balances while both phones show both. Analytics and budgets only read `expense`/`income`, so loans never appear as spending. When adding a `TransactionType`, append it (Hive stores the index) and handle it in every `switch`; older app versions read unknown types as expenses.
- **Shared tracking** — optional and opt-in. Hive stays the source of truth on each phone; `features/household/household_sync.dart` mirrors transactions, categories, accounts and the budget to Firestore and applies partner changes back (last write wins on `updatedAt`). Receipts, bank SMS, recurring rules, app lock and reminders never leave the phone. Setup in [docs/SHARED_TRACKING_SETUP.md](docs/SHARED_TRACKING_SETUP.md).
- **Restore** — `BackupRepository.parseBackupFile` validates the whole file before any data is cleared, and a `pre_restore_*.json` snapshot is written first.
- **Release signing** — `android/key.properties` (git-ignored, see `android/key.properties.example`). Without it, release builds fall back to the debug key and print a warning.
- **Privacy** — `android:allowBackup` is off and `data_extraction_rules.xml` excludes everything, so the Hive database never reaches Google's cloud backup.
- **Week analytics** — uses a rolling last-7-days window (`today − 6` to `today`), not a Mon–Sun calendar week, so data is always visible regardless of the day of the week.

---

## Permissions (Android)

| Permission | Why |
|---|---|
| `READ_SMS` | SMS Bank Reader — reads the last 90 days of bank alerts locally. Google Play restricts this permission, so the app is distributed as a direct APK |
| `READ_EXTERNAL_STORAGE` (≤ Android 12) | Picking a backup file to restore |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | App Lock |
| `POST_NOTIFICATIONS` | Daily reminder and loan due-date notifications |
| `RECEIVE_BOOT_COMPLETED` | Reschedule notifications after reboot |
| `INTERNET` | Only used by the optional shared-tracking sync (Firebase). No other network calls |

Avatar and receipt images use the system photo picker, which needs no permission.

All permissions are optional. Core tracking works without any of them.

---

## Contributing

Contributions are very welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

1. Fork the repo
2. Create a branch: `git checkout -b feat/your-feature`
3. Commit your changes
4. Open a Pull Request

---

## Roadmap

- [x] Lent & borrowed tracking per person (v1.6.0)
- [x] Recurring / scheduled transactions (v1.5.0)
- [x] SMS reader rewrite for real Indian bank formats (v1.5.0)
- [x] Background auto-backup scheduler (WorkManager, v1.4.0)
- [x] Multi-account support with opening balances and transfers (v1.4.0)
- [x] Shared household tracking for partners (v1.3.0)
- [ ] Encrypt the Hive database at rest (`HiveAesCipher` + platform keystore)
- [ ] Widgets (home screen balance widget)
- [ ] iOS support
- [ ] UPI deep link detection

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">
Made with ❤️ by <a href="https://github.com/aswin-blix">Aswin Blix</a> &amp; <a href="https://claude.ai/code">Claude Code</a> &amp; Antigravity
</div>
