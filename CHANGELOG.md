# Changelog

All notable changes to Trackify are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.2.0] — 2026-10-31

### Fixed
- **App Lock did not re-lock on resume** — the lifecycle check compared against `paused`, but Flutter ≥ 3.13 passes through `hidden`/`inactive` before `resumed`. The shell now tracks a background flag; biometric prompts are guarded so they don't trigger a re-lock themselves
- **Restore could wipe all data on a bad file** — backup files are now fully parsed and validated before anything is deleted, and a `pre_restore_*.json` snapshot of the current data is written first
- **Swipe-to-edit on the dashboard crashed** — it pushed an unregistered `/add-transaction` route; it now opens the edit sheet
- **Delete "Undo" did nothing** — Undo now re-adds the transaction
- **Reminder fired at the wrong local time outside India** — `flutter_timezone` is now actually used to resolve the IANA zone (DST and half-hour offsets); the UTC-offset mapping is only a fallback
- **Auto Backup toggle did nothing** — when enabled, a backup is now written once per day when the app is opened or resumed
- **Budget and Tips screens were unreachable** — reachable from the dashboard quick actions and the tip card (`/budget`, `/tips`)
- **Editing a transaction dropped its receipt**; receipts and avatars are now copied out of the picker cache into app storage, the avatar renders (was using `AssetImage` for a file path), and receipts show in the detail sheet
- **Clear All Data left stale state** — providers refresh, the SMS cache and scheduled notifications are cleared, and the app returns to onboarding
- **Onboarding toggles** now request the notification/SMS permissions and schedule the reminder immediately instead of waiting for the next launch
- **Backup retention** now prunes by file age in days (it was treating the value as a file count); the newest backup is always kept
- **CSV export** quotes every text field and neutralises spreadsheet formula injection
- Detail sheet no longer crashes when the category list is empty; daily-spending helper honours its `days` argument; SMS sync errors are logged instead of swallowed

### Security / Privacy
- `android:allowBackup="false"` plus `data_extraction_rules.xml` — Android Auto Backup no longer uploads the Hive database (transactions, raw bank SMS) to Google Drive
- Release builds are signed from `android/key.properties` (see `key.properties.example`) with R8 minify/shrink enabled; CI signs from repository secrets and labels debug-signed artifacts
- Removed unneeded permissions: `RECEIVE_SMS`, `CAMERA`, `READ_MEDIA_IMAGES`, `USE_FULL_SCREEN_INTENT`, `requestLegacyExternalStorage`; removed the bogus WorkManager `<service>`
- Reminder notifications no longer use a full-screen intent
- iOS: added Face ID and photo-library usage descriptions

### Changed
- Removed unused dependencies: `workmanager`, `lottie`, `flutter_svg`, `animations`, `sensors_plus`, `crypto`
- Added unit tests for `SmsParser`, `AppFormatters` and CSV escaping; removed the placeholder widget test
- `kAppVersion` now matches `pubspec.yaml`; backup files carry a `schema` field

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
