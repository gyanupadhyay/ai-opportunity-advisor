import { StudentProfile, ConversationMessage } from "./models/user_model";
import {
  extractProfile,
  getSystemPrompt,
  generateResponse,
} from "./services/ai_service";
import { queryOpportunities } from "./services/opportunity_service";
import { PROFILE_EXTRACT_AFTER, PROFILE_HINT_AFTER } from "./config";

export interface RecommendationResult {
  reply: string;
  opportunities: Record<string, unknown>[];
  profile: StudentProfile | null;
  profileQueried: boolean;
}

export async function processConversation(
  history: ConversationMessage[],
  currentProfile: StudentProfile | null,
  alreadyQueried: boolean
): Promise<RecommendationResult> {
  let profile = currentProfile;
  let profileQueried = alreadyQueried;
  let opportunities: Record<string, unknown>[] = [];

  const userMsgCount = history.filter((m) => m.role === "user").length;

  if (!profile?.isComplete && userMsgCount >= PROFILE_EXTRACT_AFTER) {
    profile = await extractProfile(history);
  }

  if (profile?.isComplete && !profileQueried) {
    opportunities = await queryOpportunities(profile);
    profileQueried = true;
  }

  let systemContent = getSystemPrompt();

  if (profile?.isComplete && opportunities.length > 0) {
    systemContent +=
      "\n\nMATCHING OPPORTUNITIES FROM OUR DATABASE — use these in your recommendation. " +
      "For each opportunity, explain why it matches this student's profile:\n" +
      JSON.stringify(opportunities, null, 2);
  }

  if (profile && !profile.isComplete && userMsgCount >= PROFILE_HINT_AFTER) {
    systemContent +=
      `\n\nPARTIAL STUDENT PROFILE (gathered so far):\n${JSON.stringify(profile, null, 2)}\n` +
      "Continue asking about the remaining missing fields.";
  }

  const reply = await generateResponse(history, systemContent);

  return { reply, opportunities, profile, profileQueried };
}
