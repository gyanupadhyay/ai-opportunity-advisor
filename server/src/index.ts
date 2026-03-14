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

app.post("/handleChatMessage", handleChatMessage);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
