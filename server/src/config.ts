// Centralised configuration — every tunable constant lives here so nothing
// is scattered as magic literals across multiple files.

// ─── AI Model ────────────────────────────────────────────────────────────────
export const AI_MODEL = process.env.AI_MODEL || "llama-3.3-70b-versatile";
export const AI_TEMPERATURE = parseFloat(process.env.AI_TEMPERATURE || "0.7");
export const AI_MAX_TOKENS_RESPONSE = 1500;
export const AI_MAX_TOKENS_EXTRACTION = 300;
export const AI_MAX_TOKENS_HEALTH = 10;

// ─── Firestore Collections ───────────────────────────────────────────────────
export const COLLECTION_OPPORTUNITIES = "opportunities";
export const COLLECTION_CONVERSATIONS = "conversations";
export const COLLECTION_CHATS = "chats";

// New multi-conversation collections
export const COLLECTION_USER_CONVERSATIONS = "userConversations";
export const COLLECTION_CONVERSATION_MESSAGES = "conversationMessages";

// ─── Title Generation ────────────────────────────────────────────────────────
export const AI_MAX_TOKENS_TITLE = 20;

// ─── Opportunity Query Limits ────────────────────────────────────────────────
export const QUERY_LIMIT_PRIMARY = 15;
export const QUERY_LIMIT_FALLBACK = 10;
export const QUERY_LIMIT_HEALTH = 1;
export const MIN_RESULTS_BEFORE_FIELD_FILTER = 3;

// ─── Profile Extraction Thresholds ───────────────────────────────────────────
// How many user messages before we attempt profile extraction
export const PROFILE_EXTRACT_AFTER = 3;
// How many user messages before we inject the partial-profile hint
export const PROFILE_HINT_AFTER = 2;

// ─── Protocol Constants ──────────────────────────────────────────────────────
export const START_MESSAGE = "__start__";

// ─── CORS ────────────────────────────────────────────────────────────────────
// Comma-separated allowed origins (override via env for production)
const DEFAULT_ORIGINS = [
  "http://localhost:8080",
  "http://127.0.0.1:8080",
];

export function getAllowedOrigins(): string[] {
  const env = process.env.CORS_ORIGINS;
  if (env) {
    return env.split(",").map((o) => o.trim()).concat(DEFAULT_ORIGINS);
  }
  return DEFAULT_ORIGINS;
}

// ─── Rate Limiting ───────────────────────────────────────────────────────────
export const RATE_LIMIT_WINDOW_MS = parseInt(
  process.env.RATE_LIMIT_WINDOW_MS || "60000",
  10
);
export const RATE_LIMIT_MAX = parseInt(
  process.env.RATE_LIMIT_MAX || "30",
  10
);
