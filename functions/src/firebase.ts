import * as admin from "firebase-admin";

// Initialize Firebase Admin once
if (!admin.apps.length) {
  admin.initializeApp();
}

export const db = admin.firestore();
export {admin};
