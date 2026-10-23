/// Whether a polled package state shows the install we started has landed.
///
/// Pure so the rules can be tested; both the stock and Shizuku installers
/// poll with it because their result callbacks can be lost (#3255, #896).
/// [wasInstalled] must come from whether the package existed before the
/// install, not from a null version code: Android 15 reports null codes for
/// longVersionCode > Integer.MAX_VALUE, which would make every update look
/// like a fresh install that succeeds on the first poll.
bool hasInstallLanded({
  required bool wasInstalled,
  int? existingCode,
  String? existingName,
  int? existingUpdateTime,
  int? targetCode,
  String? targetName,
  int? currentCode,
  String? currentName,
  int? currentUpdateTime,
}) {
  final cur = currentCode ?? 0;
  final hasTargetCode = targetCode != null && targetCode > 0;
  final hasTargetName = targetName != null && targetName.isNotEmpty;
  if (!wasInstalled) {
    if (hasTargetCode) return cur >= targetCode;
    if (hasTargetName) return currentName == targetName;
    return true;
  }
  final existing = existingCode ?? 0;
  if (hasTargetCode && existing > 0 && targetCode > existing) {
    return cur >= targetCode;
  }
  if (hasTargetName && targetName != existingName) {
    return currentName == targetName;
  }
  // Same version reinstalled, or versions we can't compare: the package's
  // last-update time moving is the only sign.
  if (existingUpdateTime != null &&
      currentUpdateTime != null &&
      currentUpdateTime != existingUpdateTime) {
    return true;
  }
  return existing > 0 && cur > existing;
}
