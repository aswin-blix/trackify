# Changelog

All notable changes to Trackify are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.1.0] — 2026-03-30

### Fixed
- **Week analytics showing 0** — "Week" tab now uses a rolling last-7-days window instead of the current Mon–Sun calendar week; transactions are no longer excluded when added before this week's Monday
- **Light mode home page blank top area** — greeting + balance card section now has a distinct accent-gradient header, eliminating the visually empty pale zone at the top
- **Onboarding keyboard overlap** — name input page now uses `SingleChildScrollView` so the `TextField` is never obscured when the keyboard opens
- **Onboarding no back navigation** — back button added; appears on pages 2 and 3 so users can return to previous steps
- **Notification not firing on some devices** — integrated `flutter_timezone` to resolve the correct local timezone at runtime; notifications now fire at the right local time on all devices and regions
- **Notification delivery on aggressive battery-saving ROMs** (OnePlus, Xiaomi, etc.) — upgraded to `Importance.max` / `Priority.max`, added `fullScreenIntent`, `category: reminder`, and `visibility: public`; switched to `inexactAllowWhileIdle` for broader Android compatibility
- **Hive null crash on older records** — `tags` and `knownSenderIds` adapter casts changed to `List?` to handle records written before those fields existed

### Added
- `USE_FULL_SCREEN_INTENT` Android permission for heads-up notification display
- `flutter_timezone` dependency for accurate timezone-aware scheduling

---

## [1.0.0] — 2026-03-30

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
