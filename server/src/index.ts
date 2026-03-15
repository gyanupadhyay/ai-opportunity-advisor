import "dotenv/config";
import express from "express";
import cors from "cors";
import rateLimit from "express-rate-limit";
import { handleChatMessage } from "./chat_handler";
import adminRoutes from "./admin_routes";
import { firebaseAuthMiddleware } from "./auth_middleware";
import {
  AI_MODEL,
  AI_MAX_TOKENS_HEALTH,
  COLLECTION_OPPORTUNITIES,
  QUERY_LIMIT_HEALTH,
  getAllowedOrigins,
  RATE_LIMIT_WINDOW_MS,
  RATE_LIMIT_MAX,
} from "./config";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(
  cors({
    origin: getAllowedOrigins(),
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  })
);
app.use(express.json());
app.use(firebaseAuthMiddleware);

const limiter = rateLimit({
  windowMs: RATE_LIMIT_WINDOW_MS,
  max: RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please try again later." },
});
app.use("/handleChatMessage", limiter);

app.get("/", (_req, res) => {
  res.json({ status: "ok", service: "AI Opportunity Advisor API" });
});

// Sitemap for search engines (avoids Firebase Hosting fetch issues)
const SITEMAP_XML = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://ai-opportunity-advisor.web.app/</loc>
    <lastmod>2026-03-15</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://ai-opportunity-advisor.web.app/login</loc>
    <lastmod>2026-03-15</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://ai-opportunity-advisor.web.app/chat</loc>
    <lastmod>2026-03-15</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>
</urlset>`;

app.get("/sitemap.xml", (_req, res) => {
  res.type("application/xml").send(SITEMAP_XML);
});

app.get("/health", async (_req, res) => {
  const checks: Record<string, string> = {};

  checks.groqKey = process.env.GROQ_API_KEY ? "set" : "MISSING";
  checks.firebaseServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT ? "set" : "MISSING";

  try {
    const Groq = (await import("groq-sdk")).default;
    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY! });
    const r = await groq.chat.completions.create({
      model: AI_MODEL,
      messages: [{ role: "user", content: "Reply with OK" }],
      max_tokens: AI_MAX_TOKENS_HEALTH,
    });
    checks.groqApi = r.choices[0]?.message?.content ? "ok" : "empty response";
  } catch (e: any) {
    checks.groqApi = `ERROR: ${e.message}`;
  }

  try {
    const { db } = await import("./firebase");
    const snap = await db
      .collection(COLLECTION_OPPORTUNITIES)
      .limit(QUERY_LIMIT_HEALTH)
      .get();
    checks.firestore = snap.empty ? "ok (empty)" : `ok (${snap.size} doc)`;
  } catch (e: any) {
    checks.firestore = `ERROR: ${e.message}`;
  }

  const allOk = !Object.values(checks).some(
    (v) => v.includes("ERROR") || v === "MISSING"
  );
  res.status(allOk ? 200 : 500).json({ healthy: allOk, checks });
});

app.post("/handleChatMessage", handleChatMessage);
app.use("/admin", adminRoutes);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
