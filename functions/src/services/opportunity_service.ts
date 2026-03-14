/**
 * Opportunity Service — queries and filters the `opportunities` Firestore
 * collection based on a student's profile.
 */

import { db } from "../firebase";
import { admin } from "../firebase";
import { StudentProfile } from "../models/user_model";
import { OPPORTUNITY_TYPE_MAP } from "../models/opportunity_model";

/**
 * Queries Firestore for opportunities matching the student's profile.
 *
 * Filtering strategy:
 *   1. Hard-filter by opportunity type (Firestore `where` clause).
 *   2. Soft-filter results by field of study (client-side includes check).
 *   3. Soft-filter results by preferred region (client-side includes check).
 *   4. Falls back to a general set if no hard-filter matches are found.
 */
export async function queryOpportunities(
  profile: StudentProfile
): Promise<Record<string, unknown>[]> {
  let query: admin.firestore.Query = db.collection("opportunities");

  if (profile.opportunityType) {
    const mapped = OPPORTUNITY_TYPE_MAP[profile.opportunityType.toLowerCase()];
    if (mapped) {
      query = query.where("type", "==", mapped);
    }
  }

  let snapshot = await query.limit(15).get();
  let results = snapshot.docs.map((doc) => doc.data());

  // Fallback: return a general set when the hard-filter yields nothing.
  if (results.length === 0) {
    const fallback = await db.collection("opportunities").limit(10).get();
    results = fallback.docs.map((doc) => doc.data());
  }

  results = filterByField(results, profile.field);
  results = filterByRegion(results, profile.preferredRegion);

  return results;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function filterByField(
  results: Record<string, unknown>[],
  field: string | null
): Record<string, unknown>[] {
  if (!field || results.length <= 3) return results;

  const fieldLower = field.toLowerCase();
  const filtered = results.filter(
    (r) =>
      (r.field as string)?.toLowerCase().includes(fieldLower) ||
      (r.field as string)?.toLowerCase().includes("multiple")
  );

  return filtered.length > 0 ? filtered : results;
}

function filterByRegion(
  results: Record<string, unknown>[],
  preferredRegion: string | null
): Record<string, unknown>[] {
  if (!preferredRegion || preferredRegion.toLowerCase() === "no preference") {
    return results;
  }

  const regionLower = preferredRegion.toLowerCase();
  const filtered = results.filter(
    (r) =>
      (r.country as string)?.toLowerCase().includes(regionLower) ||
      (r.country as string)?.toLowerCase().includes("global")
  );

  return filtered.length > 0 ? filtered : results;
}
