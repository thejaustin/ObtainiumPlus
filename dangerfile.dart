import 'package:danger_dart/danger_dart.dart';

void main() {
  final danger = Danger();

  // 1. Check PR Size
  if (danger.github.pr.changedFiles > 20) {
    warn('🚨 This PR is quite large! Consider breaking it into smaller chunks if possible.');
  }

  // 2. Check for missing tests
  final hasTestChanges = danger.git.modifiedFiles.any((file) => file.startsWith('test/'));
  final hasLibChanges = danger.git.modifiedFiles.any((file) => file.startsWith('lib/'));
  
  if (hasLibChanges && !hasTestChanges) {
    warn('🧪 It looks like you changed code in `lib/` but didn\\'t add or update any tests in `test/`.');
  }

  // 3. Check for Android Manifest changes
  final hasManifestChanges = danger.git.modifiedFiles.any((file) => file.contains('AndroidManifest.xml'));
  if (hasManifestChanges) {
    message('📱 Android Manifest changes detected. Please ensure permissions are correct.');
  }

  // 4. Check for pubspec.yaml changes
  final hasPubspecChanges = danger.git.modifiedFiles.any((file) => file == 'pubspec.yaml');
  if (hasPubspecChanges) {
    message('📦 Dependencies changed. Ensure you run `flutter pub get`.');
  }

  // 5. Encourage descriptive PRs
  if (danger.github.pr.body == null || danger.github.pr.body!.length < 50) {
    warn('📝 Please provide a more detailed description of your changes in the PR body.');
  }
}
