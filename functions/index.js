const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Helper to save notification to global collection
 */
async function saveNotification(title, body, type, relatedId) {
    try {
        await admin.firestore().collection('notifications').add({
            title: title,
            body: body,
            type: type,
            relatedId: relatedId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        // Keep only latest 20 notifications to save space (user only needs 10)
        const snapshot = await admin.firestore().collection('notifications')
            .orderBy('timestamp', 'desc')
            .offset(20)
            .get();
        
        const batch = admin.firestore().batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
    } catch (error) {
        console.error('Error saving notification to Firestore:', error);
    }
}

/**
 * Triggered when a new Lost & Found listing is created.
 */
exports.onLostFoundListingCreated = onDocumentCreated(
    'lost_found_items/{itemId}',
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) return null;

        const data = snapshot.data();
        if (!data) return null;

        const itemId = event.params.itemId;
        const title = data.title || 'New Item';
        const type = data.type || 'lost';
        const authorToken = data.authorToken;
        
        const notificationTitle = type === 'lost' ? 'New Lost Item' : 'New Found Item';
        const notificationBody = `A new ${type} item "${title}" was reported. Tap to view details.`;

        await saveNotification(notificationTitle, notificationBody, 'lost_found', itemId);

        const payloadData = {
            type: 'lost_found',
            id: String(itemId),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        };

        const promises = [];
        try {
            const tokensSnapshot = await admin.firestore().collection('device_tokens').get();
            const allTokens = tokensSnapshot.docs
                .map(doc => doc.data().token)
                .filter(token => token && token !== authorToken);

            if (allTokens.length > 0) {
                const broadcastMessage = {
                    tokens: allTokens,
                    notification: {
                        title: notificationTitle,
                        body: notificationBody,
                    },
                    data: payloadData,
                };
                promises.push(admin.messaging().sendEachForMulticast(broadcastMessage));
            }
        } catch (error) {
            console.error('Error fetching tokens for broadcast:', error);
        }

        return Promise.all(promises);
    }
);

/**
 * Triggered when a new Collaboration is created.
 */
exports.onCollaborationCreated = onDocumentCreated(
    'collaborations/{collabId}',
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) return null;

        const data = snapshot.data();
        if (!data || !data.info) return null;

        const collabInfo = data.info;
        const title = collabInfo.title || 'New Collaboration';
        const category = collabInfo.category || 'Project';
        const authorToken = collabInfo.authorToken;
        
        const notificationTitle = 'New Collaboration Opportunity';
        const notificationBody = `Looking for partners for "${title}" (${category}). Check it out!`;

        await saveNotification(notificationTitle, notificationBody, 'collaboration', event.params.collabId);

        const payloadData = {
            type: 'collaboration',
            id: String(event.params.collabId),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        };

        const promises = [];
        try {
            const tokensSnapshot = await admin.firestore().collection('device_tokens').get();
            const allTokens = tokensSnapshot.docs
                .map(doc => doc.data().token)
                .filter(token => token && token !== authorToken);

            if (allTokens.length > 0) {
                const broadcastMessage = {
                    tokens: allTokens,
                    notification: {
                        title: notificationTitle,
                        body: notificationBody,
                    },
                    data: payloadData,
                };
                promises.push(admin.messaging().sendEachForMulticast(broadcastMessage));
            }
        } catch (error) {
            console.error('Error broadcasting collaboration:', error);
        }

        return Promise.all(promises);
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
            const tokensSnapshot = await admin.firestore().collection('device_tokens').get();
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
                await admin.messaging().sendEachForMulticast(broadcastMessage);
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
            const eventsSnapshot = await admin.firestore().collection('events')
                .where('eventDate', '>=', admin.firestore.Timestamp.fromDate(startOfTomorrow))
                .where('eventDate', '<=', admin.firestore.Timestamp.fromDate(endOfTomorrow))
                .get();

            if (eventsSnapshot.empty) return null;

            const tokensSnapshot = await admin.firestore().collection('device_tokens').get();
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
                return admin.messaging().sendEachForMulticast(broadcastMessage);
            });

            await Promise.all(notificationPromises);
        } catch (error) {
            console.error('Error sending daily event reminders:', error);
        }

        return null;
    }
);
