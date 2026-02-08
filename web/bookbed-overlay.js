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
 *   - Fixed-position guard div sits on top of each BookBed iframe
 *   - Mouse wheel scrolls the parent page normally (not trapped)
 *   - Click on widget area → guard hides → widget becomes interactive
 *   - Mouse leaves widget area → guard restores → page scrollable again
 *
 * Does NOT wrap/move iframes in the DOM (that causes reload).
 * Uses getBoundingClientRect + position:fixed — works in any DOM structure.
 */
(function () {
  'use strict';

  // Only apply on desktop (mouse/trackpad) — touch devices don't trap scroll
  if (!window.matchMedia('(pointer: fine)').matches) return;

  function initIframe(iframe) {
    if (iframe.dataset.bbGuard) return;
    iframe.dataset.bbGuard = '1';

    // Guard lives on <body>, positioned fixed over the iframe
    var guard = document.createElement('div');
    document.body.appendChild(guard);

    var rafId = 0;

    function sync() {
      var r = iframe.getBoundingClientRect();
      guard.style.cssText =
        'position:fixed;z-index:9;cursor:pointer;' +
        'top:' + r.top + 'px;' +
        'left:' + r.left + 'px;' +
        'width:' + r.width + 'px;' +
        'height:' + r.height + 'px;';
    }

    function scheduleSync() {
      if (!rafId) {
        rafId = requestAnimationFrame(function () {
          sync();
          rafId = 0;
        });
      }
    }

    sync();

    // Track iframe position as page scrolls/resizes
    window.addEventListener('scroll', scheduleSync, { passive: true });
    window.addEventListener('resize', scheduleSync);
    if (window.ResizeObserver) {
      new ResizeObserver(scheduleSync).observe(iframe);
    }

    // Click guard → hide → iframe becomes interactive
    guard.addEventListener('click', function () {
      guard.style.display = 'none';
    });

    // Mouse leaves iframe area → restore guard → page scrollable again
    document.addEventListener('mousemove', function (e) {
      if (guard.style.display !== 'none') return;
      var r = iframe.getBoundingClientRect();
      if (
        e.clientX < r.left - 5 ||
        e.clientX > r.right + 5 ||
        e.clientY < r.top - 5 ||
        e.clientY > r.bottom + 5
      ) {
        guard.style.display = '';
        sync();
      }
    });
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
    new MutationObserver(function () {
      scanAll();
    }).observe(document.body || document.documentElement, {
      childList: true,
      subtree: true,
    });
  }
})();
