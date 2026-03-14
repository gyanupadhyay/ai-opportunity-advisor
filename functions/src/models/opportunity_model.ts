/**
 * Type definitions for the `opportunities` Firestore collection.
 */

export interface Opportunity {
  title: string;
  type: string;
  country: string;
  field: string;
  educationLevel: string;
  deadline: string;
  description: string;
  applicationLink: string;
}

/**
 * Maps user-facing opportunity type labels (as extracted by the AI) to the
 * lowercase values stored in Firestore documents.
 */
export const OPPORTUNITY_TYPE_MAP: Record<string, string> = {
  scholarships: "scholarship",
  scholarship: "scholarship",
  internships: "internship",
  internship: "internship",
  fellowships: "fellowship",
  fellowship: "fellowship",
  "research programs": "research",
  research: "research",
  "global summits": "summit",
  summit: "summit",
  "exchange programs": "exchange",
  exchange: "exchange",
};
