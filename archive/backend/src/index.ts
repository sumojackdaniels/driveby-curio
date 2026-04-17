import express from "express";
import { nearbyHandler } from "./nearby";
import {
  listToursHandler,
  getTourHandler,
  getTourAudioHandler,
} from "./tours/handlers";

const app = express();
const port = parseInt(process.env.PORT || "8080", 10);

app.use(express.json());

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// POI generation endpoint (live mode — kept for back-compat with the MVP iPhone build)
app.post("/nearby", nearbyHandler);

// Curated tours
app.get("/tours", listToursHandler);
app.get("/tours/:id", getTourHandler);
app.get("/tours/:id/audio/:waypointFile", getTourAudioHandler);

app.listen(port, () => {
  console.log(`curio-api listening on port ${port}`);
});
