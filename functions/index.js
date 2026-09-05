const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

if (!admin.apps || !admin.apps.length) {
    admin.initializeApp();
}

const db = getFirestore();
const messaging = getMessaging();

/**
 * Helper to save notification to global collection
 */
async function saveNotification(title, body, type, relatedId) {
    try {
        await db.collection('notifications').add({
            title: title,
            body: body,
            type: type,
            relatedId: relatedId,
            timestamp: FieldValue.serverTimestamp(),
        });
        
        // Keep only latest 20 notifications to save space
        const snapshot = await db.collection('notifications')
            .orderBy('timestamp', 'desc')
            .offset(20)
            .get();
        
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
    } catch (error) {
        console.error('Error saving notification to Firestore:', error);
    }
}

function chunk(items, size) {
    const chunks = [];
    for (let index = 0; index < items.length; index += size) {
        chunks.push(items.slice(index, index + size));
    }
    return chunks;
}

async function sendLostFoundBroadcast(itemId, data) {
    const title = data.title || 'New Item';
    const type = data.type || 'lost';
    
    const notificationTitle = type === 'lost' ? 'New Lost Item Approved' : 'New Found Item Approved';
    const notificationBody = `"${title}" has been approved and is now listed in Lost & Found.`;

    await saveNotification(notificationTitle, notificationBody, 'lost_found', itemId);

    const payloadData = {
        type: 'lost_found',
        id: String(itemId),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
    };

    try {
        const tokensSnapshot = await db.collection('device_tokens').get();
        const allTokens = tokensSnapshot.docs
            .map(doc => doc.data().token)
            .filter(token => token); // send to ALL devices

        if (allTokens.length > 0) {
            await Promise.all(
                chunk(allTokens, 500).map((tokenBatch) =>
                    messaging.sendEachForMulticast({
                        tokens: tokenBatch,
                        notification: {
                            title: notificationTitle,
                            body: notificationBody,
                        },
                        data: payloadData,
                        android: {
                            notification: { channelId: 'high_importance_channel' },
                        },
                    }),
                ),
            );
        }
    } catch (error) {
        console.error('Error fetching tokens for broadcast:', error);
    }
}

async function sendCollaborationBroadcast(collabId, collabInfo) {
    const title = collabInfo.title || 'New Collaboration';
    const category = collabInfo.category || 'Project';
    
    const notificationTitle = 'New Collaboration Approved';
    const notificationBody = `"${title}" (${category}) has been approved and is open for collaboration!`;

    await saveNotification(notificationTitle, notificationBody, 'collaboration', collabId);

    const payloadData = {
        type: 'collaboration',
        id: String(collabId),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
    };

    try {
        const tokensSnapshot = await db.collection('device_tokens').get();
        const allTokens = tokensSnapshot.docs
            .map(doc => doc.data().token)
            .filter(token => token); // send to ALL devices

        if (allTokens.length > 0) {
            await Promise.all(
                chunk(allTokens, 500).map((tokenBatch) =>
                    messaging.sendEachForMulticast({
                        tokens: tokenBatch,
                        notification: {
                            title: notificationTitle,
                            body: notificationBody,
                        },
                        data: payloadData,
                        android: {
                            notification: { channelId: 'high_importance_channel' },
                        },
                    }),
                ),
            );
        }
    } catch (error) {
        console.error('Error broadcasting collaboration:', error);
    }
}

/**
 * Triggered when a Lost & Found listing is updated (e.g. approved by admin).
 */
exports.onLostFoundListingUpdated = onDocumentUpdated(
    'lost_found_items/{itemId}',
    async (event) => {
        const beforeData = event.data.before ? event.data.before.data() : null;
        const afterData = event.data.after ? event.data.after.data() : null;
        if (!afterData) return null;

        const beforeStatus = beforeData ? (beforeData.status || '').toLowerCase() : '';
        const afterStatus = (afterData.status || '').toLowerCase();

        // If status changed to active (approved)
        if (beforeStatus !== 'active' && afterStatus === 'active') {
            await sendLostFoundBroadcast(event.params.itemId, afterData);
        }
        return null;
    }
);

/**
 * Sends an administrator-authored broadcast. The client creates only a
 * request document; FCM delivery and public notification history stay server-side.
 */
