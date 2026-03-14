import { db, admin } from "../firebase";
import { ConversationState } from "../models/user_model";

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
