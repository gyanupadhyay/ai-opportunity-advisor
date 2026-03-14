/**
 * Shared Firebase initialization module.
 *
 * Every service imports `db` and `admin` from here instead of calling
 * `admin.initializeApp()` independently.  Node's module cache guarantees
 * this file executes only once regardless of how many modules import it.
 */

import * as admin from "firebase-admin";

admin.initializeApp();

export const db = admin.firestore();
export { admin };
