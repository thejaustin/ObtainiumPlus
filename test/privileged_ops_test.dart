import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/services/privileged_ops_service.dart';

void main() {
  tearDown(() => PrivilegedOps.invokeOverride = null);

  test('candidate order per preference', () {
    expect(privilegedCandidates(PrivilegedBackend.system), isEmpty);
    expect(privilegedCandidates(PrivilegedBackend.auto), ['shizuku', 'root']);
    expect(privilegedCandidates(PrivilegedBackend.shizuku), ['shizuku']);
    expect(privilegedCandidates(PrivilegedBackend.root), ['root']);
  });

  test('system never calls native', () async {
    var calls = 0;
    PrivilegedOps.invokeOverride = (_, _, _) async {
      calls++;
      return {'ok': true};
    };
    expect(
      await PrivilegedOps.run(
        PrivilegedOp.uninstall,
        'a.b',
        PrivilegedBackend.system,
      ),
      isFalse,
    );
    expect(calls, 0);
  });

  test('auto falls through failure and exception to next backend', () async {
    final tried = <String>[];
    PrivilegedOps.invokeOverride = (op, pkg, backend) async {
      tried.add(backend);
      if (backend == 'shizuku') throw Exception('no binder');
      return {'ok': true};
    };
    expect(
      await PrivilegedOps.run(
        PrivilegedOp.uninstall,
        'a.b',
        PrivilegedBackend.auto,
      ),
      isTrue,
    );
    expect(tried, ['shizuku', 'root']);
  });

  test('all backends failing returns false for system fallback', () async {
    PrivilegedOps.invokeOverride = (_, _, _) async => {'ok': false};
    expect(
      await PrivilegedOps.run(
        PrivilegedOp.batteryWhitelist,
        'a.b',
        PrivilegedBackend.auto,
      ),
      isFalse,
    );
  });
}
