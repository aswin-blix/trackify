# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.2.x   | Yes       |
| < 1.2   | No        |

## Privacy Design

Trackify is designed from the ground up to be 100% offline and private:

- **No network calls** — the app never connects to any server
- **No analytics or tracking** — zero telemetry
- **No cloud backup** — `android:allowBackup` is disabled and data extraction rules exclude all app data, so Android Auto Backup never uploads the database to Google Drive. Backups are explicit, user-initiated files only
- **SMS data stays local** — bank SMS are read on demand and stored only on your device
- **Biometric data never accessed** — App Lock delegates entirely to Android BiometricPrompt; Trackify never reads or stores your fingerprint or face data

## Known Limitations

- The local Hive database is **not encrypted at rest**. On a rooted device, or if the device is compromised, app data could be read. Encrypting the boxes with `HiveAesCipher` and a key in the platform keystore is on the roadmap
- Exported backup and CSV files are plain text. Treat them like a bank statement

## Reporting a Vulnerability

If you discover a security vulnerability, please **do not open a public issue**.

Instead, use [GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) on this repository, or email the maintainer listed on the GitHub profile.

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You will receive a response within 48 hours. If the issue is confirmed, a patch will be released as soon as possible.
