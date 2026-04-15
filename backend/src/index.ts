import express from "express";
import { nearbyHandler } from "./nearby";

const app = express();
const port = parseInt(process.env.PORT || "8080", 10);

app.use(express.json());

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// POI generation endpoint
app.post("/nearby", nearbyHandler);

app.listen(port, () => {
  console.log(`curio-api listening on port ${port}`);
});
