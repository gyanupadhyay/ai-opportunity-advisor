import { db, admin } from "../firebase";
import { StudentProfile } from "../models/user_model";
import { OPPORTUNITY_TYPE_MAP } from "../models/opportunity_model";
import {
  COLLECTION_OPPORTUNITIES,
  QUERY_LIMIT_PRIMARY,
  QUERY_LIMIT_FALLBACK,
  MIN_RESULTS_BEFORE_FIELD_FILTER,
} from "../config";

export async function queryOpportunities(
  profile: StudentProfile
): Promise<Record<string, unknown>[]> {
  let query: admin.firestore.Query = db.collection(COLLECTION_OPPORTUNITIES);

  if (profile.opportunityType) {
    const mapped = OPPORTUNITY_TYPE_MAP[profile.opportunityType.toLowerCase()];
    if (mapped) {
      query = query.where("type", "==", mapped);
    }
  }

  let snapshot = await query.limit(QUERY_LIMIT_PRIMARY).get();
  let results = snapshot.docs.map((doc) => doc.data());

  if (results.length === 0) {
    const fallback = await db
      .collection(COLLECTION_OPPORTUNITIES)
      .limit(QUERY_LIMIT_FALLBACK)
      .get();
    results = fallback.docs.map((doc) => doc.data());
  }

  results = filterByField(results, profile.field);
  results = filterByRegion(results, profile.preferredRegion);

  return results;
}

function filterByField(
  results: Record<string, unknown>[],
  field: string | null
): Record<string, unknown>[] {
  if (!field || results.length <= MIN_RESULTS_BEFORE_FIELD_FILTER) return results;

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
