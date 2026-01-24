/**
 * Payment Bridge for Stripe Checkout in Embedded Iframes
 * 
 * Handles popup window opening, cross-tab communication, and mobile fallbacks
 * for Stripe Checkout when widget is embedded in iframe.
 */

(function() {
  'use strict';

  window.PaymentBridge = {
    channel: null,
    popupWindow: null,
    _paymentCallback: null,
    _popupPollInterval: null,

    /**
     * Initialize payment bridge
     */
    init: function() {
      try {
        // Try BroadcastChannel (best for same-origin communication)
        this.channel = new BroadcastChannel('bookbed-payment');
        console.log('[PaymentBridge] Initialized with BroadcastChannel');
      } catch (e) {
        console.log('[PaymentBridge] BroadcastChannel not supported, using fallbacks');
      }
      
      this._setupMessageListener();
      this._setupStorageListener();
    },

    /**
     * Check if running inside an iframe
     */
    isInIframe: function() {
      try {
        return window.self !== window.top;
      } catch (e) {
        return true; // Cross-origin iframe
      }
    },

    /**
     * Detect mobile device
     */
    isMobile: function() {
      return /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
    },

    /**
     * Detect mobile Safari specifically
     */
    isMobileSafari: function() {
      return /iP(ad|hone|od).+Safari/i.test(navigator.userAgent) &&
             !/(Chrome|CriOS|FxiOS)/i.test(navigator.userAgent);
    },

    /**
     * Save booking state before redirect/popup
     */
    saveBookingState: function(bookingDataJson) {
      try {
        sessionStorage.setItem('pending_booking', bookingDataJson);
        // Backup to localStorage (survives longer)
        localStorage.setItem('pending_booking_backup', bookingDataJson);
        console.log('[PaymentBridge] Booking state saved');
      } catch (e) {
        console.error('[PaymentBridge] Failed to save booking state:', e);
      }
    },

    /**
     * Pre-open popup with loading page (CRITICAL: call synchronously on user click)
     * Then update URL after async checkout session creation
     *
     * @returns {string} 'popup', 'redirect', or 'blocked'
     */
    preOpenPaymentPopup: function() {
      // Mobile Safari: will use redirect later
      if (this.isMobileSafari()) {
        return 'redirect';
      }

      // Mobile (non-Safari): try popup first
      if (this.isMobile()) {
        const popup = this._openPopup(this._getLoadingPageUrl());
        if (popup === 'blocked') {
          return 'redirect';
        }
        return 'popup';
      }

      // Desktop: open popup with loading page
      return this._openPopup(this._getLoadingPageUrl());
    },

    /**
     * Generate a data URL for a loading page to show while checkout session is being created
     * @returns {string} Data URL with loading spinner
     */
    _getLoadingPageUrl: function() {
      const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Preparing Payment...</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: white;
    }
    .container {
      text-align: center;
      padding: 40px;
    }
    .spinner {
      width: 60px;
      height: 60px;
      border: 4px solid rgba(255,255,255,0.3);
      border-top-color: white;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 0 auto 30px;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    h1 {
      font-size: 24px;
      font-weight: 600;
      margin-bottom: 12px;
    }
    p {
      font-size: 16px;
      opacity: 0.9;
      max-width: 300px;
    }
    .stripe-badge {
      margin-top: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      font-size: 14px;
      opacity: 0.8;
    }
    .lock-icon {
      width: 16px;
      height: 16px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="spinner"></div>
    <h1>Preparing Payment</h1>
    <p>Setting up secure checkout with Stripe...</p>
    <div class="stripe-badge">
      <svg class="lock-icon" viewBox="0 0 24 24" fill="currentColor">
        <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
      </svg>
      Secured by Stripe
    </div>
  </div>
</body>
</html>`;
      return 'data:text/html;charset=utf-8,' + encodeURIComponent(html);
    },

    /**
     * Update popup URL (call after async checkout session creation)
     * 
     * @param {string} url - Stripe checkout URL
     */
    updatePaymentPopupUrl: function(url) {
      if (!this.popupWindow || this.popupWindow.closed) {
        console.error('[PaymentBridge] Popup not available for URL update');
        return false;
      }

      try {
        this.popupWindow.location.href = url;
        console.log('[PaymentBridge] Popup URL updated');
        return true;
      } catch (e) {
        console.error('[PaymentBridge] Failed to update popup URL:', e);
        // Popup might have navigated away - try redirect
        try {
          window.top.location.href = url;
          return true;
        } catch (e2) {
          window.location.href = url;
          return true;
        }
      }
    },

    /**
     * Open payment popup or redirect
     * CRITICAL: Must be called synchronously on user click
     * 
     * @param {string} url - Stripe checkout URL
     * @returns {string} 'popup', 'redirect', or 'blocked'
     */
    openPayment: function(url) {
      if (!url) {
        console.error('[PaymentBridge] No URL provided');
        return 'error';
      }

      // Mobile Safari: prefer redirect (popups are more likely blocked)
      if (this.isMobileSafari()) {
        console.log('[PaymentBridge] Mobile Safari detected - using redirect');
        try {
          window.top.location.href = url;
          return 'redirect';
        } catch (e) {
          // Cross-origin error - fallback to same window
          window.location.href = url;
          return 'redirect';
        }
      }

      // Mobile (non-Safari): try popup first, fallback to redirect
      if (this.isMobile()) {
        console.log('[PaymentBridge] Mobile device detected - trying popup');
        const popup = this._openPopup(url);
        if (popup === 'blocked') {
          // Fallback to redirect
          console.log('[PaymentBridge] Popup blocked on mobile - using redirect');
          try {
            window.top.location.href = url;
            return 'redirect';
          } catch (e) {
            window.location.href = url;
            return 'redirect';
          }
        }
        return popup;
      }

      // Desktop: use popup
      return this._openPopup(url);
    },

    /**
     * Open popup window (internal helper)
     */
    _openPopup: function(url) {
      // Calculate centered position
      const width = 600;
      const height = 700;
      const left = Math.round((window.screen.width / 2) - (width / 2));
      const top = Math.round((window.screen.height / 2) - (height / 2));

      const features = [
        'width=' + width,
        'height=' + height,
        'left=' + left,
        'top=' + top,
        'menubar=no',
        'toolbar=no',
        'location=no',
        'status=no',
        'resizable=yes',
        'scrollbars=yes'
      ].join(',');

      try {
        this.popupWindow = window.open(url, 'BookBedPayment', features);

        // Check if popup was blocked
        if (!this.popupWindow || this.popupWindow.closed || typeof this.popupWindow.closed === 'undefined') {
          console.warn('[PaymentBridge] Popup blocked by browser');
          return 'blocked';
        }

        console.log('[PaymentBridge] Popup opened successfully');
        
        // Start monitoring popup
        this._monitorPopup();

        return 'popup';
      } catch (e) {
        console.error('[PaymentBridge] Error opening popup:', e);
        return 'blocked';
      }
    },

    /**
     * Monitor popup window for closure
     */
    _monitorPopup: function() {
      if (!this.popupWindow) return;

      // Clear any existing interval
      if (this._popupPollInterval) {
        clearInterval(this._popupPollInterval);
      }

      // Poll to check if popup is closed
      this._popupPollInterval = setInterval(function() {
        try {
          if (this.popupWindow.closed) {
            clearInterval(this._popupPollInterval);
            this._popupPollInterval = null;
            console.log('[PaymentBridge] Popup window closed');
            
            // Notify callback if payment wasn't completed
            // (payment completion will be notified via BroadcastChannel/postMessage)
            if (this._paymentCallback) {
              // Small delay to allow payment completion message to arrive first
              setTimeout(function() {
                // Check if we received payment completion (this is handled by message listeners)
                // If not, we could notify about popup closure
              }, 1000);
            }
          }
        } catch (e) {
          // Cross-origin error - popup navigated away (expected)
          // Continue monitoring
        }
      }.bind(this), 500);
    },

    /**
     * Allowed origins for postMessage communication
     * SECURITY: Only send messages to trusted BookBed origins
     */
    _trustedOrigins: [
      'https://view.bookbed.io',
      'https://app.bookbed.io',
      'https://bookbed.io'
    ],

    /**
     * Get the appropriate target origin for postMessage
     * SECURITY: Uses specific origin when possible, falls back to '*' only for
     * cross-origin iframe scenarios where parent origin is unknown
     */
    _getTargetOrigin: function(targetWindow) {
      // For localhost development
      if (window.location.hostname === 'localhost') {
        return '*'; // Dev mode - allow any origin
      }

      // Try to determine if target is a BookBed origin
      try {
        // If we can access the origin, use it if trusted
        var targetOrigin = targetWindow.location.origin;
        if (this._trustedOrigins.indexOf(targetOrigin) !== -1 ||
            targetOrigin.endsWith('.bookbed.io')) {
          return targetOrigin;
        }
      } catch (e) {
        // Cross-origin - can't access location
        // For opener (popup -> widget), we know it's view.bookbed.io
        if (targetWindow === window.opener) {
          return 'https://view.bookbed.io';
        }
      }

      // For parent/top in embedded iframe scenarios, parent could be any website
      // We must use '*' but the data is not sensitive (just sessionId and status)
      // The receiving widget validates the message source
      return '*';
    },

    /**
     * Notify payment completion (called from payment success page)
     * Uses multiple methods for cross-origin reliability:
     * 1. postMessage to opener (popup -> iframe parent)
     * 2. postMessage to parent (iframe -> parent)
     * 3. BroadcastChannel (same-origin tabs)
     * 4. localStorage (Safari fallback)
     *
     * PRIORITY: postMessage is tried first as it works across origins
     * SECURITY: Uses specific target origin where known, '*' only when necessary
     */
    notifyComplete: function(sessionId, status) {
      const message = {
        type: 'PAYMENT_COMPLETE',
        source: 'bookbed-widget',
        sessionId: sessionId,
        status: status,
        timestamp: Date.now()
      };

      // Also send as 'stripe-payment-complete' for Flutter widget compatibility
      const flutterMessage = {
        type: 'stripe-payment-complete',
        source: 'bookbed-widget',
        sessionId: sessionId,
        status: status,
        timestamp: Date.now()
      };

      console.log('[PaymentBridge] Notifying payment complete:', message);

      let successCount = 0;

      // Method 1: postMessage to opener (PRIORITY - works cross-origin)
      // This is the primary method for popup -> iframe communication
      if (window.opener && !window.opener.closed) {
        try {
          // SECURITY: Use specific origin for opener (known to be view.bookbed.io)
          var openerOrigin = this._getTargetOrigin(window.opener);
          // Send both message formats for compatibility
          window.opener.postMessage(message, openerOrigin);
          window.opener.postMessage(flutterMessage, openerOrigin);
          console.log('[PaymentBridge] Sent via postMessage to opener (origin: ' + openerOrigin + ')');
          successCount++;
        } catch (e) {
          console.error('[PaymentBridge] postMessage to opener error:', e);
        }
      }

      // Method 2: postMessage to parent (for nested iframe scenarios)
      if (window.parent && window.parent !== window) {
        try {
          // SECURITY: Determine target origin (may be '*' for cross-origin iframes)
          var parentOrigin = this._getTargetOrigin(window.parent);
          window.parent.postMessage(message, parentOrigin);
          window.parent.postMessage(flutterMessage, parentOrigin);
          console.log('[PaymentBridge] Sent via postMessage to parent (origin: ' + parentOrigin + ')');
          successCount++;
        } catch (e) {
          console.error('[PaymentBridge] postMessage to parent error:', e);
        }
      }

      // Method 3: postMessage to top (for deeply nested iframes)
      try {
        if (window.top && window.top !== window && window.top !== window.parent) {
          var topOrigin = this._getTargetOrigin(window.top);
          window.top.postMessage(message, topOrigin);
          window.top.postMessage(flutterMessage, topOrigin);
          console.log('[PaymentBridge] Sent via postMessage to top (origin: ' + topOrigin + ')');
          successCount++;
        }
      } catch (e) {
        // Cross-origin top - ignore silently (expected)
      }

      // Method 4: BroadcastChannel (same-origin backup)
      if (this.channel) {
        try {
          this.channel.postMessage(message);
          console.log('[PaymentBridge] Sent via BroadcastChannel');
          successCount++;
        } catch (e) {
          console.error('[PaymentBridge] BroadcastChannel error:', e);
        }
      }

      // Method 5: localStorage fallback (for Safari)
      try {
        localStorage.setItem('payment_complete', JSON.stringify(message));
        // Remove immediately to trigger storage event
        setTimeout(function() {
          localStorage.removeItem('payment_complete');
        }, 100);
        console.log('[PaymentBridge] Sent via localStorage');
        successCount++;
      } catch (e) {
        console.error('[PaymentBridge] localStorage error:', e);
      }

      // Retry postMessage multiple times for reliability
      // Cross-origin messages can be lost if receiver isn't ready
      var retryCount = 0;
      var maxRetries = 3;
      var self = this;
      var retryInterval = setInterval(function() {
        retryCount++;
        if (retryCount > maxRetries) {
          clearInterval(retryInterval);
          return;
        }

        console.log('[PaymentBridge] Retry #' + retryCount + ' postMessage...');

        if (window.opener && !window.opener.closed) {
          try {
            var openerOrigin = self._getTargetOrigin(window.opener);
            window.opener.postMessage(message, openerOrigin);
            window.opener.postMessage(flutterMessage, openerOrigin);
          } catch (e) {}
        }
        if (window.parent && window.parent !== window) {
          try {
            var parentOrigin = self._getTargetOrigin(window.parent);
            window.parent.postMessage(message, parentOrigin);
            window.parent.postMessage(flutterMessage, parentOrigin);
          } catch (e) {}
        }
      }, 500);

      // Close popup after delay (if we're in a popup)
      if (window.opener) {
        setTimeout(function() {
          clearInterval(retryInterval); // Stop retries before closing
          try {
            window.close();
            console.log('[PaymentBridge] Popup closed');
          } catch (e) {
            console.log('[PaymentBridge] Could not close popup:', e);
          }
        }, 2000);
      }
    },

    /**
     * Register callback for payment results
     */
    onPaymentResult: function(callback) {
      this._paymentCallback = callback;
    },

    /**
     * Setup message listeners
     */
    _setupMessageListener: function() {
      // BroadcastChannel listener
      if (this.channel) {
        this.channel.onmessage = function(event) {
          if (event.data && event.data.type === 'PAYMENT_COMPLETE') {
            this._handleResult(event.data);
          }
        }.bind(this);
      }

      // postMessage listener
      window.addEventListener('message', function(event) {
        // SECURITY: Verify origin is trusted before processing
        // Use URL parsing for proper hostname validation (CWE-20)
        var isLocalhost = false;
        var isBookBedOrigin = false;

        try {
          var originUrl = new URL(event.origin);
          var hostname = originUrl.hostname;

          // Check for localhost
          isLocalhost = hostname === 'localhost' || hostname === '127.0.0.1';

          // Check for exact BookBed domains or proper subdomain matching
          // SECURITY: hostname.endsWith() ensures the check is at the end,
          // preventing attacks like "evil.bookbed.io.attacker.com"
          isBookBedOrigin = hostname === 'view.bookbed.io' ||
                            hostname === 'app.bookbed.io' ||
                            hostname === 'bookbed.io' ||
                            hostname.endsWith('.bookbed.io');
        } catch (e) {
          // Invalid origin URL - reject
          return;
        }

        if (!isLocalhost && !isBookBedOrigin) {
          // Ignore messages from untrusted origins
          return;
        }

        // Verify message structure
        if (event.data && event.data.type === 'PAYMENT_COMPLETE') {
          this._handleResult(event.data);
        }
      }.bind(this));
    },

    /**
     * Setup localStorage event listener (Safari fallback)
     */
    _setupStorageListener: function() {
      window.addEventListener('storage', function(event) {
        if (event.key === 'payment_complete' && event.newValue) {
          try {
            const data = JSON.parse(event.newValue);
            if (data.type === 'PAYMENT_COMPLETE') {
              this._handleResult(data);
            }
          } catch (e) {
            console.error('[PaymentBridge] Failed to parse storage event:', e);
          }
        }
      }.bind(this));
    },

    // Track processed session IDs to avoid duplicate handling
    _processedSessions: {},

    // FIX #60: Track cleanup timeouts for proper disposal
    _cleanupTimeouts: [],

    // FIX #61: Maximum number of tracked sessions to prevent unbounded growth
    _maxProcessedSessions: 100,

    /**
     * Handle payment result (with deduplication)
     */
    _handleResult: function(data) {
      console.log('[PaymentBridge] Payment result received:', data);

      // Deduplication: ignore if we've already processed this sessionId
      if (data.sessionId && this._processedSessions[data.sessionId]) {
        console.log('[PaymentBridge] Ignoring duplicate message for session:', data.sessionId);
        return;
      }

      // Mark as processed (with TTL of 60 seconds)
      if (data.sessionId) {
        // FIX #61: Cap at max size to prevent unbounded growth
        var sessionIds = Object.keys(this._processedSessions);
        if (sessionIds.length >= this._maxProcessedSessions) {
          // Remove oldest entry
          var oldest = sessionIds.reduce(function(min, id) {
            return this._processedSessions[id] < this._processedSessions[min] ? id : min;
          }.bind(this));
          delete this._processedSessions[oldest];
        }

        this._processedSessions[data.sessionId] = Date.now();

        // FIX #60: Store timeout ID for cleanup in dispose()
        var timeoutId = setTimeout(function() {
          delete this._processedSessions[data.sessionId];
          // Remove from cleanup array
          var index = this._cleanupTimeouts.indexOf(timeoutId);
          if (index > -1) {
            this._cleanupTimeouts.splice(index, 1);
          }
        }.bind(this), 60000);
        this._cleanupTimeouts.push(timeoutId);
      }

      if (this._paymentCallback) {
        try {
          // Call callback with JSON string (for Dart interop)
          this._paymentCallback(JSON.stringify(data));
        } catch (e) {
          console.error('[PaymentBridge] Callback error:', e);
        }
      }
    },

    /**
     * Cleanup resources
     */
    dispose: function() {
      if (this._popupPollInterval) {
        clearInterval(this._popupPollInterval);
        this._popupPollInterval = null;
      }

      if (this.channel) {
        this.channel.close();
        this.channel = null;
      }

      // FIX #60: Clear all pending cleanup timeouts
      if (this._cleanupTimeouts && this._cleanupTimeouts.length > 0) {
        this._cleanupTimeouts.forEach(function(timeoutId) {
          clearTimeout(timeoutId);
        });
        this._cleanupTimeouts = [];
      }

      // Clear processed sessions
      this._processedSessions = {};

      this._paymentCallback = null;
    }
  };

  // Auto-initialize
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      window.PaymentBridge.init();
    });
  } else {
    window.PaymentBridge.init();
  }
})();