exports.onAdminNotificationCreated = onDocumentCreated(
    'admin_notifications/{notificationId}',
    async (event) => {
        const data = event.data ? event.data.data() : null;
        if (!data) return null;

        const title = String(data.title || 'LGU Connect');
        const body = String(data.body || 'You have a new update.');
        await saveNotification(title, body, 'announcement', event.params.notificationId);

        const tokensSnapshot = await db.collection('device_tokens').get();
        const tokens = tokensSnapshot.docs
            .map(doc => doc.data().token)
            .filter(token => token);

        if (tokens.length === 0) return null;

        const responses = await Promise.all(
            chunk(tokens, 500).map(tokenBatch => messaging.sendEachForMulticast({
                tokens: tokenBatch,
                notification: { title, body },
                data: {
                    type: 'announcement',
                    id: String(event.params.notificationId),
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    notification: { channelId: 'high_importance_channel' },
                },
            })),
        );
        console.log(`Admin notification sent to ${tokens.length} device(s).`, responses);
        return null;
    },
);

/**
 * Triggered when a Collaboration is updated (e.g. approved by admin).
 */
exports.onCollaborationUpdated = onDocumentUpdated(
    'collaborations/{collabId}',
    async (event) => {
        const beforeData = event.data.before ? event.data.before.data() : null;
        const afterData = event.data.after ? event.data.after.data() : null;
        if (!afterData || !afterData.info) return null;

        const beforeStatus = beforeData && beforeData.info ? (beforeData.info.status || '').toLowerCase() : '';
        const afterStatus = (afterData.info.status || '').toLowerCase();

        // If status changed to open (approved)
        if (beforeStatus !== 'open' && afterStatus === 'open') {
            await sendCollaborationBroadcast(event.params.collabId, afterData.info);
        }
        return null;
    }
);

/**
 * Triggered when a new Event is created.
 */
exports.onEventCreated = onDocumentCreated(
    'events/{eventId}',
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) return null;

        const data = snapshot.data();
        if (!data) return null;

        const eventId = event.params.eventId;
        const title = data.title || 'New Event';
        const location = data.location || 'Campus';
        
        const notificationTitle = 'New Event Added!';
        const notificationBody = `${title} is happening at ${location}. Don't miss out!`;

        await saveNotification(notificationTitle, notificationBody, 'event', eventId);

        const payloadData = {
            type: 'event',
            id: String(eventId),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        };

        try {
            const tokensSnapshot = await db.collection('device_tokens').get();
            const allTokens = tokensSnapshot.docs
                .map(doc => doc.data().token)
                .filter(token => token);

            if (allTokens.length > 0) {
                const broadcastMessage = {
                    tokens: allTokens,
                    notification: {
                        title: notificationTitle,
                        body: notificationBody,
                    },
                    data: payloadData,
                };
                await messaging.sendEachForMulticast(broadcastMessage);
            }
        } catch (error) {
            console.error('Error broadcasting new event:', error);
        }

        return null;
    }
);

/**
 * Scheduled function to check for events happening tomorrow.
 */
exports.sendDailyEventReminders = onSchedule(
    {
        schedule: '0 9 * * *',
        timeZone: 'Asia/Karachi',
    },
    async (event) => {
        const now = new Date();
        const tomorrow = new Date(now);
        tomorrow.setDate(now.getDate() + 1);
        
        const startOfTomorrow = new Date(tomorrow.setHours(0, 0, 0, 0));
        const endOfTomorrow = new Date(tomorrow.setHours(23, 59, 59, 999));

        try {
            const eventsSnapshot = await db.collection('events')
                .where('eventDate', '>=', Timestamp.fromDate(startOfTomorrow))
                .where('eventDate', '<=', Timestamp.fromDate(endOfTomorrow))
                .get();

            if (eventsSnapshot.empty) return null;

            const tokensSnapshot = await db.collection('device_tokens').get();
            const allTokens = tokensSnapshot.docs
                .map(doc => doc.data().token)
                .filter(token => token);

            if (allTokens.length === 0) return null;

            const notificationPromises = eventsSnapshot.docs.map(async (doc) => {
                const eventData = doc.data();
                const notificationTitle = 'Event Reminder: Only 1 Day Left!';
                const notificationBody = `"${eventData.title}" is happening tomorrow at ${eventData.location}.`;
                
                await saveNotification(notificationTitle, notificationBody, 'event', doc.id);

                const broadcastMessage = {
                    tokens: allTokens,
                    notification: {
                        title: notificationTitle,
                        body: notificationBody,
                    },
                    data: {
                        type: 'event',
                        id: String(doc.id),
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                };
                return messaging.sendEachForMulticast(broadcastMessage);
            });

            await Promise.all(notificationPromises);
        } catch (error) {
            console.error('Error sending daily event reminders:', error);
        }

        return null;
    }
);

