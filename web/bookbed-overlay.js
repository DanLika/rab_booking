/**
 * BookBed Scroll Guard v8 — prevents iframe scroll trapping.
 *
 * Usage: Add this single line anywhere on your page:
 *   <script src="https://view.bookbed.io/bookbed-overlay.js" defer></script>
 *
 * Auto-detects BookBed iframes (src containing view.bookbed.io).
 * No wrapper divs or manual HTML changes needed.
 *
 * How it works (Google Maps cooperative pattern):
 *   - Creates an absolute-positioned overlay inside iframe's parent element
 *   - Default state: overlay captures mouse/touch events → parent page scrolls
 *   - Click/tap on widget → overlay becomes transparent → widget interactive
 *   - Mouse leave (desktop), touch outside iframe (mobile), or page scroll → restores
 *   - touch-action CSS lets browser handle mobile scroll natively
 *
 * Does NOT wrap/move iframes in the DOM (that causes reload).
 * Uses position:absolute inside parent — works in any DOM structure.
 */
(function () {
  'use strict';

  function initIframe(iframe) {
    if (iframe.dataset.bbGuard) return;
    iframe.dataset.bbGuard = '1';

    var parent = iframe.parentElement;
    if (!parent) return;

    // Ensure parent is a positioning context for absolute overlay
    var pos = getComputedStyle(parent).position;
    if (pos === 'static' || pos === '') {
      parent.style.position = 'relative';
    }

    // Create overlay as sibling of iframe (NOT wrapping — no reload)
    var overlay = document.createElement('div');
    overlay.style.cssText =
      'position:absolute;top:0;left:0;width:100%;height:100%;' +
      'z-index:2;cursor:pointer;' +
      'touch-action:pan-y pan-x;';

    // Insert after iframe (stays in same parent, no DOM restructuring)
    parent.insertBefore(overlay, iframe.nextSibling);

    function restore() {
      overlay.style.pointerEvents = 'auto';
    }

    // Click/tap → pointer-events:none → events pass through to iframe
    overlay.addEventListener('click', function () {
      overlay.style.pointerEvents = 'none';
    });

    // Desktop: mouse leaves parent → restore overlay protection
    parent.addEventListener('mouseleave', restore);

    // Mobile: touch outside iframe visual bounds → restore
    document.addEventListener('touchstart', function (e) {
      if (overlay.style.pointerEvents !== 'none') return;
      var touch = e.touches[0];
      if (!touch) return;
      var r = iframe.getBoundingClientRect();
      if (
        touch.clientX < r.left ||
        touch.clientX > r.right ||
        touch.clientY < r.top ||
        touch.clientY > r.bottom
      ) {
        restore();
      }
    }, { passive: true });

    // Safety net: any page scroll → restore (user moved on from widget)
    window.addEventListener('scroll', function () {
      if (overlay.style.pointerEvents === 'none') {
        restore();
      }
    }, { passive: true });
  }

  function scanAll() {
    var iframes = document.querySelectorAll('iframe[src*="view.bookbed.io"]');
    for (var i = 0; i < iframes.length; i++) {
      initIframe(iframes[i]);
    }
  }

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', scanAll);
  } else {
    scanAll();
  }

  // Watch for dynamically added iframes (React, SPA, etc.)
  if (window.MutationObserver) {
    new MutationObserver(scanAll).observe(
      document.body || document.documentElement,
      { childList: true, subtree: true }
    );
  }
})();
