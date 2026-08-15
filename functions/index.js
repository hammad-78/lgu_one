const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Triggered when a new Lost & Found listing is created.
 */
exports.onLostFoundListingCreated = functions.firestore
    .document('lost_found_items/{itemId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        if (!data) return null;

        const itemId = context.params.itemId;
        const title = data.title || 'New Item';
        const type = data.type || 'lost';
        const authorToken = data.authorToken;

        const payloadData = {
            type: 'lost_found',
            id: String(itemId),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        };

        const promises = [];

        // 1. Notify the Author
        if (authorToken) {
            const authorMessage = {
                token: authorToken,
                notification: {
                    title: 'Listing Published!',
                    body: 'Your listing is visible throughout the campus.',
                },
                data: payloadData,
            };
            
            promises.push(
                admin.messaging().send(authorMessage)
                    .then(() => console.log(`Author notification sent for: ${itemId}`))
                    .catch(err => console.error('Error sending to author:', err))
            );
        }

        // 2. Broadcast to all other campus users
        try {
            const tokensSnapshot = await admin.firestore().collection('device_tokens').get();
            const allTokens = tokensSnapshot.docs
                .map(doc => doc.data().token)
                .filter(token => token && token !== authorToken);

            if (allTokens.length > 0) {
                const broadcastMessage = {
                    tokens: allTokens,
                    notification: {
                        title: type === 'lost' ? 'New Lost Item' : 'New Found Item',
                        body: `A new ${type} item "${title}" was reported. Tap to view details.`,
                    },
                    data: payloadData,
                };

                promises.push(
                    admin.messaging().sendEachForMulticast(broadcastMessage)
                        .then(response => {
                            console.log(`${response.successCount} broadcast notifications sent.`);
                        })
                        .catch(err => console.error('Multicast error:', err))
                );
            }
        } catch (error) {
            console.error('Error fetching tokens for broadcast:', error);
        }

        return Promise.all(promises);
    });

/**
 * Triggered when a new Collaboration is created.
 */
exports.onCollaborationCreated = functions.firestore
    .document('collaborations/{collabId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        // The collaboration data is nested inside 'info' field
        if (!data || !data.info) return null;

        const collabInfo = data.info;
        const title = collabInfo.title || 'New Collaboration';
        const category = collabInfo.category || 'Project';
        const authorToken = collabInfo.authorToken;

        const payloadData = {
            type: 'collaboration',
            id: String(context.params.collabId),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        };

        const promises = [];

        // 1. Notify the Author
        if (authorToken) {
            const authorMessage = {
                token: authorToken,
                notification: {
                    title: 'Collaboration Live!',
                    body: 'Your project is now visible to all students. Let\'s build something great!',
                },
                data: payloadData,
            };
            
            promises.push(
                admin.messaging().send(authorMessage)
                    .then(() => console.log(`Collaboration author notified: ${title}`))
                    .catch(err => console.error('Error sending collab notification to author:', err))
            );
        }

        // 2. Broadcast to all other campus users
        try {
            const tokensSnapshot = await admin.firestore().collection('device_tokens').get();
            const allTokens = tokensSnapshot.docs
                .map(doc => doc.data().token)
                .filter(token => token && token !== authorToken);

            if (allTokens.length > 0) {
                const broadcastMessage = {
                    tokens: allTokens,
                    notification: {
                        title: 'New Collaboration Opportunity',
                        body: `Looking for partners for "${title}" (${category}). Check it out!`,
                    },
                    data: payloadData,
                };

                promises.push(
                    admin.messaging().sendEachForMulticast(broadcastMessage)
                        .then(response => {
                            console.log(`${response.successCount} collab broadcast notifications sent.`);
                        })
                        .catch(err => console.error('Collab multicast error:', err))
                );
            }
        } catch (error) {
            console.error('Error broadcasting collaboration:', error);
        }

        return Promise.all(promises);
    });
