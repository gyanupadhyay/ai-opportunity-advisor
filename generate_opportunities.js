/**
 * AI-Powered Opportunity Generator
 *
 * Uses Groq AI (Llama 3.3 70B) to generate 200+ realistic opportunities
 * and writes them to the Firestore "opportunities" collection.
 *
 * Usage:
 *   cd server && npm install && cd ..
 *   node generate_opportunities.js
 *
 * Requires server/.env with GROQ_API_KEY and FIREBASE_SERVICE_ACCOUNT set.
 */

const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "server", ".env") });

const Groq = require("groq-sdk");
const admin = require("firebase-admin");

const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
if (serviceAccountEnv) {
  const serviceAccount = JSON.parse(serviceAccountEnv);
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
} else {
  admin.initializeApp();
}

const db = admin.firestore();
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const BATCHES = [
  {
    category: "Scholarships - Global & Europe",
    count: 25,
    prompt: `Generate 25 real international scholarships for students. Include well-known ones like:
- Chevening (UK), DAAD (Germany), Erasmus Mundus (EU), Gates Cambridge, Rhodes (Oxford)
- Swedish Institute, Swiss Government Excellence, Eiffel (France), Australia Awards
- Country-specific scholarships from Netherlands, Japan, South Korea, China, Turkey, Hungary
Each must be a REAL scholarship with a REAL application website. Mix undergraduate and graduate levels.`,
  },
  {
    category: "Scholarships - Americas & Asia",
    count: 25,
    prompt: `Generate 25 real international scholarships focusing on Americas and Asia:
- Fulbright, LASPAU, OAS, Canadian Commonwealth, Vanier (Canada)
- MEXT (Japan), KGSP (South Korea), CSC (China), ICCR (India), ADB-JSP (Asia)
- Regional: MasterCard Foundation, AAUW, Rotary Peace Fellowship
- University-specific: MIT, Stanford, Harvard, NUS, Tsinghua merit scholarships
Each must be a REAL scholarship with a REAL application website. Mix undergraduate and graduate levels.`,
  },
  {
    category: "Internships - Tech",
    count: 25,
    prompt: `Generate 25 real tech internships for students:
- Google (STEP, SWE intern), Microsoft (Explore, SWE), Amazon (Future Engineer, SDE), Meta, Apple
- Startups and mid-size: Stripe, Shopify, Databricks, Figma, Notion
- Open source: Google Summer of Code, MLH Fellowship, Outreachy, Linux Foundation
- Research: Google Research, Microsoft Research, DeepMind, OpenAI
Each must be a REAL internship program with a REAL application website. Mix undergraduate levels.`,
  },
  {
    category: "Internships - Non-Tech",
    count: 25,
    prompt: `Generate 25 real non-tech internships for students across various fields:
- International orgs: United Nations, World Bank, IMF, WHO, UNICEF, UNDP, WTO
- Government: US State Dept (Pathways), EU Parliament, NATO
- Finance: Goldman Sachs, JP Morgan, McKinsey, BCG, Deloitte
- Media/Arts: BBC, NYT, National Geographic, Smithsonian
- NGOs: Red Cross, Amnesty International, WWF, Doctors Without Borders
Each must be a REAL internship with a REAL application website.`,
  },
  {
    category: "Fellowships",
    count: 30,
    prompt: `Generate 30 real fellowships for students and young professionals:
- Research: Fulbright, Humboldt, Marie Curie, Royal Society, Newton Fund
- Leadership: Obama Foundation, Echoing Green, Ashoka, Mandela Washington, Yenching Academy
- Social impact: Acumen, Atlas Corps, Peace Corps, Teach For All, Kiva
- Policy: Hertie School, Schwarzman Scholars, Knight-Hennessy, Soros Fellowship
- Field-specific: Wellcome Trust (health), Ford Foundation, MacArthur
Each must be a REAL fellowship with a REAL application website.`,
  },
  {
    category: "Research Programs",
    count: 25,
    prompt: `Generate 25 real research programs and opportunities for students:
- Physics/Engineering: CERN, DESY, Fermilab, SLAC, ESA, NASA JPL
- Biology/Medicine: NIH, Pasteur Institute, Max Planck, Wellcome Sanger
- University summer research: MIT UROP, Caltech SURF, Stanford SURGE, ETH Student Research
- International: RIKEN (Japan), KAIST (Korea), Weizmann Institute (Israel), CSIRO (Australia)
- Multidisciplinary: Santa Fe Institute, Perimeter Institute, Kavli Foundation
Each must be a REAL research program with a REAL application website.`,
  },
  {
    category: "Exchange Programs",
    count: 20,
    prompt: `Generate 20 real student exchange and cultural programs:
- Government-funded: Fulbright, AIESEC, AFS, YFU, Rotary Youth Exchange
- Regional: Erasmus+ Student Exchange, UMAP (Asia-Pacific), ISEP
- Country-specific: DAAD exchange, JASSO (Japan), Campus France, Study in Holland
- Short-term: SAKURA (Japan), JENESYS, Global UGRAD, Community Solutions
- Virtual/hybrid exchanges: Stevens Initiative, Soliya Connect
Each must be a REAL exchange program with a REAL application website.`,
  },
  {
    category: "Summits & Conferences",
    count: 20,
    prompt: `Generate 20 real global summits, conferences, and leadership programs for young people:
- Leadership: One Young World, Global Shapers (WEF), Millennium Fellowship, UNLEASH
- Tech: Web Summit, CES student program, Grace Hopper Celebration, PyCon
- Social impact: Clinton Global Initiative University, SocEntTO, Ashoka U Exchange
- Regional: European Youth Forum, African Union Youth Summit, ASEAN Youth Forum
- Academic: Nobel Laureate Meeting (Lindau), Model United Nations (WorldMUN, HNMUN)
Each must be a REAL event/program with a REAL application website.`,
  },
];

