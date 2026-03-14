/**
 * Chat Handler — the HTTP Cloud Function that the Jaspr frontend calls.
 *
 * Orchestrates the request lifecycle:
 *   1. Validate the incoming request.
 *   2. Load (or initialise) conversation state.
 *   3. Delegate to the recommendation engine.
 *   4. Persist updated state and return the response.
 */

import { onRequest } from "firebase-functions/v2/https";
import {
  loadConversation,
  saveConversation,
  logMessage,
} from "./services/user_service";
import { processConversation } from "./recommendation_engine";
import { ConversationState } from "./models/user_model";

export const handleChatMessage = onRequest(
  { cors: true, region: "us-central1" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const { sessionId, message } = req.body;

    if (!sessionId || !message) {
      res.status(400).json({ error: "sessionId and message are required" });
      return;
    }

    try {
      const isStart = message === "__start__";

      // ---- 1. Load or initialise conversation state ----
      const state: ConversationState = isStart
        ? { messages: [], profile: null, profileQueried: false }
        : await loadConversation(sessionId);

      // ---- 2. Append user message (skip for the hidden start signal) ----
      if (!isStart) {
        state.messages.push({ role: "user", content: message });
        await logMessage(sessionId, message, "user");
      }

      // ---- 3. Run the recommendation pipeline ----
      const result = await processConversation(
        state.messages,
        state.profile,
        state.profileQueried
      );

      // ---- 4. Update and persist state ----
      state.messages.push({ role: "assistant", content: result.reply });
      state.profile = result.profile;
      state.profileQueried = result.profileQueried;

      await saveConversation(sessionId, state);
      await logMessage(sessionId, result.reply, "assistant");

      res.status(200).json({
        reply: result.reply,
        opportunities: result.opportunities,
      });
    } catch (error) {
      console.error("Error processing chat message:", error);
      res.status(500).json({
        reply: "I'm sorry, I encountered an error. Please try again.",
        opportunities: [],
      });
    }
  }
);
