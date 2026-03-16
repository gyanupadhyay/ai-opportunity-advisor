import { db, admin } from "../firebase";
import { ConversationMessage, ConversationState } from "../models/user_model";
import { COLLECTION_CONVERSATIONS, COLLECTION_CHATS } from "../config";

// Fallback in-memory store so local development still has conversational
// context even when Firestore is not configured.
const inMemoryConversations = new Map<string, ConversationState>();

export async function loadConversation(
  sessionId: string
): Promise<ConversationState> {
  try {
    const doc = await db
      .collection(COLLECTION_CONVERSATIONS)
      .doc(sessionId)
      .get();

    if (doc.exists) {
      const data = doc.data() as {
        messages?: ConversationMessage[];
        profile?: unknown;
        profileQueried?: boolean;
      } | null;

      return {
        messages: data?.messages ?? [],
        profile: (data?.profile as any) ?? null,
        profileQueried: data?.profileQueried ?? false,
      };
    }

    // No Firestore doc yet, fall back to any in-memory state.
    const mem = inMemoryConversations.get(sessionId);
    if (mem) {
      return mem;
    }
  } catch (e) {
    console.warn("loadConversation: Firestore unavailable, using memory only", e);

    const mem = inMemoryConversations.get(sessionId);
    if (mem) {
      return mem;
    }
  }

  return { messages: [], profile: null, profileQueried: false };
}

export async function saveConversation(
  sessionId: string,
  state: ConversationState
): Promise<void> {
  try {
    await db.collection(COLLECTION_CONVERSATIONS).doc(sessionId).set({
      messages: state.messages,
      profile: state.profile,
      profileQueried: state.profileQueried,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.warn("saveConversation: Firestore write failed, keeping in memory", e);
  }

  // Always update the in-memory cache so local development (or Firestore
  // outages) still preserve context for the lifetime of the process.
  inMemoryConversations.set(sessionId, {
    messages: [...state.messages],
    profile: state.profile,
    profileQueried: state.profileQueried,
  });
}

export async function logMessage(
  sessionId: string,
  message: string,
  role: "user" | "assistant"
): Promise<void> {
  try {
    await db.collection(COLLECTION_CHATS).add({
      userId: sessionId,
      message,
      role,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.warn(
      "logMessage: skipping Firestore write (likely no Firestore in local env)",
      e
    );
  }
}
