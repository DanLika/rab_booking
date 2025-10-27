/**
 * RAB Booking Widget - Embed Script
 *
 * Usage:
 *
 * <!-- On your website (e.g., jasko-rab.com) -->
 * <div id="rab-booking-widget" data-unit-id="YOUR_UNIT_ID"></div>
 * <script src="https://YOUR-NETLIFY-URL.netlify.app/embed.js"></script>
 *
 * Or with custom configuration:
 *
 * <div id="rab-booking-widget"
 *      data-unit-id="YOUR_UNIT_ID"
 *      data-theme="light"
 *      data-locale="hr"
 *      data-height="800px">
 * </div>
 * <script src="https://YOUR-NETLIFY-URL.netlify.app/embed.js"></script>
 */

(function() {
  'use strict';

  // Configuration
  const WIDGET_BASE_URL = window.RAB_BOOKING_WIDGET_URL || 'https://rab-booking.netlify.app';

  // Find all widget containers
  const containers = document.querySelectorAll('#rab-booking-widget, [data-rab-booking]');

  if (containers.length === 0) {
    console.warn('[RAB Booking] No widget container found. Add <div id="rab-booking-widget" data-unit-id="..."></div> to your HTML.');
    return;
  }

  containers.forEach(function(container) {
    // Get configuration from data attributes
    const unitId = container.getAttribute('data-unit-id') || container.getAttribute('data-unit');
    const theme = container.getAttribute('data-theme') || 'light';
    const locale = container.getAttribute('data-locale') || 'en';
    const height = container.getAttribute('data-height') || '800px';
    const width = container.getAttribute('data-width') || '100%';

    if (!unitId) {
      console.error('[RAB Booking] Missing data-unit-id attribute on widget container');
      container.innerHTML = '<p style="color: red; padding: 20px; border: 1px solid red;">Error: Missing data-unit-id attribute</p>';
      return;
    }

    // Build iframe URL with query parameters
    const params = new URLSearchParams({
      theme: theme,
      locale: locale,
      embed: 'true'
    });

    const iframeUrl = `${WIDGET_BASE_URL}/embed/${unitId}?${params.toString()}`;

    // Create iframe
    const iframe = document.createElement('iframe');
    iframe.src = iframeUrl;
    iframe.style.width = width;
    iframe.style.height = height;
    iframe.style.border = 'none';
    iframe.style.display = 'block';
    iframe.setAttribute('allowfullscreen', 'true');
    iframe.setAttribute('loading', 'lazy');
    iframe.setAttribute('title', 'RAB Booking Widget');

    // Add loading indicator
    const loader = document.createElement('div');
    loader.style.cssText = 'display: flex; align-items: center; justify-content: center; height: ' + height + '; background: #f5f5f5; color: #666; font-family: sans-serif;';
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

    // Listen for messages from iframe (e.g., booking completed, height changes)
    window.addEventListener('message', function(event) {
      // Verify origin for security
      if (event.origin !== WIDGET_BASE_URL && !event.origin.includes('netlify.app')) {
        return;
      }

      const data = event.data;

      // Handle height changes for responsive iframe
      if (data.type === 'resize' && data.height) {
        iframe.style.height = data.height + 'px';
      }

      // Handle booking events
      if (data.type === 'booking-completed') {
        console.log('[RAB Booking] Booking completed:', data.bookingId);

        // Dispatch custom event for parent page to listen
        const customEvent = new CustomEvent('rab-booking-completed', {
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

  console.log('[RAB Booking] Widget loaded successfully');
})();
