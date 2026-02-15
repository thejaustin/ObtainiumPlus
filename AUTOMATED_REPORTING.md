# Automated Reporting in Obtainium+

Obtainium+ features an automated crash and error reporting system designed to streamline debugging and maintain app stability.

## 1. Automated Crash Reporting (Sentry)

The app is integrated with **Sentry** for real-time crash tracking.

### Connecting Sentry to GitHub
To automatically create GitHub Issues from Sentry errors:
1. In your Sentry project, go to **Settings > Integrations**.
2. Install the **GitHub** integration.
3. Configure the integration to map your Sentry project to this repository.
4. Enable **Issue Sync** to keep Sentry and GitHub in sync.

### Configuration
To enable Sentry reporting in your builds, you must provide the Sentry DSN during the Flutter build process:

```bash
flutter build apk --dart-define=SENTRY_DSN=your_dsn_here
```

### CI/CD Integration
The GitHub Actions workflow (`build-apk.yml`) is configured to:
- Automatically upload debug symbols/proguard mappings to Sentry if the following secrets are provided:
    - `SENTRY_AUTH_TOKEN`
    - `SENTRY_ORG`
    - `SENTRY_PROJECT`

## 2. GitHub Issue Templates

Consistent reporting is ensured through GitHub Issue Templates found in `.github/ISSUE_TEMPLATE/`:
- **Crash Report**: For reporting app crashes with stack traces.
- **Bug Report**: For reporting functional issues.
- **Feature Request**: For suggesting new features.

## 3. Real-time Reporting Webhook

A GitHub Action workflow (`.github/workflows/crash-report-webhook.yml`) is available to handle crash reports from external sources via a `repository_dispatch` event.

### Usage
You can trigger an automated issue creation by sending a POST request to the GitHub API:

```bash
curl -X POST 
  -H "Accept: application/vnd.github.v3+json" 
  -H "Authorization: token YOUR_GITHUB_TOKEN" 
  https://api.github.com/repos/OWNER/REPO/dispatches 
  -d '{"event_type": "crash_report", "client_payload": {"error": "Example Error", "version": "1.0.0", "stackTrace": "..."}}'
```

## 4. Release Automation

Every push to `main` (that isn't an auto-bump) triggers:
1. **Version Bumping**: Automatically increments the patch version in `pubspec.yaml`.
2. **Changelog Generation**: Generates a detailed changelog based on commit messages.
3. **Release Creation**: Creates a new GitHub Release with attached APKs and automatically tags relevant issues/PRs.

## 5. Built-in Error UI

Even if Sentry is not configured, the app includes a fallback Error UI (`ErrorApp` and `_buildErrorWidget`) that displays stack traces directly to the user, allowing them to manually copy and report issues using the [Crash Report Template](https://github.com/OWNER/REPO/issues/new?template=crash_report.md).