async function generateBatch(batch) {
  const systemPrompt = `You are a database generator. Output ONLY a valid JSON array of opportunity objects. No markdown, no explanation, no code fences. Each object must have exactly these fields:
- "title": string (official program name)
- "type": one of "scholarship", "internship", "fellowship", "research", "exchange", "summit"
- "country": string (country or "Global" or region like "Europe")
- "field": string (e.g., "Computer Science", "Multiple Fields", "Engineering", "Medicine", "Business", "Leadership", "Science & Technology")
- "educationLevel": one of "undergraduate", "graduate", "phd", "any"
- "deadline": string (realistic month + year, e.g., "November 2026", or "Rolling")
- "description": string (1-2 sentences describing the program)
- "applicationLink": string (real URL to the official program page)

Output exactly ${batch.count} objects. Use REAL programs with REAL URLs. Do NOT invent fake programs.`;

  const response = await groq.chat.completions.create({
    model: "llama-3.3-70b-versatile",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: batch.prompt },
    ],
    temperature: 0.3,
    max_tokens: 8000,
  });

  const text = response.choices[0]?.message?.content ?? "[]";

  const jsonMatch = text.match(/\[[\s\S]*\]/);
  if (!jsonMatch) {
    console.error(`  Failed to parse JSON for "${batch.category}". Raw output:\n${text.slice(0, 200)}`);
    return [];
  }

  try {
    return JSON.parse(jsonMatch[0]);
  } catch (e) {
    console.error(`  JSON parse error for "${batch.category}": ${e.message}`);
    return [];
  }
}

async function main() {
  console.log("Generating opportunities using Groq AI...\n");

  const allOpportunities = [];

  for (const batch of BATCHES) {
    process.stdout.write(`  Generating: ${batch.category} (${batch.count})...`);
    try {
      const results = await generateBatch(batch);
      console.log(` got ${results.length}`);
      allOpportunities.push(...results);
    } catch (e) {
      console.error(` ERROR: ${e.message}`);
    }
    await new Promise((r) => setTimeout(r, 2000));
  }

  console.log(`\nTotal generated: ${allOpportunities.length}`);

  const existing = await db.collection("opportunities").get();
  const existingTitles = new Set(existing.docs.map((d) => d.data().title?.toLowerCase()));
  console.log(`Existing in Firestore: ${existingTitles.size}`);

  const newOpps = allOpportunities.filter(
    (opp) => opp.title && !existingTitles.has(opp.title.toLowerCase())
  );
  console.log(`New (after dedup): ${newOpps.length}\n`);

  if (newOpps.length === 0) {
    console.log("Nothing new to add.");
    process.exit(0);
  }

  const FIRESTORE_BATCH_SIZE = 500;
  for (let i = 0; i < newOpps.length; i += FIRESTORE_BATCH_SIZE) {
    const chunk = newOpps.slice(i, i + FIRESTORE_BATCH_SIZE);
    const batch = db.batch();

    for (const opp of chunk) {
      const ref = db.collection("opportunities").doc();
      batch.set(ref, {
        title: opp.title || "",
        type: opp.type || "scholarship",
        country: opp.country || "Global",
        field: opp.field || "Multiple Fields",
        educationLevel: opp.educationLevel || "any",
        deadline: opp.deadline || "Rolling",
        description: opp.description || "",
        applicationLink: opp.applicationLink || "",
        source: "ai-generated",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`  Wrote batch ${Math.floor(i / FIRESTORE_BATCH_SIZE) + 1} (${chunk.length} docs)`);
  }

  console.log(`\nDone — ${newOpps.length} new opportunities added to Firestore.`);
  process.exit(0);
}

main().catch((err) => {
  console.error("Failed:", err);
  process.exit(1);
});
