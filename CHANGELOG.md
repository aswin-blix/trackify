# Changelog

All notable changes to Trackify are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2025-03-30

### Added
- Transaction tracking — add income, expenses, and transfers with categories, notes, and tags
- Dashboard with monthly summary, balance card, and recent transactions
- Analytics screen — bar charts, pie charts, and trend breakdown by period (week / month / year)
- Budget tracking — set monthly budgets per category with live progress indicators
- SMS Bank Reader — auto-reads bank transaction SMS (100% local, never uploaded), parses amount, merchant, and type, lets you add them as transactions in one tap
- App Lock — biometric / device PIN gate on app open and on background resume
- Backup & Restore — export full data as JSON and restore from file
- Auto Backup — scheduled daily backup with configurable retention
- Dark / Light / System theme with immediate apply
- Multi-currency support (INR, USD, EUR, GBP, JPY, AUD, CAD, SGD, AED)
- Custom categories with icons and budget limits
- Glassmorphism UI with smooth spring animations
- Onboarding flow
- Daily reminder notifications
- Financial tips screen
- 100% offline — zero data collection, zero network calls

### Technical
- State: `flutter_riverpod` StateNotifierProvider pattern
- Database: Hive with hand-written type adapters (no build_runner dependency at runtime)
- Charts: `fl_chart` v0.68
- Animations: `flutter_animate` + `animations`
- Typography: Google Fonts — Plus Jakarta Sans
