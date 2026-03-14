/**
 * Recommendation Engine — the core pipeline that turns a conversation into
 * personalised opportunity recommendations.
 *
 * Pipeline:
 *   1. Extract / update the student profile from conversation history.
 *   2. Query Firestore for matching opportunities (first time only).
 *   3. Build an enriched system prompt with opportunity context.
 *   4. Generate the AI response via the AI service.
 */

import { StudentProfile, ConversationMessage } from "./models/user_model";
import {
  extractProfile,
  getSystemPrompt,
  generateResponse,
} from "./services/ai_service";
import { queryOpportunities } from "./services/opportunity_service";

export interface RecommendationResult {
  reply: string;
  opportunities: Record<string, unknown>[];
  profile: StudentProfile | null;
  profileQueried: boolean;
}

/**
 * Runs the full recommendation pipeline for one conversational turn.
 *
 * @param history        All messages exchanged so far (including the latest).
 * @param currentProfile Cached student profile (may be null or incomplete).
 * @param alreadyQueried Whether Firestore was already queried for this session.
 */
export async function processConversation(
  history: ConversationMessage[],
  currentProfile: StudentProfile | null,
  alreadyQueried: boolean
): Promise<RecommendationResult> {
  let profile = currentProfile;
  let profileQueried = alreadyQueried;
  let opportunities: Record<string, unknown>[] = [];

  // --- Step 1: Profile extraction (after 3+ student answers) ---
  const userMsgCount = history.filter((m) => m.role === "user").length;

  if (!profile?.isComplete && userMsgCount >= 3) {
    profile = await extractProfile(history);
  }

  // --- Step 2: Query Firestore the first time the profile completes ---
  if (profile?.isComplete && !profileQueried) {
    opportunities = await queryOpportunities(profile);
    profileQueried = true;
  }

  // --- Step 3: Build enriched system prompt ---
  let systemContent = getSystemPrompt();

  if (profile?.isComplete && opportunities.length > 0) {
    systemContent +=
      "\n\nMATCHING OPPORTUNITIES FROM OUR DATABASE — use these in your recommendation. " +
      "For each opportunity, explain why it matches this student's profile:\n" +
      JSON.stringify(opportunities, null, 2);
  }

  if (profile && !profile.isComplete && userMsgCount >= 2) {
    systemContent +=
      `\n\nPARTIAL STUDENT PROFILE (gathered so far):\n${JSON.stringify(profile, null, 2)}\n` +
      "Continue asking about the remaining missing fields.";
  }

  // --- Step 4: Generate AI response ---
  const reply = await generateResponse(history, systemContent);

  return { reply, opportunities, profile, profileQueried };
}
