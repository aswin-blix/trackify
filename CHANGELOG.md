# Changelog

All notable changes to Trackify are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.6.0] — 2026-11-02

### Added
- **Lent & Borrowed** — record money you lend, borrow, get paid back or pay back, per person (Settings → Lent & Borrowed, or the dashboard card). Each person shows a running balance; partial repayments reduce it and a zero balance moves the person to *Settled*. A person screen lists the full history with the balance after each entry, with one-tap *Got paid back* / *Paid back* prefilled with the outstanding amount
- Entries move money in or out of the chosen account but never count as income or expense, so analytics, budgets and monthly totals are unaffected. They appear in History (new *Loans* filter, searchable by name) and the CSV export (person in the Category column)
- Optional due date on a loan, with a 10:00 reminder on that day; reminders are re-synced whenever the app opens, so a loan settled early never pings. Overdue loans are highlighted
- In a shared household each member records their own loans; both phones show both sets, labelled by owner, with an *Everyone / You / partner* filter. Balances are kept per owner
- The SMS inbox's add sheet has a **Loan** option (I lent / I paid back for debits, I borrowed / Paid back to me for credits)

### Notes
- New transaction types are appended to the Hive enum (indexes 3–6) and new fields `counterparty` (15) and `dueDate` (16) are added; existing data is unaffected. Update both phones in a household before recording loans: older versions read the new types as expenses

---

## [1.5.0] — 2026-11-02

### Added
- **Recurring transactions** — pick Repeat (Daily / Weekly / Monthly / Yearly) when adding a transaction, or use Settings → Recurring. Due entries are posted when the app opens or returns to the foreground, catching up any missed dates. Monthly rules set on the 29th–31st land on the last day of shorter months. Pausing stops posting; resuming skips the dates missed while paused. Posted entries use stable ids (`rec_<rule>_<n>`), so an occurrence is never added twice and they sync to a shared household like any other entry. Rules are included in backups (schema 3)
- Bank SMS are scanned automatically when the app opens or resumes (if the SMS Reader is on), and when the SMS inbox screen opens

### Fixed
- **SMS sync missed most bank messages.** The sender allow-list lacked most real DLT headers (SBIUPI, CBSSBI, ATMSBI, SBICRD, ICICIT; and had `PHONEPE` where the header is `PHONPE`). Any alphanumeric sender is now scanned; senders not on the list must also use a bank verb and mention an account or card. Personal numbers and `-P` promotional headers are skipped
- SBI UPI alerts ("debited by 75.00", no Rs/INR) are parsed; the transaction amount is chosen over "Avl Bal" amounts; HDFC multi-line UPI, card spends, ICICI, SBI CBS and PhonePe formats give correct payee names
- OTPs, dues/overdue notices, "will be debited", collect requests, declined transactions, scheduled AutoPay notices, mandate registrations and credit-card bill-payment confirmations are no longer listed as transactions. Pending entries stored by the old parser are re-checked on the next scan
- SMS are read through a small native channel (four columns, off the main thread, last 90 days) instead of `flutter_sms_inbox`, which read every column of the whole inbox on the UI thread
- Light theme: yellow/mint category and quick-action colours are darkened for legibility; the amount field no longer shows a white box; the sheet handle is visible
- Bottom navigation: every tab shows a label so the icons line up, the + button is exactly centred, and page content fades out behind the floating bar

---

## [1.4.0] — 2026-11-01

### Added
- **Accounts** — Cash, Bank, UPI/Wallet, Credit Card or Other, each with an opening balance. The dashboard now shows the real **Total Balance** (opening balances plus everything logged) with a per-account strip underneath; monthly income and expense stay on the same card
- Every transaction records its account; transfers pick a source and a destination and move money between them. Legacy entries without an account count toward the default account
- Onboarding asks for cash in hand and bank balance; Settings → Accounts manages accounts, sets the default, and deletes one by moving its entries to the default
- Accounts sync in a shared household (`households/{id}/accounts`), are included in backups (schema 2), and appear as Account / To Account columns in the CSV export
- **Background auto-backup** — when Auto Backup is on, Android WorkManager writes the daily backup at the chosen time even if the app is closed (Settings → Backup Time). The on-open check stays as a fallback for days the OS skips the job. The background isolate only reads Hive and writes the file; the app picks the backup time up from the newest file

### Fixed
- Editing a partner's transaction no longer re-attributes it to the editor
- Bottom navigation bar now sits above the system navigation bar (it was hidden behind 3-button navigation on edge-to-edge Android 15+)

---

## [1.3.0] — 2026-11-01

### Added
- **Shared Tracking** — track one household from two phones. Sign in with Google, create a household, share a 6-character invite code; transactions, categories, currency and the monthly budget sync through Firestore (free tier). Receipt photos, bank SMS, app lock and reminders stay on the phone
- Transaction tiles show who added each entry ("You" / partner) and Analytics gains a **Who Spent** split when the household has more than one member
- `TransactionModel.addedBy` (Hive field 12) and `AppSettings.householdId` (field 19); both are included in backups, and a restore keeps the device's own household link
- Firestore security rules in `firebase/firestore.rules`; setup guide in `docs/SHARED_TRACKING_SETUP.md`

### Changed
- The feature is strictly opt-in. Without `android/app/google-services.json` the Google Services Gradle plugin is skipped, the build succeeds, and Settings reports the feature as not configured. `INTERNET` permission is now declared for release builds
- Hive remains the source of truth; Firestore is a mirror with last-write-wins on `updatedAt`
- Android: Kotlin Gradle plugin 2.2.20 → 2.3.21 (Firebase Auth 25 ships Kotlin 2.4 metadata), `jvmTarget` moved to the `compilerOptions` DSL, and `kotlin.incremental=false` to work around a Windows incremental-cache failure in plugin modules

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
