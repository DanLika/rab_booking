/**
 * BookBed Overlay — prevents iframe scroll trapping on all devices.
 *
 * Usage: Add <script src="https://view.bookbed.io/bookbed-overlay.js"></script>
 * to any page that contains a .bookbed-widget wrapper.
 *
 * How it works:
 * Desktop (mouse/trackpad):
 *   - Overlay captures mouse wheel so parent page scrolls normally
 *   - Click on widget → overlay hides → widget interactive
 *   - Mouse leaves widget area → overlay restores
 *
 * Mobile/Touch:
 *   - Overlay has touch-action:pan-y — vertical swipes scroll parent page
 *   - Tap widget → overlay hides → widget interactive
 *   - Touch outside widget → overlay restores
 */
(function () {
  'use strict';

  var hasPointerFine = window.matchMedia('(pointer: fine)').matches;

  function initOverlay(widget) {
    var overlay = widget.querySelector('.bookbed-overlay');
    if (!overlay) return;
    if (overlay.dataset.bbInit) return;
    overlay.dataset.bbInit = '1';

    // Enable overlay on all devices
    overlay.style.pointerEvents = 'auto';

    // On touch devices, allow parent page to scroll through the overlay
    if (!hasPointerFine) {
      overlay.style.touchAction = 'pan-y';
    }

    var active = false;

    // Click/tap dismisses overlay → widget becomes interactive
    overlay.addEventListener('click', function () {
      overlay.style.pointerEvents = 'none';
      active = true;
    });

    // Desktop: mouseleave restores overlay
    widget.addEventListener('mouseleave', function () {
      overlay.style.pointerEvents = 'auto';
      active = false;
    });

    // Desktop fallback: cross-origin iframe swallows mouse events,
    // so mouseleave may not fire. Detect mouse re-entering parent page.
    document.addEventListener('mousemove', function (e) {
      if (!active) return;
      var r = widget.getBoundingClientRect();
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

    // Touch: detect touch outside widget to restore overlay
    document.addEventListener('touchstart', function (e) {
      if (!active) return;
      var touch = e.touches[0];
      var r = widget.getBoundingClientRect();
      if (
        touch.clientX < r.left ||
        touch.clientX > r.right ||
        touch.clientY < r.top ||
        touch.clientY > r.bottom
      ) {
        overlay.style.pointerEvents = 'auto';
        active = false;
      }
    });
  }

  function initAll() {
    var widgets = document.querySelectorAll('.bookbed-widget');
    for (var i = 0; i < widgets.length; i++) {
      initOverlay(widgets[i]);
    }
  }

  // Initialize now and on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAll);
  } else {
    initAll();
  }

  // Also observe DOM for dynamically added widgets (React, SPA, etc.)
  if (window.MutationObserver) {
    new MutationObserver(function () {
      initAll();
    }).observe(document.body || document.documentElement, {
      childList: true,
      subtree: true,
    });
  }
})();
