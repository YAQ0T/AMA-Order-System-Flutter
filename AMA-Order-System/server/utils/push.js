const webpush = require('web-push');
const { PushSubscription } = require('../db');

const publicVapidKey = 'BPi7aQAQ7GVUmK_Kcj3DOwVZXWru297dmOiDPslJ4dlIKVc-YecqwQXXmgzbqxr8US5HVxPh8y-pgkrHmJdYj9M';
const privateVapidKey = 'emcHqGK9BaJ-fw92FeYChZqdDOmBMpiQkSOijvHuRnw';

webpush.setVapidDetails(
    'mailto:test@test.com',
    publicVapidKey,
    privateVapidKey
);

const sendPushNotification = async (userId, payload) => {
    try {
        const subscriptions = await PushSubscription.findAll({ where: { userId } });

        const notifications = subscriptions.map(sub => {
            const pushConfig = {
                endpoint: sub.endpoint,
                keys: {
                    auth: sub.auth,
                    p256dh: sub.p256dh
                }
            };
            return webpush.sendNotification(pushConfig, JSON.stringify(payload))
                .catch(err => {
                    if (err.statusCode === 410 || err.statusCode === 404) {
                        // Subscription is invalid, delete it
                        return sub.destroy();
                    }
                    console.error('Error sending push notification:', err);
                });
        });

        await Promise.all(notifications);
    } catch (error) {
        console.error('Error in sendPushNotification:', error);
    }
};

module.exports = { sendPushNotification };
