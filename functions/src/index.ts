import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onItemCreated = functions.firestore
  .document('items/{itemId}')
  .onCreate(async (snap, context) => {
    const newItem = snap.data();
    
    if (!newItem) {
      console.log('No item data found');
      return null;
    }

    const type = newItem.type; // 'lost' or 'found'
    const title = newItem.title || 'An item';
    const category = newItem.category;
    const posterName = newItem.posterName || 'Someone';

    if (type === 'lost') {
      // 1. Notify all users about the new lost item via 'all_users' topic
      const payload = {
        notification: {
          title: `New Lost Item Reported: ${category}`,
          body: `${posterName} lost ${title}. Can you help find it?`,
        },
      };
      
      try {
        await admin.messaging().sendToTopic('all_users', payload);
        console.log(`Successfully sent topic message for lost item: ${title}`);
      } catch (error) {
        console.error('Error sending topic message:', error);
      }
    } else if (type === 'found') {
      // 2. Notify users who lost an item in the same category
      try {
        // Query items for lost items in the same category
        const lostItemsSnapshot = await admin.firestore().collection('items')
          .where('type', '==', 'lost')
          .where('category', '==', category)
          .get();

        if (lostItemsSnapshot.empty) {
          console.log(`No matching lost items found for category ${category}`);
          return null;
        }

        // Collect unique user IDs of those who lost similar items
        const userIdsToNotify = new Set<string>();
        lostItemsSnapshot.forEach(doc => {
          const itemData = doc.data();
          if (itemData.postedBy && itemData.postedBy !== newItem.postedBy) {
            userIdsToNotify.add(itemData.postedBy);
          }
        });

        if (userIdsToNotify.size === 0) {
           console.log('No eligible users found to notify for found item.');
           return null;
        }

        // Fetch their FCM tokens from the 'users' collection
        const tokens: string[] = [];
        const userFetchPromises = Array.from(userIdsToNotify).map(async (userId) => {
           const userDoc = await admin.firestore().collection('users').doc(userId).get();
           if (userDoc.exists) {
             const userData = userDoc.data();
             if (userData && userData.fcmToken) {
               tokens.push(userData.fcmToken);
             }
           }
        });

        await Promise.all(userFetchPromises);

        if (tokens.length === 0) {
          console.log('No valid FCM tokens found for users to notify.');
          return null;
        }

        // Send multicast message
        const payload = {
          notification: {
            title: `A ${category} has been found!`,
            body: `${title} was recently found. Could this be yours?`,
          },
        };

        const response = await admin.messaging().sendToDevice(tokens, payload);
        console.log(`Successfully sent message to ${response.successCount} devices for found item.`);
      } catch (error) {
        console.error('Error handling found item notifications:', error);
      }
    }

    return null;
  });
