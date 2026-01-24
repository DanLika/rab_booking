// Firebase Messaging Service Worker
// This service worker handles background push notifications for web

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
// These values must match your firebase_options.dart web config
firebase.initializeApp({
  apiKey: 'AIzaSyB2J8MaHvIU1sw4ItO3tzsn5LC9pDvgD5s',
  appId: '1:592597958982:web:7703de3f5a2ab47dd3e547',
  messagingSenderId: '592597958982',
  projectId: 'rab-booking-248fc',
  authDomain: 'rab-booking-248fc.firebaseapp.com',
  storageBucket: 'rab-booking-248fc.firebasestorage.app',
});

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
    // Actions for the notification
    actions: payload.data?.bookingId ? [
      { action: 'view', title: 'View Booking' }
    ] : [],
    // Require interaction on desktop (notification stays until clicked)
    requireInteraction: true,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked:', event);

  event.notification.close();

  const bookingId = event.notification.data?.bookingId;
  const action = event.action;

  // Build the URL to open
  let urlToOpen = '/owner/bookings';
  if (bookingId) {
    urlToOpen = `/owner/bookings?booking=${bookingId}`;
  }

  // Open the app or focus existing window
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // Check if there's already a window open
      for (const client of windowClients) {
        // Proper URL hostname check to prevent URL substring attacks (CWE-20)
        let isBookBedWindow = false;
        try {
          const clientUrl = new URL(client.url);
          isBookBedWindow = clientUrl.hostname === 'app.bookbed.io' ||
                           clientUrl.hostname === 'localhost';
        } catch (e) {
          // Invalid URL, skip this client
        }
        if (isBookBedWindow && 'focus' in client) {
          // Navigate existing window to the booking
          client.postMessage({
            type: 'NOTIFICATION_CLICK',
            bookingId: bookingId,
          });
          return client.focus();
        }
      }
      // No window open, open a new one
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
