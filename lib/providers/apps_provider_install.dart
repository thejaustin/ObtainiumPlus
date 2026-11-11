// Install-flow helpers shared by AppsProvider and the install services.

/// Whether an install should be confirmed by polling the package state in
/// addition to awaiting the installer result (#3255, #3369).
///
/// The background stock workaround must not be raced (its result never
/// arrives, see #896), and the external installer already reports completion
/// through its own native timeout. Everything else — including Shizuku, whose
/// result callback can be lost when the installer service stalls — is raced so
/// one app can never block the install chain indefinitely.
bool shouldPollForInstallConfirmation(
  String installerModeKey, {
  required bool needsBGWorkaround,
}) {
  if (needsBGWorkaround) return false;
  return installerModeKey != 'external';
}
