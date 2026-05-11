import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PlusSettingsProvider initialization and toggles', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = PlusSettingsProvider();
    
    await provider.initializeSettings(prefs);
    
    expect(provider.backupEncryptionEnabled, false);
    
    provider.backupEncryptionEnabled = true;
    expect(provider.backupEncryptionEnabled, true);
    expect(prefs.getBool('backupEncryptionEnabled'), true);
  });
}
