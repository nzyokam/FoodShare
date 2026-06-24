importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCcjwP2AP1YekF3Urg-EJ5T743-5Jsnyyc',
  appId: '1:383740409419:web:6462e232a50cc99ef33fce',
  messagingSenderId: '383740409419',
  projectId: 'foodsharing-5777b',
  authDomain: 'foodsharing-5777b.firebaseapp.com',
  storageBucket: 'foodsharing-5777b.firebasestorage.app',
});

const messaging = firebase.messaging();

// Background push handler — shows system notification when app is in background/closed
messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  if (!title && !body) return;
  self.registration.showNotification(title ?? 'FoodShare', {
    body: body ?? '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  });
});
