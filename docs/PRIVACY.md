# Privacy

What Obtainium+ stores, what it sends, and where.

## What leaves your phone

- **Requests to the sources you add.** To check for updates the app contacts each app's source (GitHub, GitLab, F-Droid and so on) directly, and downloads APKs from there. Nothing goes through a server run by this project.
- **Crash reports: off by default.** Settings > Troubleshooting > "Send crash reports". When on, crashes are sent to the developer's Sentry project (error details and device model). Performance traces, profiles and session tracking are not sent. Turning it off stops reporting immediately; turning it on applies after the next launch. Builds without the project's Sentry key (local or forked builds) never send anything.
- **Nothing else.** No analytics, ads or accounts.

## What stays on your phone

- **Settings and app list:** in the app's private storage.
- **API tokens and store credentials:** in Android's secure storage.
- **Logs and the local crash record:** in the app's private storage; you can view and share them from Settings > Troubleshooting. They are shared only if you choose to.
- **Shizuku activity log:** local only.

## Backups

Android cloud backup is off (`allowBackup=false`, with cloud-backup rules excluding everything), so tokens and credentials are not copied to Google. Device-to-device transfer skips secure storage. Use the app's own export if you want a backup; encrypt it with a password.

## Permissions

Usage access, overlay and install permissions are optional and requested only for the features that need them. Nothing from them is sent anywhere.

If something here stops being true, that is a bug: please open an issue.
