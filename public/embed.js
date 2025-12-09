/**
 * BookBed Widget - Embed Script
 *
 * Usage:
 *
 * <!-- On your website -->
 * <div id="bookbed-widget" data-unit-id="YOUR_UNIT_ID"></div>
 * <script src="https://bookbed.io/embed.js"></script>
 *
 * Or with custom configuration:
 *
 * <div id="bookbed-widget"
 *      data-unit-id="YOUR_UNIT_ID"
 *      data-theme="light"
 *      data-height="auto">
 * </div>
 * <script src="https://bookbed.io/embed.js"></script>
 *
 * Attributes:
 * - data-unit-id: (required) Your unit ID from BookBed dashboard
 * - data-theme: "light" or "dark" (default: "light")
 * - data-height: Initial height, e.g. "800px" or "auto" (default: "auto")
 * - data-width: Width, e.g. "100%" or "600px" (default: "100%")
 */

(function() {
  'use strict';

  // Configuration - can be overridden via window.BOOKBED_WIDGET_URL
  const WIDGET_BASE_URL = window.BOOKBED_WIDGET_URL || 'https://bookbed.io';

  // Find all widget containers (support both old and new selectors)
  const containers = document.querySelectorAll('#bookbed-widget, #rab-booking-widget, [data-bookbed], [data-rab-booking]');

  if (containers.length === 0) {
    console.warn('[BookBed] No widget container found. Add <div id="bookbed-widget" data-unit-id="..."></div> to your HTML.');
    return;
  }

  containers.forEach(function(container) {
    // Get configuration from data attributes
    const unitId = container.getAttribute('data-unit-id') || container.getAttribute('data-unit');
    const theme = container.getAttribute('data-theme') || 'light';
    // Note: locale removed - widget has its own language selector
    const height = container.getAttribute('data-height') || 'auto';
    const width = container.getAttribute('data-width') || '100%';

    if (!unitId) {
      console.error('[BookBed] Missing data-unit-id attribute on widget container');
      container.innerHTML = '<p style="color: red; padding: 20px; border: 1px solid red;">Error: Missing data-unit-id attribute</p>';
      return;
    }

    // Build iframe URL with query parameters
    const params = new URLSearchParams({
      theme: theme,
      embed: 'true'
    });

    const iframeUrl = `${WIDGET_BASE_URL}/embed/${unitId}?${params.toString()}`;

    // Create iframe
    const iframe = document.createElement('iframe');
    iframe.src = iframeUrl;
    iframe.style.width = width;
    iframe.style.height = height === 'auto' ? '700px' : height; // Initial height, will auto-resize
    iframe.style.border = 'none';
    iframe.style.display = 'block';
    iframe.style.transition = 'height 0.2s ease-out'; // Smooth height transitions
    iframe.setAttribute('allowfullscreen', 'true');
    iframe.setAttribute('loading', 'lazy');
    iframe.setAttribute('title', 'BookBed Booking Widget');

    // Add loading indicator
    const initialHeight = height === 'auto' ? '700px' : height;
    const loader = document.createElement('div');
    loader.style.cssText = 'display: flex; align-items: center; justify-content: center; height: ' + initialHeight + '; background: #f5f5f5; color: #666; font-family: sans-serif;';
    loader.innerHTML = '<div style="text-align: center;"><div style="width: 40px; height: 40px; border: 4px solid #e0e0e0; border-top-color: #2196F3; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 12px;"></div><p>Loading booking widget...</p></div>';

    // Add spinner animation
    const style = document.createElement('style');
    style.textContent = '@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }';
    document.head.appendChild(style);

    container.appendChild(loader);

    // Replace loader with iframe when loaded
    iframe.addEventListener('load', function() {
      loader.style.display = 'none';
      iframe.style.display = 'block';
    });

    iframe.addEventListener('error', function() {
      loader.innerHTML = '<p style="color: red; padding: 20px;">Failed to load booking widget. Please try again later.</p>';
    });

    container.appendChild(iframe);

    // Listen for messages from iframe (height changes, booking events)
    window.addEventListener('message', function(event) {
      // Verify origin for security - allow bookbed.io and subdomains
      const isBookBedOrigin = event.origin === WIDGET_BASE_URL ||
                              event.origin.endsWith('.bookbed.io') ||
                              event.origin.includes('bookbed.io');

      if (!isBookBedOrigin) {
        return;
      }

      const data = event.data;

      // Verify message source (our widget sends 'bookbed-widget')
      if (data.source !== 'bookbed-widget') {
        return;
      }

      // Handle height changes for auto-resize iframe
      if (data.type === 'resize' && data.height) {
        iframe.style.height = data.height + 'px';
      }

      // Handle booking events
      if (data.type === 'booking-completed') {
        console.log('[BookBed] Booking completed:', data.bookingId);

        // Dispatch custom event for parent page to listen
        const customEvent = new CustomEvent('bookbed-booking-completed', {
          detail: {
            bookingId: data.bookingId,
            unitId: unitId
          }
        });
        document.dispatchEvent(customEvent);
      }

      // Handle navigation
      if (data.type === 'navigate' && data.url) {
        window.location.href = data.url;
      }
    });
  });

  console.log('[BookBed] Widget loaded successfully');
})();
