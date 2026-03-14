/**
 * AI Service — wraps all OpenAI API interactions.
 *
 * Responsibilities:
 *   - Manage the system prompt that defines Pathora AI's personality.
 *   - Generate conversational responses given a message history.
 *   - Extract a structured student profile from conversation transcripts.
 */

import OpenAI from "openai";
import {
  StudentProfile,
  ConversationMessage,
  DEFAULT_PROFILE,
} from "../models/user_model";

// ---------------------------------------------------------------------------
// Prompts
// ---------------------------------------------------------------------------

const SYSTEM_PROMPT = `You are Pathora AI, an intelligent advisor that helps students discover global opportunities such as scholarships, internships, fellowships, research programs, exchange programs, and international summits.

Your mission is to help students find opportunities that match their academic background, interests, and goals. You behave like a helpful advisor, not a generic chatbot.

Follow this structured process:

STEP 1 — UNDERSTAND THE STUDENT
If information is missing, ask questions ONE AT A TIME to understand the student's background. Important information includes:
- Country of origin
- Education level (High School, Undergraduate, Masters, PhD)
- Field of study (e.g. Computer Science, Engineering, Business, Medicine, Arts)
- Interests or career goals (e.g. AI, software development, policy, healthcare)
- Preferred countries or regions (e.g. Europe, USA, Canada, Asia, or No preference)
- Opportunity type (Scholarships, Internships, Fellowships, Research Programs, Global Summits)

STEP 2 — BUILD A STUDENT PROFILE
From the conversation, infer a structured profile covering: country, educationLevel, field, interests, preferredRegion, and opportunityType.

STEP 3 — RECOMMEND OPPORTUNITIES
When the profile is sufficiently complete, recommend opportunities that best match. Prioritize:
- Highly relevant programs
- Globally recognized programs
- Funded or partially funded opportunities

STEP 4 — PRESENT RECOMMENDATIONS CLEARLY
Format each recommendation like this:

**Opportunity Name**
Type: Scholarship / Internship / Fellowship / Research Program
Location: Country or Region
Description: Short explanation
Why it matches you: Brief personalized reason
Application link (if available)

STEP 5 — OFFER HELPFUL GUIDANCE
After recommending opportunities, provide helpful tips such as:
- Eligibility requirements
- Documents typically needed
- Preparation tips (e.g. SOP writing, recommendation letters)

STEP 6 — KEEP RESPONSES CONCISE
Avoid long explanations. Focus on clear, structured answers.

STEP 7 — STAY FOCUSED
If the user asks unrelated questions, gently redirect them toward discovering opportunities. Example: "That's a great question! But I'm best at helping you find scholarships and global opportunities — let's focus on that."

TONE GUIDELINES:
- Supportive
- Informative
- Encouraging
- Professional

START: When the conversation begins (no prior messages), greet the student warmly, introduce yourself as Pathora AI, and ask the first question about their country.`;

const EXTRACTION_PROMPT = `Analyze this conversation between a student and the Pathora AI advisor. Extract the student's profile from what they have explicitly stated.

Return ONLY a valid JSON object with these fields (use null for anything not yet mentioned):
{
  "country": "student's country of origin or null",
  "educationLevel": "High School | Undergraduate | Masters | PhD or null",
  "field": "their field of study or null",
  "interests": "their interests or career goals or null",
  "opportunityType": "Scholarships | Internships | Fellowships | Research Programs | Global Summits or null",
  "preferredRegion": "preferred country/region or null",
  "isComplete": true only if country, educationLevel, field, opportunityType, AND preferredRegion all have non-null values
}

Note: "interests" is helpful but not required for isComplete. Mark isComplete as true when the five core fields (country, educationLevel, field, opportunityType, preferredRegion) are all non-null.`;

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

let _client: OpenAI | null = null;

function getClient(): OpenAI {
  if (!_client) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error("OPENAI_API_KEY environment variable is not set");
    }
    _client = new OpenAI({ apiKey });
  }
  return _client;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/** Returns the base system prompt that defines Pathora AI's behavior. */
export function getSystemPrompt(): string {
  return SYSTEM_PROMPT;
}

/**
 * Sends the full conversation history (preceded by a system message) to
 * OpenAI and returns the assistant's reply text.
 */
export async function generateResponse(
  history: ConversationMessage[],
  systemContent: string
): Promise<string> {
  const openai = getClient();

  const messages: Array<{
    role: "system" | "user" | "assistant";
    content: string;
  }> = [{ role: "system", content: systemContent }, ...history];

  const completion = await openai.chat.completions.create({
    model: "gpt-3.5-turbo",
    messages,
    temperature: 0.7,
    max_tokens: 1500,
  });

  return (
    completion.choices[0]?.message?.content ??
    "Hi! I'm Pathora AI. I help students discover scholarships and global opportunities. Which country are you from?"
  );
}

/**
 * Asks the AI to extract a structured student profile from the conversation
 * transcript.  Returns a profile with `isComplete: true` when the five core
 * fields are all present.
 */
export async function extractProfile(
  history: ConversationMessage[]
): Promise<StudentProfile> {
  const openai = getClient();

  try {
    const transcript = history
      .map(
        (m) =>
          `${m.role === "user" ? "Student" : "Pathora AI"}: ${m.content}`
      )
      .join("\n");

    const extraction = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: EXTRACTION_PROMPT },
        { role: "user", content: transcript },
      ],
      temperature: 0,
      max_tokens: 300,
    });

    const raw = extraction.choices[0]?.message?.content ?? "{}";
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return { ...DEFAULT_PROFILE };

    return { ...DEFAULT_PROFILE, ...JSON.parse(jsonMatch[0]) };
  } catch {
    return { ...DEFAULT_PROFILE };
  }
}
