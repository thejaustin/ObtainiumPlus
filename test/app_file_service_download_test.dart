import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:obtainium/services/app_file_service.dart';

void main() {
  late ServerSocket server;
  late Directory destDir;
  final body = List<int>.generate(4096, (i) => i % 256);
  var sendBytes = 4096;

  setUp(() async {
    sendBytes = 4096;
    destDir = await Directory.systemTemp.createTemp('app_file_dl_test');
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((socket) async {
      // Read the request head, then answer by hand so the body can be cut
      // short while Content-Length still promises all of it.
      await socket.firstWhere(
        (chunk) => utf8.decode(chunk).contains('\r\n\r\n'),
      );
      socket.add(
        utf8.encode(
          'HTTP/1.1 200 OK\r\n'
          'Content-Type: application/vnd.android.package-archive\r\n'
          'Content-Length: ${body.length}\r\n'
          'Connection: close\r\n\r\n',
        ),
      );
      socket.add(body.sublist(0, sendBytes));
      await socket.flush();
      await socket.close();
    });
  });

  tearDown(() async {
    await server.close();
    await destDir.delete(recursive: true);
  });

  Future<File> download() => AppFileService.downloadFile(
    'http://${server.address.host}:${server.port}/app.apk',
    'app',
    false,
    null,
    destDir.path,
    useExisting: false,
  );

  test('a download shorter than its Content-Length is not accepted', () async {
    sendBytes = 1000;
    // dart:io or our own length check — either way an error, not an APK.
    await expectLater(
      download(),
      throwsA(anyOf(isA<ClientException>(), isA<HttpException>())),
    );
    expect(File('${destDir.path}/app.apk').existsSync(), isFalse);
  });

  test('a complete download is accepted', () async {
    final f = await download();
    expect(await f.length(), body.length);
  });
}
