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
     * Pre-open popup with placeholder URL (CRITICAL: call synchronously on user click)
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
        const popup = this._openPopup('about:blank');
        if (popup === 'blocked') {
          return 'redirect';
        }
        return 'popup';
      }

      // Desktop: open popup with placeholder
      return this._openPopup('about:blank');
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
     * Notify payment completion (called from payment success page)
     */
    notifyComplete: function(sessionId, status) {
      const message = {
        type: 'PAYMENT_COMPLETE',
        sessionId: sessionId,
        status: status,
        timestamp: Date.now()
      };

      console.log('[PaymentBridge] Notifying payment complete:', message);

      // Method 1: BroadcastChannel (same-origin)
      if (this.channel) {
        try {
          this.channel.postMessage(message);
          console.log('[PaymentBridge] Sent via BroadcastChannel');
        } catch (e) {
          console.error('[PaymentBridge] BroadcastChannel error:', e);
        }
      }

      // Method 2: postMessage to opener (for popup scenarios)
      if (window.opener && !window.opener.closed) {
        try {
          window.opener.postMessage(message, '*');
          console.log('[PaymentBridge] Sent via postMessage to opener');
        } catch (e) {
          console.error('[PaymentBridge] postMessage error:', e);
        }
      }

      // Method 3: postMessage to parent (for iframe scenarios)
      if (window.parent && window.parent !== window) {
        try {
          window.parent.postMessage(message, '*');
          console.log('[PaymentBridge] Sent via postMessage to parent');
        } catch (e) {
          console.error('[PaymentBridge] postMessage to parent error:', e);
        }
      }

      // Method 4: localStorage fallback (for Safari)
      try {
        localStorage.setItem('payment_complete', JSON.stringify(message));
        // Remove immediately to trigger storage event
        setTimeout(function() {
          localStorage.removeItem('payment_complete');
        }, 100);
        console.log('[PaymentBridge] Sent via localStorage');
      } catch (e) {
        console.error('[PaymentBridge] localStorage error:', e);
      }

      // Close popup after delay (if we're in a popup)
      if (window.opener) {
        setTimeout(function() {
          try {
            window.close();
            console.log('[PaymentBridge] Popup closed');
          } catch (e) {
            console.log('[PaymentBridge] Could not close popup:', e);
          }
        }, 1500);
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
        // Verify message structure
        if (event.data && event.data.type === 'PAYMENT_COMPLETE') {
          // In production, you might want to verify event.origin
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

    /**
     * Handle payment result
     */
    _handleResult: function(data) {
      console.log('[PaymentBridge] Payment result received:', data);
      
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
