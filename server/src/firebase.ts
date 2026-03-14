import * as admin from "firebase-admin";

const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT;

if (serviceAccountEnv) {
  const serviceAccount = JSON.parse(serviceAccountEnv);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} else {
  admin.initializeApp();
}

export const db = admin.firestore();
export { admin };
