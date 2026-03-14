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
