# Shared Tracking (partner / household) setup

Shared tracking lets two or more people keep one ledger and one budget from
their own phones. It is optional. Without the Firebase config below the app
builds and runs exactly as before, fully offline, and the Settings entry
explains that the feature is not configured.

Cost: Firebase's free Spark plan covers this comfortably for personal use
(50K reads and 20K writes per day). No card is required. Phone-number login
and Cloud Storage are deliberately not used because they need billing.

## 1. Create the Firebase project

1. Open <https://console.firebase.google.com> and create a project.
2. Add an **Android** app with package name `com.blixcode.trackify`.
3. Add the **SHA-1** fingerprints of every key you build with. Google sign-in
   silently fails without them.

   ```bash
   # Debug key
   keytool -list -v -alias androiddebugkey -storepass android \
     -keystore ~/.android/debug.keystore
   # Release key (path/alias from android/key.properties)
   keytool -list -v -alias <alias> -keystore <path-to-jks>
   ```

   You can add more fingerprints later under Project settings → Your apps.
4. Download `google-services.json` and place it at
   `android/app/google-services.json`. The file is git-ignored.

## 2. Enable Google sign-in

Firebase console → **Authentication** → Sign-in method → **Google** → Enable.
Set the support email and save.

This creates the "web client" OAuth entry (`client_type: 3`) that the Android
plugin needs. If you enabled Google sign-in *after* downloading
`google-services.json`, download the file again.

## 3. Create Firestore and deploy the rules

1. Firebase console → **Firestore Database** → Create database → production
   mode → pick the region closest to your users (for example `asia-south1`).
2. Paste `firebase/firestore.rules` into the Rules tab and publish, or with
   the Firebase CLI:

   ```bash
   npm i -g firebase-tools
   firebase login
   firebase use <your-project-id>
   firebase deploy --only firestore:rules
   ```

No composite indexes are needed.

## 4. Build

```bash
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

Gradle prints a warning and skips Firebase when `google-services.json` is
missing, so CI builds without the file keep working.

## 5. Use it

Settings → **Shared Tracking** → Continue with Google → **Create household**.
Share the 6-character code. Your partner signs in on their phone and taps
**Join with a code**.

Everything already on either phone is merged into the shared ledger. After
that, each new entry is tagged with who added it, transaction tiles show a
"You" / partner label, and Analytics gains a "Who Spent" card.

**Lent & Borrowed** entries sync like any other transaction. Each partner
records their own loans; both phones show both sets, labelled by owner, and
balances are kept per owner ("Rahul owes you" and "Rahul owes Shyni" stay
separate). Use the Everyone / You / partner filter on that screen.

**Recurring rules** stay on the phone that created them. The entries they post
sync normally, so a rule is never run twice across two phones.

Keep both phones on the same app version. Loan entries (1.6.0+) are read as
expenses by older builds.

## Data layout

```
households/{id}
  name, inviteCode, ownerUid, memberIds[], members{uid: {name, photoUrl, joinedAt}}
  monthlyBudget, currency, currencySymbol, createdAt, updatedAt
households/{id}/transactions/{txId}   TransactionModel JSON (no receipt path); loans carry
                                      type lend|borrow|collect|repay, counterparty, dueDate
households/{id}/categories/{catId}    CategoryModel JSON
households/{id}/accounts/{accId}      AccountModel JSON (opening balances are shared)
invites/{code}                        { householdId, createdAt }
```

Hive stays the source of truth on each phone; Firestore is a mirror. Local
writes are pushed through the Riverpod notifiers (`app_providers.dart`), and
snapshot listeners in `household_sync.dart` write cloud changes back into Hive.
Conflicts on a transaction resolve by `updatedAt` (last write wins); categories
take the shared copy. Receipt photos, bank SMS, recurring rules, app lock and
reminders never leave the phone. No Firestore rules change is needed for
recurring or loans.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| "Not available in this build" in Settings | `google-services.json` missing when the APK was built |
| Sign-in dialog closes immediately with "cancelled" | SHA-1 of the signing key not added in Firebase |
| "Google did not return an ID token" | Google sign-in not enabled, or stale `google-services.json` without the web client |
| "Not allowed" when joining | Rules not deployed, or household already has 5 members |
| Entries never reach the partner | Rules not deployed (check Firestore → Rules → Monitor for denials) |
| Partner sees your loans as expenses | Their phone is on a version older than 1.6.0 |
