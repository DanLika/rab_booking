import 'package:web/web.dart' as web;

/// Web implementation of [wipeWebStorageOnLogout].
///
/// F-58c-14: Firebase Auth `signOut()` only clears the
/// `firebaseLocalStorageDb` IndexedDB store. The remaining surface
/// (sessionStorage, localStorage, document cookies) keeps any non-Firebase
/// "remember me" / preference / cached-PII state alive on a shared kiosk.
///
/// This routine wipes:
/// 1. `sessionStorage` (entire origin)
/// 2. `localStorage`   (entire origin)
/// 3. Document cookies (path=/ on current host)
/// 4. Optionally forces a `location.reload()` so any in-memory Flutter state
///    is dropped together with the storage.
///
/// Catches and swallows every store-level error individually — a single
/// blocked store must not abort the rest of the wipe.
Future<void> wipeWebStorageOnLogout({bool reload = false}) async {
  try {
    web.window.sessionStorage.clear();
  } catch (_) {
    /* ignore */
  }

  try {
    web.window.localStorage.clear();
  } catch (_) {
    /* ignore */
  }

  try {
    final doc = web.document;
    final cookies = doc.cookie;
    if (cookies.isNotEmpty) {
      for (final pair in cookies.split(';')) {
        final eqIdx = pair.indexOf('=');
        final name = (eqIdx >= 0 ? pair.substring(0, eqIdx) : pair).trim();
        if (name.isEmpty) continue;
        doc.cookie =
            '$name=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; SameSite=Lax';
      }
    }
  } catch (_) {
    /* ignore */
  }

  if (reload) {
    try {
      web.window.location.reload();
    } catch (_) {
      /* ignore */
    }
  }
}
