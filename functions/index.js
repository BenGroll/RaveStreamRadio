/**
 * Import function triggers from their respective submodules:
 *
 * 
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { Message } = require("firebase-functions/v1/pubsub");
admin.initializeApp();

exports.testFunction = onCall({ maxInstances: 10 }, (request) => {
    const text = request.data;
    const arg1 = text[0];
    const arg2 = text[1];
    return text;
}); 

exports.sendMessageToDeviceTokens = functions.https.onCall((request) => {
    // Scheme is callable.call([List<String>tokens, String title, String content]);
    const args = request;
    const tokens = args[0];
    const title = args[1];
    const content = args[2];
    console.log("Reached arg creation in sendMessageToDeviceTokens");
    for (let i = 0; i < tokens.length; i++) {
        const payload = { 
            "token": tokens[i],
            "notification": {
              "title": title,
              "body": content
            }
          };
        const stringed = JSON.stringify(payload);
        try {
            const response = admin.messaging().send(payload)
            console.log("Sent message to token " + tokens[i])
        } catch (error) {
            console.log("Error in Response")
            console.log(error);
        }
    }
    return "Success";
});
