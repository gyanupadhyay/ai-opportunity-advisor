import { Router } from "express";
import { db } from "./firebase";
import {
  COLLECTION_CONVERSATION_MESSAGES,
  COLLECTION_SHARED_CONVERSATIONS,
} from "./config";
import { AuthedRequest } from "./auth_middleware";

const router = Router();

// Create a public snapshot of a conversation (requires auth, owned by user)
router.post(
  "/me/conversations/:id/share",
  async (req: AuthedRequest, res) => {
    const convId = req.params.id as string;
    const uid = req.user?.uid;

    if (!uid) {
      res.status(401).json({ error: "Authentication required" });
      return;
    }

    try {
      // Load messages for this conversation
      const snap = await db
        .collection(COLLECTION_CONVERSATION_MESSAGES)
        .where("conversationId", "==", convId)
        .get();

      const messages = snap.docs
        .map((d) => d.data() as { role: string; content: string })
        .sort((a, b) => {
          const at = (a as any).timestamp?.toDate?.()?.getTime?.() ?? 0;
          const bt = (b as any).timestamp?.toDate?.()?.getTime?.() ?? 0;
          return at - bt;
        })
        .map((m) => ({ role: m.role, content: m.content }));

      if (messages.length === 0) {
        res
          .status(400)
          .json({ error: "Conversation has no messages to share yet." });
        return;
      }

      const docRef = await db.collection(COLLECTION_SHARED_CONVERSATIONS).add({
        ownerUid: uid,
        conversationId: convId,
        messages,
        createdAt: new Date().toISOString(),
      });

      res.status(201).json({ shareId: docRef.id });
    } catch (e) {
      console.error("Error creating share snapshot", e);
      res.status(500).json({ error: "Failed to create shareable link" });
    }
  }
);

// Public, read-only access to a shared conversation snapshot
router.get("/share/:shareId", async (req, res) => {
  const shareId = req.params.shareId as string;

  try {
    const doc = await db
      .collection(COLLECTION_SHARED_CONVERSATIONS)
      .doc(shareId)
      .get();

    if (!doc.exists) {
      res.status(404).json({ error: "Shared conversation not found" });
      return;
    }

    const data = doc.data() as
      | {
          messages?: { role: string; content: string }[];
        }
      | undefined;

    res.json({
      messages: data?.messages ?? [],
    });
  } catch (e) {
    console.error("Error loading shared conversation", e);
    res.status(500).json({ error: "Failed to load shared conversation" });
  }
});

export default router;

