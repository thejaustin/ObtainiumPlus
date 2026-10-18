import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/pages/home.dart';

void main() {
  test('link imports drop security-weakening per-app settings', () {
    final apps = <dynamic>[
      {
        'id': 'a',
        'additionalSettings': {
          'allowInsecure': true,
          'allowedSigningCertHashes': 'deadbeef',
          'includePrereleases': true,
        },
      },
      {
        'id': 'b',
        'additionalSettings': jsonEncode({
          'allowInsecureRedirects': true,
          'enableCertificatePinning': false,
          'fallbackToOlderReleases': true,
        }),
      },
      'not-a-map',
    ];
    expect(stripLinkUnsafeSettings(apps), 4);
    expect((apps[0] as Map)['additionalSettings'], {'includePrereleases': true});
    expect(
      jsonDecode((apps[1] as Map)['additionalSettings'] as String),
      {'fallbackToOlderReleases': true},
    );
  });
}
