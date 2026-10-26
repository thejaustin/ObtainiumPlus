import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/pages/import_export.dart';

void main() {
  test('storage-access folder URIs read as folder paths', () {
    expect(
      readableTreeUri(
        Uri.parse(
          'content://com.android.externalstorage.documents/tree/primary%3ADocuments%2FObtainium',
        ),
      ),
      'Documents/Obtainium',
    );
    expect(
      readableTreeUri(
        Uri.parse(
          'content://com.android.externalstorage.documents/tree/1A2B-3C4D%3ABackups',
        ),
      ),
      '1A2B-3C4D/Backups',
    );
    expect(
      readableTreeUri(
        Uri.parse(
          'content://com.android.externalstorage.documents/tree/primary%3ADocuments/document/primary%3ADocuments%2Fobtainium-export.json',
        ),
      ),
      'Documents/obtainium-export.json',
    );
    expect(
      readableTreeUri(Uri.parse('file:///sdcard/x')),
      'file:///sdcard/x',
    );
  });
}
