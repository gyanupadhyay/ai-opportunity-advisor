import { Response } from "express";
import {
  loadConversation,
  saveConversation,
  logMessage,
} from "./services/user_service";
import { processConversation } from "./recommendation_engine";
import { ConversationState } from "./models/user_model";
import { START_MESSAGE } from "./config";
import { AuthedRequest } from "./auth_middleware";

export async function handleChatMessage(
  req: AuthedRequest,
  res: Response
): Promise<void> {
  const { sessionId: bodySessionId, message } = req.body;
  const sessionId = req.user?.uid ?? bodySessionId;

  if (!sessionId || !message) {
    res.status(400).json({ error: "sessionId and message are required" });
    return;
  }

  try {
    const isStart = message === START_MESSAGE;

    const state: ConversationState = isStart
      ? { messages: [], profile: null, profileQueried: false }
      : await loadConversation(sessionId);

    if (!isStart) {
      state.messages.push({ role: "user", content: message });
      await logMessage(sessionId, message, "user");
    }

    const result = await processConversation(
      state.messages,
      state.profile,
      state.profileQueried
    );

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
