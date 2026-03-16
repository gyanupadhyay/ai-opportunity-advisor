import { Router, Response } from "express";
import { AuthedRequest } from "./auth_middleware";
import { db, admin } from "./firebase";
import { processConversation } from "./recommendation_engine";
import { ConversationMessage, StudentProfile } from "./models/user_model";
import {
  COLLECTION_USER_CONVERSATIONS,
  COLLECTION_CONVERSATION_MESSAGES,
  START_MESSAGE,
  AI_MODEL,
  AI_MAX_TOKENS_TITLE,
} from "./config";

// In-memory fallback when Firestore is unavailable (local dev)
interface MemConversation {
  id: string;
  ownerUid: string;
  title: string;
  createdAt: string;
  updatedAt: string;
  profile: StudentProfile | null;
  profileQueried: boolean;
}
interface MemMessage {
  conversationId: string;
  role: "user" | "assistant";
  content: string;
  timestamp: string;
}
const memConversations: MemConversation[] = [];
const memMessages: MemMessage[] = [];

let firestoreAvailable: boolean | null = null;

async function checkFirestore(): Promise<boolean> {
  if (firestoreAvailable !== null) return firestoreAvailable;
  try {
    await db.collection(COLLECTION_USER_CONVERSATIONS).limit(1).get();
    firestoreAvailable = true;
  } catch {
    firestoreAvailable = false;
  }
  return firestoreAvailable;
}

function requireAuth(req: AuthedRequest, res: Response): string | null {
  if (!req.user?.uid) {
    res.status(401).json({ error: "Authentication required" });
    return null;
  }
  return req.user.uid;
}

const router = Router();

// ─── List conversations ───────────────────────────────────────────────────────
router.get("/", async (req: AuthedRequest, res: Response) => {
  const uid = requireAuth(req, res);
  if (!uid) return;

  try {
    if (await checkFirestore()) {
      const snap = await db
        .collection(COLLECTION_USER_CONVERSATIONS)
        .where("ownerUid", "==", uid)
        .orderBy("updatedAt", "desc")
        .limit(50)
        .get();

      const conversations = snap.docs.map((d) => ({
        id: d.id,
        ...d.data(),
      }));
      res.json({ conversations });
    } else {
      const conversations = memConversations
        .filter((c) => c.ownerUid === uid)
        .sort(
          (a, b) =>
            new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
        );
      res.json({ conversations });
    }
  } catch (e) {
    console.error("Error listing conversations", e);
    res.status(500).json({ error: "Failed to list conversations" });
  }
});

