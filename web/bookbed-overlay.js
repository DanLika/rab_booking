/**
 * BookBed Scroll Guard — prevents iframe scroll trapping on desktop.
 *
 * Usage: Add this single line anywhere on your page:
 *   <script src="https://view.bookbed.io/bookbed-overlay.js" defer></script>
 *
 * Auto-detects BookBed iframes (src containing view.bookbed.io).
 * No wrapper divs or manual HTML changes needed.
 *
 * How it works (desktop only — mobile/touch unaffected):
 *   - Sets pointer-events:none on iframe so mouse wheel scrolls parent page
 *   - Click on iframe area → pointer-events restored → widget interactive
 *   - Mouse leaves iframe area → pointer-events:none again → page scrollable
 *
 * IMPORTANT: Does NOT move/wrap the iframe in the DOM (that causes reload).
 */
(function () {
  'use strict';

  // Only apply on desktop (mouse/trackpad) — touch devices don't trap scroll
  if (!window.matchMedia('(pointer: fine)').matches) return;

  function initIframe(iframe) {
    if (iframe.dataset.bbInit) return;
    iframe.dataset.bbInit = '1';

    // Block pointer events so mouse wheel passes through to parent page
    iframe.style.pointerEvents = 'none';

    var active = false;

    // Click within iframe bounds → enable interaction
    document.addEventListener('mousedown', function (e) {
      var r = iframe.getBoundingClientRect();
      if (
        e.clientX >= r.left &&
        e.clientX <= r.right &&
        e.clientY >= r.top &&
        e.clientY <= r.bottom
      ) {
        iframe.style.pointerEvents = 'auto';
        active = true;
      }
    });

    // Mouse moves outside iframe → restore scroll protection
    document.addEventListener('mousemove', function (e) {
      if (!active) return;
      var r = iframe.getBoundingClientRect();
      if (
        e.clientX < r.left ||
        e.clientX > r.right ||
        e.clientY < r.top ||
        e.clientY > r.bottom
      ) {
        iframe.style.pointerEvents = 'none';
        active = false;
      }
    });
  }

  function initAll() {
    var iframes = document.querySelectorAll(
      'iframe[src*="view.bookbed.io"]'
    );
    for (var i = 0; i < iframes.length; i++) {
      initIframe(iframes[i]);
    }
  }

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAll);
  } else {
    initAll();
  }

  // Observe DOM for dynamically added iframes (React, SPA, etc.)
  if (window.MutationObserver) {
    new MutationObserver(function () {
      initAll();
    }).observe(document.body || document.documentElement, {
      childList: true,
      subtree: true,
    });
  }
})();
