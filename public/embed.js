/**
 * BookBed Widget - Embed Script
 *
 * Usage:
 *
 * <!-- On your website -->
 * <div id="bookbed-widget"
 *      data-property-id="YOUR_PROPERTY_ID"
 *      data-unit-id="YOUR_UNIT_ID">
 * </div>
 * <script src="https://bookbed.io/embed.js"></script>
 *
 * Or with custom configuration:
 *
 * <div id="bookbed-widget"
 *      data-property-id="YOUR_PROPERTY_ID"
 *      data-unit-id="YOUR_UNIT_ID"
 *      data-theme="light"
 *      data-height="auto">
 * </div>
 * <script src="https://bookbed.io/embed.js"></script>
 *
 * Attributes:
 * - data-property-id: (required) Your property ID from BookBed dashboard
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
  const containers = document.querySelectorAll('#bookbed-widget, [data-bookbed]');

  if (containers.length === 0) {
    console.warn('[BookBed] No widget container found. Add <div id="bookbed-widget" data-property-id="..." data-unit-id="..."></div> to your HTML.');
    return;
  }

  containers.forEach(function(container) {
    // Get configuration from data attributes
    const propertyId = container.getAttribute('data-property-id') || container.getAttribute('data-property');
    const unitId = container.getAttribute('data-unit-id') || container.getAttribute('data-unit');
    const theme = container.getAttribute('data-theme') || 'light';
    // Note: locale removed - widget has its own language selector
    const height = container.getAttribute('data-height') || 'auto';
    const width = container.getAttribute('data-width') || '100%';

    if (!propertyId) {
      console.error('[BookBed] Missing data-property-id attribute on widget container');
      container.innerHTML = '<p style="color: red; padding: 20px; border: 1px solid red;">Error: Missing data-property-id attribute</p>';
      return;
    }

    if (!unitId) {
      console.error('[BookBed] Missing data-unit-id attribute on widget container');
      container.innerHTML = '<p style="color: red; padding: 20px; border: 1px solid red;">Error: Missing data-unit-id attribute</p>';
      return;
    }

    // Build iframe URL with query parameters
    // Uses /?property=PROPERTY_ID&unit=UNIT_ID format for efficient queries
    const params = new URLSearchParams({
      property: propertyId,
      unit: unitId,
      theme: theme,
      embed: 'true'
    });

    const iframeUrl = `${WIDGET_BASE_URL}/?${params.toString()}`;

    // Create iframe
    const iframe = document.createElement('iframe');
    iframe.src = iframeUrl;
    iframe.style.width = width;
    // Dynamic height calculation based on ACTUAL month calendar structure
    // Month calendar: 7 columns (days) x 6 rows (weeks) + header row
    const screenWidth = window.innerWidth;

    // Calendar max width constraints (matches Flutter widget)
    const maxCalendarWidth = screenWidth >= 1024 ? 650 : 600;

    // Horizontal padding (matches Flutter basePadding logic)
    let horizontalPadding;
    if (screenWidth < 600) {
      horizontalPadding = 12;      // Mobile
    } else if (screenWidth < 1024) {
      horizontalPadding = 16;      // Tablet
    } else if (screenWidth > 1400) {
      horizontalPadding = 48;      // Large screen
    } else {
      horizontalPadding = 24;      // Desktop
    }

    // Calculate calendar width (constrained by max width)
    const availableWidth = screenWidth - (horizontalPadding * 2);
    const calendarWidth = Math.min(availableWidth, maxCalendarWidth);

    // Cell dimensions (matches Flutter GridView)
    const cellWidth = calendarWidth / 7;
    const aspectRatio = screenWidth < 600 ? 1.0 : 0.95; // mobile: square, desktop: slightly taller
    const cellHeight = cellWidth / aspectRatio;

    // Grid height: 6 rows (max weeks) + gaps between cells (~2px each)
    const weeksCount = 6;
    const cellGap = 2;
    const gridHeight = (cellHeight * weeksCount) + (cellGap * (weeksCount - 1));

    // Weekday header row (~40px)
    const headerRowHeight = 40;

    // Total calendar component height
    const calendarComponentHeight = gridHeight + headerRowHeight;

    // Extra height: widget header (~70px), legend (~60px), contact card (~60px), vertical padding/margins (~90px)
    const extraHeight = 280;

    // Final widget height
    const autoHeight = Math.round(calendarComponentHeight + extraHeight) + 'px';
    iframe.style.height = height === 'auto' ? autoHeight : height; // Initial height, will auto-resize
    iframe.style.border = 'none';
    iframe.style.display = 'block';
    iframe.style.transition = 'height 0.2s ease-out'; // Smooth height transitions
    iframe.setAttribute('allowfullscreen', 'true');
    iframe.setAttribute('loading', 'lazy');
    iframe.setAttribute('title', 'BookBed Booking Widget');

    // Add loading indicator (use same responsive height)
    const initialHeight = height === 'auto' ? autoHeight : height;
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
            propertyId: propertyId,
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
