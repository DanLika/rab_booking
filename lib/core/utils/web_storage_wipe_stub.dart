/// Non-web stub for [wipeWebStorageOnLogout]. No-op on mobile/desktop.
Future<void> wipeWebStorageOnLogout({bool reload = false}) async {
  // Mobile + desktop: Firebase Auth signOut already clears all auth state.
  // sessionStorage/localStorage/cookies don't apply outside the browser.
}
