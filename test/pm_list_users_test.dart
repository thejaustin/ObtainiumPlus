import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/multi_user_diagnostic_sheet.dart';

void main() {
  test('parses pm list users output', () {
    const out = '''Users:
	UserInfo{0:Owner:c13} running
	UserInfo{95:DUAL_APP:4001010} running
	UserInfo{150:Secure Folder:10001030} running
''';
    expect(parsePmListUsers(out), {
      0: 'Owner',
      95: 'DUAL_APP',
      150: 'Secure Folder',
    });
  });

  test('ignores unrelated output', () {
    expect(parsePmListUsers('Error: permission denied'), isEmpty);
  });
}
