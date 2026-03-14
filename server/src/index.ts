import "dotenv/config";
import express from "express";
import cors from "cors";
import { handleChatMessage } from "./chat_handler";

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

app.get("/", (_req, res) => {
  res.json({ status: "ok", service: "AI Opportunity Advisor API" });
});

app.get("/health", async (_req, res) => {
  const checks: Record<string, string> = {};

  checks.geminiKey = process.env.GEMINI_API_KEY ? "set" : "MISSING";
  checks.firebaseServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT ? "set" : "MISSING";

  try {
    const { GoogleGenAI } = await import("@google/genai");
    const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY! });
    const r = await ai.models.generateContent({
      model: "gemini-2.0-flash",
      contents: "Reply with OK",
      config: { maxOutputTokens: 10 },
    });
    checks.geminiApi = r.text ? "ok" : "empty response";
  } catch (e: any) {
    checks.geminiApi = `ERROR: ${e.message}`;
  }

  try {
    const { db } = await import("./firebase");
    const snap = await db.collection("opportunities").limit(1).get();
    checks.firestore = snap.empty ? "ok (empty)" : `ok (${snap.size} doc)`;
  } catch (e: any) {
    checks.firestore = `ERROR: ${e.message}`;
  }

  const allOk = !Object.values(checks).some((v) => v.includes("ERROR") || v === "MISSING");
  res.status(allOk ? 200 : 500).json({ healthy: allOk, checks });
});

app.post("/handleChatMessage", handleChatMessage);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
