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
const {onCall} = require("firebase-functions/v2/https");
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.testFunction = onCall({ maxInstances: 10 }, (request) => {
    return "Hello, world!";
}); 