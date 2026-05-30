// This script is embedded in the Flutter web app (the iframe content).
// It sends the content height to the parent window.
//
// SF-NEW (audit/50 F-50-11): replace targetOrigin '*' with the parent origin
// captured from an explicit `{type:'init', origin}` handshake. Falls back to
// document.referrer-derived origin if no handshake fires within 2s, and stays
// silent (no postMessage) if neither is available — never broadcasts to '*'.

(function () {
  var parentOrigin = null;
  var pending = [];

  function resolveOrigin() {
    if (parentOrigin) return parentOrigin;
    try {
      if (document.referrer) {
        var refUrl = new URL(document.referrer);
        // Same-origin parent isn't a leak risk; embedders use https only.
        if (refUrl.protocol === 'https:' || refUrl.protocol === 'http:') {
          return refUrl.origin;
        }
      }
    } catch (e) {
      // ignore — fall through to null
    }
    return null;
  }

  function trySend(payload) {
    var origin = resolveOrigin();
    if (!origin) {
      // Defer until handshake or referrer is available.
      pending.push(payload);
      return;
    }
    try {
      window.parent.postMessage(payload, origin);
    } catch (e) {
      // ignore — parent may have been torn down
    }
  }

  function flushPending() {
    var origin = resolveOrigin();
    if (!origin) return;
    while (pending.length) {
      try {
        window.parent.postMessage(pending.shift(), origin);
      } catch (e) {
        // ignore
      }
    }
  }

  // Listen for an explicit handshake from the parent so we don't have to
  // trust document.referrer (which can be empty on no-referrer policy).
  window.addEventListener('message', function (event) {
    if (!event || !event.data || event.data.type !== 'bookbed-widget-init') return;
    if (typeof event.origin !== 'string' || !event.origin) return;
    parentOrigin = event.origin;
    flushPending();
  });

  window.addEventListener('load', function () {
    if (typeof ResizeObserver !== 'function') return;
    var observer = new ResizeObserver(function (entries) {
      for (var i = 0; i < entries.length; i++) {
        var height = entries[i].contentRect.height;
        if (height > 0) {
          trySend({ type: 'resize', height: height });
        }
      }
    });
    var flutterScene = document.querySelector('flt-scene');
    if (flutterScene) {
      observer.observe(flutterScene);
    }
  });
})();