// ─── Create conversation ──────────────────────────────────────────────────────
router.post("/", async (req: AuthedRequest, res: Response) => {
  const uid = requireAuth(req, res);
  if (!uid) return;

  const title = (req.body.title as string) || "New chat";
  const now = new Date().toISOString();

  try {
    if (await checkFirestore()) {
      const docRef = await db.collection(COLLECTION_USER_CONVERSATIONS).add({
        ownerUid: uid,
        title,
        profile: null,
        profileQueried: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      res.status(201).json({ id: docRef.id, title });
    } else {
      const id = `conv_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      memConversations.push({
        id,
        ownerUid: uid,
        title,
        createdAt: now,
        updatedAt: now,
        profile: null,
        profileQueried: false,
      });
      res.status(201).json({ id, title });
    }
  } catch (e) {
    console.error("Error creating conversation", e);
    res.status(500).json({ error: "Failed to create conversation" });
  }
});

// ─── Delete conversation ──────────────────────────────────────────────────────
router.delete("/:id", async (req: AuthedRequest, res: Response) => {
  const uid = requireAuth(req, res);
  if (!uid) return;

  const convId = req.params.id as string;

  try {
    if (await checkFirestore()) {
      const docRef = db
        .collection(COLLECTION_USER_CONVERSATIONS)
        .doc(convId);
      const doc = await docRef.get();
      if (!doc.exists || doc.data()?.ownerUid !== uid) {
        res.status(404).json({ error: "Conversation not found" });
        return;
      }

      // Delete all messages for this conversation
      const msgSnap = await db
        .collection(COLLECTION_CONVERSATION_MESSAGES)
        .where("conversationId", "==", convId)
        .get();
      const batch = db.batch();
      msgSnap.docs.forEach((d) => batch.delete(d.ref));
      batch.delete(docRef);
      await batch.commit();

      res.json({ success: true });
    } else {
      const idx = memConversations.findIndex(
        (c) => c.id === convId && c.ownerUid === uid
      );
      if (idx === -1) {
        res.status(404).json({ error: "Conversation not found" });
        return;
      }
      memConversations.splice(idx, 1);
      // Remove associated messages
      for (let i = memMessages.length - 1; i >= 0; i--) {
        if (memMessages[i].conversationId === convId) memMessages.splice(i, 1);
      }
      res.json({ success: true });
    }
  } catch (e) {
    console.error("Error deleting conversation", e);
    res.status(500).json({ error: "Failed to delete conversation" });
  }
});

// ─── Get messages for a conversation ──────────────────────────────────────────
router.get("/:id/messages", async (req: AuthedRequest, res: Response) => {
  const uid = requireAuth(req, res);
  if (!uid) return;

  const convId = req.params.id as string;

  try {
    if (await checkFirestore()) {
      const snap = await db
        .collection(COLLECTION_CONVERSATION_MESSAGES)
        .where("conversationId", "==", convId)
        .orderBy("timestamp", "asc")
        .get();

      const messages = snap.docs.map((d) => {
        const data = d.data();
        return {
          role: data.role,
          content: data.content,
          timestamp: data.timestamp?.toDate?.()?.toISOString?.() ?? "",
        };
      });
      res.json({ messages });
    } else {
      const messages = memMessages
        .filter((m) => m.conversationId === convId)
        .map((m) => ({
          role: m.role,
          content: m.content,
          timestamp: m.timestamp,
        }));
      res.json({ messages });
    }
  } catch (e) {
    console.error("Error loading messages", e);
    res.status(500).json({ error: "Failed to load messages" });
  }
});

// ─── Send a message in a conversation ─────────────────────────────────────────
router.post("/:id/messages", async (req: AuthedRequest, res: Response) => {
  const uid = requireAuth(req, res);
  if (!uid) return;

  const convId = req.params.id as string;
  const { message } = req.body;

  if (!message) {
    res.status(400).json({ error: "message is required" });
    return;
  }

  try {
    const isStart = message === START_MESSAGE;
    const useFs = await checkFirestore();
    const now = new Date().toISOString();

    // Load existing profile + messages for this conversation
    let profile: StudentProfile | null = null;
    let profileQueried = false;
    let history: ConversationMessage[] = [];

    if (!isStart) {
      if (useFs) {
        const convDoc = await db
          .collection(COLLECTION_USER_CONVERSATIONS)
          .doc(convId)
          .get();
        if (convDoc.exists) {
          const data = convDoc.data()!;
          profile = data.profile ?? null;
          profileQueried = data.profileQueried ?? false;
        }

        const msgSnap = await db
          .collection(COLLECTION_CONVERSATION_MESSAGES)
          .where("conversationId", "==", convId)
          .orderBy("timestamp", "asc")
          .get();

        history = msgSnap.docs.map((d) => ({
          role: d.data().role as "user" | "assistant",
          content: d.data().content as string,
        }));
      } else {
        const conv = memConversations.find((c) => c.id === convId);
        if (conv) {
          profile = conv.profile;
          profileQueried = conv.profileQueried;
        }
        history = memMessages
          .filter((m) => m.conversationId === convId)
          .map((m) => ({ role: m.role, content: m.content }));
      }
    }

    if (!isStart) {
      history.push({ role: "user", content: message });
    }

    // Call the recommendation engine
    const result = await processConversation(
      history,
      profile,
      profileQueried
    );

    // Save messages
    if (useFs) {
      const batch = db.batch();

      if (!isStart) {
        batch.set(db.collection(COLLECTION_CONVERSATION_MESSAGES).doc(), {
          conversationId: convId,
          role: "user",
          content: message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      batch.set(db.collection(COLLECTION_CONVERSATION_MESSAGES).doc(), {
        conversationId: convId,
        role: "assistant",
        content: result.reply,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update conversation metadata
      const convUpdate: Record<string, unknown> = {
        profile: result.profile,
        profileQueried: result.profileQueried,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Auto-title after first user message
      if (!isStart && history.filter((m) => m.role === "user").length === 1) {
        convUpdate.title = await generateTitle(message);
      }

      batch.update(
        db.collection(COLLECTION_USER_CONVERSATIONS).doc(convId),
        convUpdate
      );

      await batch.commit();
    } else {
      if (!isStart) {
        memMessages.push({
          conversationId: convId,
          role: "user",
          content: message,
          timestamp: now,
        });
      }
      memMessages.push({
        conversationId: convId,
        role: "assistant",
        content: result.reply,
        timestamp: new Date().toISOString(),
      });

      const conv = memConversations.find((c) => c.id === convId);
      if (conv) {
        conv.profile = result.profile;
        conv.profileQueried = result.profileQueried;
        conv.updatedAt = new Date().toISOString();

        if (
          !isStart &&
          history.filter((m) => m.role === "user").length === 1
        ) {
          conv.title = await generateTitle(message);
        }
      }
    }

    res.json({
      reply: result.reply,
      opportunities: result.opportunities,
    });
  } catch (e) {
    console.error("Error processing message", e);
    res.status(500).json({
      reply: "I'm sorry, I encountered an error. Please try again.",
      opportunities: [],
    });
  }
});

async function generateTitle(firstMessage: string): Promise<string> {
  try {
    const Groq = (await import("groq-sdk")).default;
    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY! });
    const r = await groq.chat.completions.create({
      model: AI_MODEL,
      messages: [
        {
          role: "system",
          content:
            "Generate a short chat title (max 6 words) for a conversation that starts with the following user message. Reply with ONLY the title, no quotes or punctuation.",
        },
        { role: "user", content: firstMessage },
      ],
      max_tokens: AI_MAX_TOKENS_TITLE,
      temperature: 0.5,
    });
    return r.choices[0]?.message?.content?.trim() || firstMessage.slice(0, 40);
  } catch {
    return firstMessage.length > 40
      ? firstMessage.slice(0, 37) + "..."
      : firstMessage;
  }
}

export default router;
