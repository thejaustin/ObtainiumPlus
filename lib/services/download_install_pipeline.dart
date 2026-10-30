import 'dart:async';
import 'dart:math';

/// Overlaps downloading and installing for a batch of app updates.
///
/// Downloads run [downloadConcurrency] at a time. Each finished download is
/// queued straight away for installing, and installs run strictly one at a
/// time (the package manager and the user's install prompts can't overlap).
/// So the first update installs while later ones are still downloading,
/// instead of every install waiting for the slowest download.
///
/// Items for which [installLast] is true (Obtainium+ itself, Shizuku
/// providers whose install restarts the binder) are held back and installed
/// after every other install, in their order in [ids].
///
/// [install] errors are passed to [onInstallError] and never stop the queue.
Future<void> runDownloadInstallPipeline<R>({
  required List<String> ids,
  required int downloadConcurrency,
  required Future<R> Function(String id) download,
  required Future<void> Function(String id, R result) install,
  required bool Function(String id) installLast,
  required void Function(String id, Object error) onInstallError,
}) async {
  if (ids.isEmpty) return;
  final held = <String, R>{};
  var installChain = Future<void>.value();

  Future<void> guardedInstall(String id, R result) async {
    try {
      await install(id, result);
    } catch (e) {
      onInstallError(id, e);
    }
  }

  var next = 0;
  Future<void> worker() async {
    while (next < ids.length) {
      final id = ids[next++];
      final result = await download(id);
      if (installLast(id)) {
        held[id] = result;
      } else {
        installChain = installChain.then((_) => guardedInstall(id, result));
      }
    }
  }

  final workers = max(1, min(downloadConcurrency, ids.length));
  await Future.wait(List.generate(workers, (_) => worker()));
  await installChain;
  for (final id in ids) {
    if (held.containsKey(id)) await guardedInstall(id, held[id] as R);
  }
}
