self.addEventListener('push', function (event) {
    const data = event.data.json();

    const options = {
        body: data.body,
        icon: '/vite.svg',
        badge: '/vite.svg',
        vibrate: [200, 100, 200], // Vibration pattern
        requireInteraction: true, // Notification stays until user interacts
        silent: false, // Enable sound
        tag: 'order-notification', // Group notifications
        data: {
            url: data.url || '/'
        }
    };

    event.waitUntil(
        self.registration.showNotification(data.title, options)
    );
});

self.addEventListener('notificationclick', function (event) {
    event.notification.close();
    event.waitUntil(
        clients.openWindow(event.notification.data.url)
    );
});
