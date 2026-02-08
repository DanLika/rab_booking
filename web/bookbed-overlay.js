/**
 * BookBed Overlay — prevents iframe scroll trapping on desktop.
 *
 * Usage: Add this single line anywhere on your page:
 *   <script src="https://view.bookbed.io/bookbed-overlay.js" defer></script>
 *
 * The script auto-detects BookBed iframes (src containing view.bookbed.io)
 * and wraps them with a scroll-protection overlay. No manual HTML changes needed.
 *
 * How it works (desktop only — mobile/touch unaffected):
 *   - Transparent overlay sits on top of iframe
 *   - Mouse wheel scrolls the parent page (not trapped by iframe)
 *   - Click on widget → overlay hides → widget becomes interactive
 *   - Mouse leaves widget → overlay restores → page scrollable again
 */
(function () {
  'use strict';

  // Only apply on desktop (mouse/trackpad) — touch devices don't trap scroll
  if (!window.matchMedia('(pointer: fine)').matches) return;

  function wrapIframe(iframe) {
    if (iframe.dataset.bbInit) return;
    iframe.dataset.bbInit = '1';

    // Create wrapper
    var wrapper = document.createElement('div');
    wrapper.className = 'bookbed-widget';
    wrapper.style.cssText = 'position:relative;width:100%;max-width:100%;';

    // Insert wrapper where iframe is, then move iframe inside
    iframe.parentNode.insertBefore(wrapper, iframe);
    wrapper.appendChild(iframe);

    // Create overlay
    var overlay = document.createElement('div');
    overlay.className = 'bookbed-overlay';
    overlay.style.cssText =
      'position:absolute;top:0;left:0;width:100%;height:100%;' +
      'cursor:pointer;z-index:1;pointer-events:auto;';
    wrapper.appendChild(overlay);

    var active = false;

    // Click dismisses overlay → widget interactive
    overlay.addEventListener('click', function () {
      overlay.style.pointerEvents = 'none';
      active = true;
    });

    // Mouse leaves widget → restore overlay
    wrapper.addEventListener('mouseleave', function () {
      overlay.style.pointerEvents = 'auto';
      active = false;
    });

    // Fallback: cross-origin iframe swallows mouse events,
    // so mouseleave may not fire. Detect mouse re-entering parent page.
    document.addEventListener('mousemove', function (e) {
      if (!active) return;
      var r = wrapper.getBoundingClientRect();
      if (
        e.clientX < r.left ||
        e.clientX > r.right ||
        e.clientY < r.top ||
        e.clientY > r.bottom
      ) {
        overlay.style.pointerEvents = 'auto';
        active = false;
      }
    });
  }

  function initAll() {
    var iframes = document.querySelectorAll(
      'iframe[src*="view.bookbed.io"]'
    );
    for (var i = 0; i < iframes.length; i++) {
      wrapIframe(iframes[i]);
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
