# Trackify 💸

A personal finance tracker built with Flutter. Stay on top of your income and expenses with a clean, intuitive interface and insightful monthly reports.

---

## Features

- **Dashboard** — View total balance, monthly spending & income at a glance
- **Add / Edit / Delete Transactions** — Log income and expenses with category, date, and notes
- **Swipe to Delete** — Quickly remove transactions with a swipe gesture
- **Monthly Reports** — Visualize spending with a donut chart broken down by category
- **6-Month Overview** — Bar chart comparing income vs expenses over the last 6 months
- **Smart Insights** — Auto-generated tips based on your spending patterns
- **Category Management** — Create, edit, and delete custom categories with icons and colors
- **Profile & Settings** — Edit your name, toggle dark/light theme, and manage your data
- **Persistent Storage** — All data stored locally using SQLite (no account needed)

---

## Screenshots

> Dashboard · Monthly Report · Profile

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Provider |
| Local Database | SQLite (sqflite) |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |
| Settings | SharedPreferences |

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.x`
- Android Studio / VS Code

### Run locally

```bash
git clone https://github.com/AswinBlix/trackify.git
cd trackify
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Developer

**Aswin Blix**

Built with the assistance of:
- [Google Gemini](https://gemini.google.com)
- [Google Stitch](https://stitch.withgoogle.com)
- [Antigravity](https://antigravity.dev)
- [Claude AI](https://claude.ai) by Anthropic

---

## License

This project is for personal use. All rights reserved © Aswin Blix.
