// Firebase Messaging Service Worker
// Background push notifications for web (PWA).
//
// IMPORTANT: This file is shared across DEV / STAGING / PROD hosting sites.
// The Firebase config is selected at runtime by matching `self.location.hostname`
// against known per-env hosts. Hostnames here must stay in sync with
// `lib/core/config/environment.dart` (dashboardHost / widgetHost) and
// `lib/firebase_options{,_dev,_staging}.dart` (web blocks).
//
// Mismatch class: audit/33 §11.4 — DEV hosting was registering FCM tokens
// against PROD project because this file was hardcoded to rab-booking-248fc.
// FCM API returned 401 UNAUTHENTICATED on bookbed-dev origin.

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Firebase web `apiKey` is a PUBLIC client identifier, not a secret.
// Access is enforced by Firebase Auth + Firestore/Storage Security Rules.
// See: https://firebase.google.com/docs/projects/api-keys#api-keys-for-firebase-are-different
// These values mirror lib/firebase_options{,_dev,_staging}.dart (web blocks) and
// MUST stay in sync with them. Treated as public — committed in repo intentionally.
const FIREBASE_CONFIGS = {
  production: {
    // nosemgrep: generic.secrets.security.detected-generic-api-key.detected-generic-api-key
    apiKey: 'AIzaSyB2J8MaHvIU1sw4ItO3tzsn5LC9pDvgD5s',
    appId: '1:592597958982:web:7703de3f5a2ab47dd3e547',
    messagingSenderId: '592597958982',
    projectId: 'rab-booking-248fc',
    authDomain: 'rab-booking-248fc.firebaseapp.com',
    storageBucket: 'rab-booking-248fc.firebasestorage.app',
  },
  staging: {
    // nosemgrep: generic.secrets.security.detected-generic-api-key.detected-generic-api-key
    apiKey: 'AIzaSyDEayEl_0_Ne3Xwy8bEaEqI0Mybe4LTGrU',
    appId: '1:584902480248:web:767f9d3bc1837eea94f88d',
    messagingSenderId: '584902480248',
    projectId: 'bookbed-staging',
    authDomain: 'bookbed-staging.firebaseapp.com',
    storageBucket: 'bookbed-staging.firebasestorage.app',
  },
  development: {
    // nosemgrep: generic.secrets.security.detected-generic-api-key.detected-generic-api-key
    apiKey: 'AIzaSyDc6vDPLBTN3ePkY39Pw9Jrheh30OhLWEM',
    appId: '1:733027606474:web:cdac74e20c8fb05aebf933',
    messagingSenderId: '733027606474',
    projectId: 'bookbed-dev',
    authDomain: 'bookbed-dev.firebaseapp.com',
    storageBucket: 'bookbed-dev.firebasestorage.app',
  },
};

function pickEnvByHostname(host) {
  // DEV — Firebase Hosting *-dev.web.app sites + localhost dev server
  if (host === 'bookbed-owner-dev.web.app' ||
      host === 'bookbed-widget-dev.web.app' ||
      host === 'bookbed-admin-dev.web.app' ||
      host === 'localhost' ||
      host === '127.0.0.1') {
    return 'development';
  }
  // STAGING — staging subdomains + Firebase Hosting *-staging.web.app sites
  if (host === 'staging.app.bookbed.io' ||
      host === 'staging.view.bookbed.io' ||
      host === 'bookbed-owner-staging.web.app' ||
      host === 'bookbed-widget-staging.web.app' ||
      host === 'bookbed-admin-staging.web.app' ||
      host.endsWith('.staging.view.bookbed.io')) {
    return 'staging';
  }
  // PROD — apex prod hosts + client widget subdomains (*.view.bookbed.io)
  if (host === 'app.bookbed.io' ||
      host === 'view.bookbed.io' ||
      host === 'bookbed-admin.web.app' ||
      host.endsWith('.view.bookbed.io')) {
    return 'production';
  }
  // Fallback: log + default PROD (preserve legacy behavior; safest of the wrong defaults).
  console.warn('[SW] Unknown hostname ' + host + ' — defaulting Firebase config to production.');
  return 'production';
}

const SW_HOST = self.location.hostname;
const SW_ENV = pickEnvByHostname(SW_HOST);
const SW_CONFIG = FIREBASE_CONFIGS[SW_ENV];

console.log('[SW] Initializing Firebase: env=' + SW_ENV + ' project=' + SW_CONFIG.projectId + ' host=' + SW_HOST);
firebase.initializeApp(SW_CONFIG);

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Background message received:', payload);

  const notificationTitle = payload.notification?.title || 'BookBed';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.bookingId || 'default',
    data: payload.data,
    actions: payload.data?.bookingId ? [
      { action: 'view', title: 'View Booking' }
    ] : [],
    requireInteraction: true,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked:', event);

  event.notification.close();

  // F-99-16: payload is trust-bounded by FCM signing, but the id is still
  // concatenated into a URL + postMessage — shape-check as defense-in-depth.
  const rawBookingId = event.notification.data?.bookingId;
  const bookingId =
    typeof rawBookingId === 'string' && /^[A-Za-z0-9_-]{6,40}$/.test(rawBookingId)
      ? rawBookingId
      : null;

  let urlToOpen = '/owner/bookings';
  if (bookingId) {
    urlToOpen = `/owner/bookings?booking=${bookingId}`;
  }

  // Focus an existing BookBed window if one is open on this SW's origin.
  // SW scope is per-origin, so `self.location.hostname` is the right identity
  // to compare against (previously hardcoded to `app.bookbed.io`, which broke
  // notification-click focus on DEV/STAGING hosts).
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        let isBookBedWindow = false;
        try {
          const clientUrl = new URL(client.url);
          isBookBedWindow = clientUrl.hostname === SW_HOST;
        } catch (e) {
          // Invalid URL, skip this client
        }
        if (isBookBedWindow && 'focus' in client) {
          client.postMessage({
            type: 'NOTIFICATION_CLICK',
            bookingId: bookingId,
          });
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
