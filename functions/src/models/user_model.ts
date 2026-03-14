/**
 * Type definitions for student profiles, conversation messages, and
 * conversation state persisted in the `conversations` Firestore collection.
 */

export interface StudentProfile {
  country: string | null;
  educationLevel: string | null;
  field: string | null;
  interests: string | null;
  opportunityType: string | null;
  preferredRegion: string | null;
  isComplete: boolean;
}

export interface ConversationMessage {
  role: "user" | "assistant";
  content: string;
}

export interface ConversationState {
  messages: ConversationMessage[];
  profile: StudentProfile | null;
  profileQueried: boolean;
}

export const DEFAULT_PROFILE: StudentProfile = {
  country: null,
  educationLevel: null,
  field: null,
  interests: null,
  opportunityType: null,
  preferredRegion: null,
  isComplete: false,
};
