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

  // ============================================
  // CONFIGURATION & VALIDATION
  // ============================================

  /**
   * Validate and sanitize the widget base URL
   * SECURITY: Prevents XSS via malicious window.BOOKBED_WIDGET_URL
   * @param {string} url - URL to validate
   * @returns {string} Safe URL or default
   */
  function validateBaseUrl(url) {
    if (!url || typeof url !== 'string') {
      return 'https://bookbed.io';
    }
    try {
      const parsed = new URL(url);
      // Only allow HTTPS URLs (or HTTP for localhost development)
      if (parsed.protocol === 'https:' ||
          (parsed.protocol === 'http:' && parsed.hostname === 'localhost')) {
        return parsed.origin;
      }
    } catch (e) {
      // Invalid URL
    }
    console.warn('[BookBed] Invalid BOOKBED_WIDGET_URL, using default');
    return 'https://bookbed.io';
  }

  const WIDGET_BASE_URL = validateBaseUrl(window.BOOKBED_WIDGET_URL) || 'https://bookbed.io';

  /**
   * Sanitize CSS dimension value to prevent injection
   * Allows: 'auto', percentages (e.g., '100%'), pixels (e.g., '800px'), numbers
   * @param {string} value - The CSS value to sanitize
   * @param {string} defaultValue - Fallback if invalid
   * @returns {string} Safe CSS value
   */
  function sanitizeCssDimension(value, defaultValue) {
    if (!value || typeof value !== 'string') {
      return defaultValue;
    }
    // Allow: 'auto', numbers, percentages, px/em/rem/vh/vw units
    const safePattern = /^(auto|\d+(\.\d+)?(px|em|rem|%|vh|vw)?)$/i;
    if (safePattern.test(value.trim())) {
      return value.trim();
    }
    console.warn('[BookBed] Invalid CSS dimension value: ' + value + ', using default: ' + defaultValue);
    return defaultValue;
  }

  /**
   * Add spinner animation styles (only once)
   * FIX #12/#30: Prevents duplicate <style> elements
   */
  function ensureSpinnerStyles() {
    const styleId = 'bookbed-spinner-style';
    if (document.getElementById(styleId)) {
      return; // Already exists
    }
    // FIX #28: Check if document.head exists
    if (!document.head) {
      console.warn('[BookBed] document.head not available, styles may not load');
      return;
    }
    const style = document.createElement('style');
    style.id = styleId;
    style.textContent = '@keyframes bookbed-spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }';
    document.head.appendChild(style);
  }

  // ============================================
  // WIDGET INITIALIZATION
  // ============================================

  // Find all widget containers (support both old and new selectors)
  const containers = document.querySelectorAll('#bookbed-widget, [data-bookbed]');

  if (containers.length === 0) {
    console.warn('[BookBed] No widget container found. Add <div id="bookbed-widget" data-property-id="..." data-unit-id="..."></div> to your HTML.');
    return;
  }

  // Add spinner styles once (not per container)
  ensureSpinnerStyles();

  // Store all created iframes for message routing
  const iframeMap = new Map();

  containers.forEach(function(container) {
    // FIX #15: Check if container already has an iframe (prevents duplicates on re-run)
    if (container.querySelector('iframe[data-bookbed-widget]')) {
      console.warn('[BookBed] Container already has a widget, skipping');
      return;
    }

    // Get configuration from data attributes
    const propertyId = container.getAttribute('data-property-id') || container.getAttribute('data-property');
    const unitId = container.getAttribute('data-unit-id') || container.getAttribute('data-unit');
    const theme = container.getAttribute('data-theme') || 'light';
    // Sanitize CSS dimensions to prevent injection attacks
    const height = sanitizeCssDimension(container.getAttribute('data-height'), 'auto');
    const width = sanitizeCssDimension(container.getAttribute('data-width'), '100%');

    // FIX #27: Use textContent instead of innerHTML for error messages (prevents XSS)
    if (!propertyId) {
      console.error('[BookBed] Missing data-property-id attribute on widget container');
      const errorP = document.createElement('p');
      errorP.style.cssText = 'color: red; padding: 20px; border: 1px solid red;';
      errorP.textContent = 'Error: Missing data-property-id attribute';
      container.appendChild(errorP);
      return;
    }

    if (!unitId) {
      console.error('[BookBed] Missing data-unit-id attribute on widget container');
      const errorP = document.createElement('p');
      errorP.style.cssText = 'color: red; padding: 20px; border: 1px solid red;';
      errorP.textContent = 'Error: Missing data-unit-id attribute';
      container.appendChild(errorP);
      return;
    }

    // Build iframe URL with query parameters
    const params = new URLSearchParams({
      property: propertyId,
      unit: unitId,
      theme: theme,
      embed: 'true'
    });

    const iframeUrl = WIDGET_BASE_URL + '/?' + params.toString();

    // Create iframe
    const iframe = document.createElement('iframe');
    iframe.src = iframeUrl;
    iframe.style.width = width;
    // FIX #19: Hide iframe initially to prevent flash before load
    iframe.style.display = 'none';

    // Dynamic height calculation based on ACTUAL month calendar structure
    const screenWidth = window.innerWidth;
    const maxCalendarWidth = screenWidth >= 1024 ? 650 : 600;

    // Horizontal padding (matches Flutter basePadding logic)
    let horizontalPadding;
    if (screenWidth < 600) {
      horizontalPadding = 12;
    } else if (screenWidth < 1024) {
      horizontalPadding = 16;
    } else if (screenWidth > 1400) {
      horizontalPadding = 48;
    } else {
      horizontalPadding = 24;
    }

    // Calculate calendar dimensions
    const availableWidth = screenWidth - (horizontalPadding * 2);
    const calendarWidth = Math.min(availableWidth, maxCalendarWidth);
    const cellWidth = calendarWidth / 7;
    const aspectRatio = screenWidth < 600 ? 1.0 : 0.95;
    const cellHeight = cellWidth / aspectRatio;
    const weeksCount = 6;
    const cellGap = 2;
    const gridHeight = (cellHeight * weeksCount) + (cellGap * (weeksCount - 1));
    const headerRowHeight = 40;
    const calendarComponentHeight = gridHeight + headerRowHeight;
    const extraHeight = 280;
    const autoHeight = Math.round(calendarComponentHeight + extraHeight) + 'px';

    iframe.style.height = height === 'auto' ? autoHeight : height;
    iframe.style.border = 'none';
    iframe.style.transition = 'height 0.2s ease-out';
    iframe.setAttribute('allowfullscreen', 'true');
    iframe.setAttribute('loading', 'lazy');
    iframe.setAttribute('title', 'BookBed Booking Widget');
    // FIX #82: Add Permissions Policy for Payment Request API (Stripe)
    iframe.setAttribute('allow', 'payment');
    // Mark iframe as BookBed widget for duplicate detection
    iframe.setAttribute('data-bookbed-widget', 'true');
    iframe.setAttribute('data-unit-id', unitId);

    // Add loading indicator
    const initialHeight = height === 'auto' ? autoHeight : height;
    const loader = document.createElement('div');
    loader.style.cssText = 'display: flex; align-items: center; justify-content: center; height: ' + initialHeight + '; background: #f5f5f5; color: #666; font-family: sans-serif;';
    loader.innerHTML = '<div style="text-align: center;"><div style="width: 40px; height: 40px; border: 4px solid #e0e0e0; border-top-color: #2196F3; border-radius: 50%; animation: bookbed-spin 1s linear infinite; margin: 0 auto 12px;"></div><p>Loading booking widget...</p></div>';

    container.appendChild(loader);
    container.appendChild(iframe);

    // Store iframe reference for message routing
    iframeMap.set(unitId, { iframe: iframe, propertyId: propertyId });

    // Replace loader with iframe when loaded
    iframe.addEventListener('load', function() {
      loader.style.display = 'none';
      iframe.style.display = 'block';
    });

    iframe.addEventListener('error', function() {
      // FIX #27: Use textContent for error content
      loader.innerHTML = '';
      const errorP = document.createElement('p');
      errorP.style.cssText = 'color: red; padding: 20px;';
      errorP.textContent = 'Failed to load booking widget. Please try again later.';
      loader.appendChild(errorP);
    });
  });

  // ============================================
  // MESSAGE HANDLING (SINGLE GLOBAL LISTENER)
  // ============================================
  // FIX #13: Single message listener instead of one per container

  window.addEventListener('message', function(event) {
    // Verify origin for security - allow bookbed.io and subdomains only
    // SECURITY: Use exact match or endsWith to prevent spoofing
    const isBookBedOrigin = event.origin === WIDGET_BASE_URL ||
                            event.origin === 'https://bookbed.io' ||
                            event.origin === 'https://view.bookbed.io' ||
                            event.origin.endsWith('.bookbed.io');

    if (!isBookBedOrigin) {
      return;
    }

    const data = event.data;

    // Verify message is an object with expected source
    // SECURITY: Prevents errors if data is primitive
    if (typeof data !== 'object' || data === null || data.source !== 'bookbed-widget') {
      return;
    }

    // Find the target iframe based on unitId in message or use source window
    let targetInfo = null;
    if (data.unitId && iframeMap.has(data.unitId)) {
      targetInfo = iframeMap.get(data.unitId);
    } else {
      // Fallback: find iframe by checking contentWindow
      for (const [unitId, info] of iframeMap.entries()) {
        if (info.iframe.contentWindow === event.source) {
          targetInfo = info;
          break;
        }
      }
    }

    if (!targetInfo) {
      return;
    }

    const { iframe, propertyId, unitId } = targetInfo;

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

  console.log('[BookBed] Widget loaded successfully');
})();
