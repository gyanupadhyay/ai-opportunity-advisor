import { Router, Request, Response, NextFunction } from "express";
import { db, admin } from "./firebase";

const router = Router();

function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const password = process.env.ADMIN_PASSWORD;
  if (!password) {
    res.status(500).json({ error: "ADMIN_PASSWORD not configured on server" });
    return;
  }

  const provided = req.headers.authorization?.replace("Bearer ", "");
  if (provided !== password) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }

  next();
}

router.use(authMiddleware);

router.get("/opportunities", async (_req: Request, res: Response) => {
  try {
    const snapshot = await db.collection("opportunities").orderBy("title").get();
    const opportunities = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    res.json({ opportunities, total: opportunities.length });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});

router.post("/opportunities", async (req: Request, res: Response) => {
  try {
    const {
      title, type, country, field, educationLevel,
      deadline, description, applicationLink,
    } = req.body;

    if (!title || !type) {
      res.status(400).json({ error: "title and type are required" });
      return;
    }

    const data = {
      title,
      type,
      country: country || "Global",
      field: field || "Multiple Fields",
      educationLevel: educationLevel || "any",
      deadline: deadline || "Rolling",
      description: description || "",
      applicationLink: applicationLink || "",
      source: "manual",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const ref = await db.collection("opportunities").add(data);
    res.status(201).json({ id: ref.id, ...data });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});

router.put("/opportunities/:id", async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const docRef = db.collection("opportunities").doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: "Opportunity not found" });
      return;
    }

    const updates: Record<string, unknown> = {};
    const allowed = [
      "title", "type", "country", "field", "educationLevel",
      "deadline", "description", "applicationLink",
    ];

    for (const key of allowed) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }

    await docRef.update(updates);
    res.json({ id, ...doc.data(), ...updates });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});

router.delete("/opportunities/:id", async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const docRef = db.collection("opportunities").doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).json({ error: "Opportunity not found" });
      return;
    }

    await docRef.delete();
    res.json({ deleted: true, id });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
