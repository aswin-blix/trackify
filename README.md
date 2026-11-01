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
| 🏦 | **Accounts** | Cash, bank, wallets and cards with opening balances; real total balance and transfers between accounts |
| 📊 | **Analytics** | Bar charts, pie charts, weekly/monthly/yearly breakdowns |
| 🎯 | **Budget Tracking** | Set monthly budgets per category with live progress bars |
| 📱 | **SMS Bank Reader** | Auto-reads bank transaction SMS — 100% local, never uploaded |
| 🔐 | **App Lock** | Biometric / device PIN gate on open and on background resume |
| ☁️ | **Backup & Restore** | Export full data as JSON and restore from file |
| 👫 | **Shared Tracking** | Optional: one household, one budget, two phones. Google sign-in + Firestore, free tier. See [docs/SHARED_TRACKING_SETUP.md](docs/SHARED_TRACKING_SETUP.md) |
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
| SMS Reading | `flutter_sms_inbox` |
| Notifications | `flutter_local_notifications`, `flutter_timezone`, `timezone` |
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
│   └── utils/          # SmsParser, formatters
├── data/
│   ├── models/         # Hive models + hand-written .g.dart adapters
│   └── repositories/   # Thin Hive box wrappers
├── features/           # One folder per screen/feature
│   ├── analytics/
│   ├── app_lock/
│   ├── backup/
│   ├── budget/
│   ├── dashboard/
│   ├── onboarding/
│   ├── settings/
│   ├── sms/
│   ├── splash/
│   ├── tips/
│   └── transactions/
└── shared/
    ├── providers/      # All Riverpod providers (settings, transactions, categories, SMS)
    └── widgets/        # Reusable widgets (GlassCard, TransactionTile, etc.)
```

---

## Architecture Notes

- **Hive adapters** — the `.g.dart` files are checked in. After changing a `@HiveType` model, run `dart run build_runner build --delete-conflicting-outputs` and review the diff; never change a field number.
- **Settings state** — `AppSettings` is cloned via `fromJson`/`toJson` on every update so Riverpod detects the change. Mutation-in-place won't work.
- **Tab indices** in `HomeShell`: `0`=Dashboard, `1`=Transactions, `2`=FAB (opens sheet), `3`=Analytics, `4`=Settings.
- **Notifications** — `NotificationService.init()` resolves the device IANA timezone with `flutter_timezone` before any `zonedSchedule` call; a fixed UTC-offset zone is only a fallback.
- **App Lock** — `HomeShell` re-locks on resume using a went-to-background flag (not the previous lifecycle state). Wrap any biometric prompt in `AppLockGuard.run` so the system credential screen does not trigger a re-lock.
- **Auto Backup** — runs in the foreground: once per day on app open/resume when enabled (`BackupRepository.runAutoBackupIfDue`). There is no background scheduler.
- **Restore** — `BackupRepository.parseBackupFile` validates the whole file before any data is cleared, and a `pre_restore_*.json` snapshot is written first.
- **Release signing** — `android/key.properties` (git-ignored, see `android/key.properties.example`). Without it, release builds fall back to the debug key and print a warning.
- **Privacy** — `android:allowBackup` is off and `data_extraction_rules.xml` excludes everything, so the Hive database never reaches Google's cloud backup.
- **Week analytics** — uses a rolling last-7-days window (`today − 6` to `today`), not a Mon–Sun calendar week, so data is always visible regardless of the day of the week.

---

## Permissions (Android)

| Permission | Why |
|---|---|
| `READ_SMS` | SMS Bank Reader — reads bank transaction messages locally. Google Play restricts this permission, so the app is distributed as a direct APK |
| `READ_EXTERNAL_STORAGE` (≤ Android 12) | Picking a backup file to restore |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | App Lock |
| `POST_NOTIFICATIONS` | Daily reminder notifications |
| `RECEIVE_BOOT_COMPLETED` | Reschedule notifications after reboot |

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

- [ ] Recurring / scheduled transactions
- [ ] Encrypt the Hive database at rest (`HiveAesCipher` + platform keystore)
- [ ] Background auto-backup scheduler (currently runs on app open)
- [ ] Widgets (home screen balance widget)
- [ ] iOS support
- [ ] UPI deep link detection
- [ ] Multi-account support

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">
Made with ❤️ by <a href="https://github.com/aswin-blix">Aswin Blix</a> &amp; <a href="https://claude.ai/code">Claude Code</a> &amp; Antigravity
</div>
