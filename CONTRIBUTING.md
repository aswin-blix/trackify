# Contributing to Trackify

Thank you for taking the time to contribute! Here's how to get started.

---

## Getting Started

1. Fork the repository and clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/trackify.git
   cd trackify
   ```

2. Install Flutter (≥ 3.38): https://docs.flutter.dev/get-started/install

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run on a connected device or emulator:
   ```bash
   flutter run
   ```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/     # App-wide constants, currencies, default data
│   ├── theme/         # AppTheme, AppColors, gradients
│   └── utils/         # SmsParser, Recurrence, DebtLedger, formatters
├── data/
│   ├── models/        # Hive models; generated .g.dart adapters checked in
│   └── repositories/  # Thin Hive box wrappers
├── features/          # One folder per screen/feature
│   ├── accounts/
│   ├── analytics/
│   ├── app_lock/
│   ├── backup/
│   ├── budget/
│   ├── dashboard/
│   ├── debts/         # Lent & Borrowed
│   ├── household/     # Optional shared tracking
│   ├── onboarding/
│   ├── recurring/
│   ├── settings/
│   ├── sms/
│   ├── splash/
│   ├── tips/
│   └── transactions/
└── shared/
    ├── providers/     # All Riverpod providers
    └── widgets/       # Reusable widgets
```

### Key Architecture Notes
- **Hive adapters** — the `.g.dart` files are checked in. Only run `dart run build_runner build --delete-conflicting-outputs` after changing a `@HiveType` model, and never reuse a field number.
- **State** uses `StateNotifierProvider`. Settings changes must produce a new `AppSettings` instance (clone via `fromJson`) for Riverpod to detect them.
- **Transaction types** — Hive stores `TransactionType` by index: append new values, never reorder, and handle them in every `switch` (the analyzer flags non-exhaustive ones).
- **SMS formats** — when a bank alert is missed or misread, add the (anonymised) message to `test/sms_parser_test.dart` first, then adjust `SmsParser`.
- **Formatting** — CI runs `dart format --set-exit-if-changed`; run `dart format .` before pushing.
- **App Lock** — wrap any biometric prompt in `AppLockGuard.run` so the system credential screen does not trigger the resume re-lock.
- **Tab indices** in `HomeShell`: 0=Dashboard, 1=Transactions, 2=FAB (opens Add Transaction sheet), 3=Analytics, 4=Settings.

---

## How to Contribute

### Bug Reports
Open a [GitHub Issue](../../issues/new?template=bug_report.md) with:
- Steps to reproduce
- Expected vs actual behaviour
- Device / OS / Flutter version

### Feature Requests
Open a [GitHub Issue](../../issues/new?template=feature_request.md) describing the use case.

### Pull Requests
1. Create a branch: `git checkout -b feat/your-feature` or `fix/your-bug`
2. Make your changes — keep commits focused and descriptive
3. Run the analyzer before submitting: `flutter analyze`
4. Open a PR against `main` and fill in the template

### Commit Message Style
```
feat: add recurring transaction support
fix: settings dark mode not applying immediately
refactor: extract SmsService from settings screen
docs: update contributing guide
```

---

## Code Style
- Follow the existing `analysis_options.yaml` rules
- Use `flutter_lints` recommended rules
- Keep widgets small and composable
- Use `GoogleFonts.plusJakartaSans(...)` for all text — no raw `TextStyle`

---

## License
By contributing you agree that your contributions will be licensed under the [MIT License](LICENSE).
