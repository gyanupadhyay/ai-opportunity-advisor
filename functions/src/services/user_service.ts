/**
 * User Service — manages conversation state and chat logging in Firestore.
 *
 * Conversation state is stored per-session in `conversations/{sessionId}`.
 * Individual messages are also logged to the `chats` collection for analytics.
 */

import { db, admin } from "../firebase";
import { ConversationState } from "../models/user_model";

/**
 * Loads a conversation from Firestore.  Returns default empty state when the
 * session does not yet exist.
 */
export async function loadConversation(
  sessionId: string
): Promise<ConversationState> {
  const doc = await db.collection("conversations").doc(sessionId).get();

  if (doc.exists) {
    const data = doc.data()!;
    return {
      messages: data.messages ?? [],
      profile: data.profile ?? null,
      profileQueried: data.profileQueried ?? false,
    };
  }

  return { messages: [], profile: null, profileQueried: false };
}

/**
 * Persists the full conversation state (messages, profile, flags) back to
 * Firestore with a server timestamp.
 */
export async function saveConversation(
  sessionId: string,
  state: ConversationState
): Promise<void> {
  await db.collection("conversations").doc(sessionId).set({
    messages: state.messages,
    profile: state.profile,
    profileQueried: state.profileQueried,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Appends a single message to the `chats` collection for analytics and
 * audit purposes.
 */
export async function logMessage(
  sessionId: string,
  message: string,
  role: "user" | "assistant"
): Promise<void> {
  await db.collection("chats").add({
    userId: sessionId,
    message,
    role,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}
