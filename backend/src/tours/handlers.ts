// HTTP handlers for the tours API.
//
//   GET /tours                              → catalog list
//   GET /tours/:id                          → full tour manifest including waypoint narration text
//   GET /tours/:id/audio/:waypointId.mp3    → streamed mp3 (pre-generated, served from disk)
//
// Audio is pre-generated at build time by `npm run synthesize-tours` and
// committed under backend/audio-cache/{tourId}/{waypointId}.mp3. The running
// service does NOT call ElevenLabs at request time. This keeps the runtime
// fast, deterministic, and free of an outbound dependency on a third-party
// API. If a requested audio file isn't on disk, we 404 — that's a deploy bug
// we want to surface loudly, not paper over with a slow on-demand fallback.

import { Request, Response } from "express";
import path from "node:path";
import fs from "node:fs";
import { findTour, TOURS } from "./registry";
import { tourSummary } from "./types";

const AUDIO_CACHE_DIR = path.join(__dirname, "..", "..", "audio-cache");

export function listToursHandler(_req: Request, res: Response) {
  res.json({ tours: TOURS.map(tourSummary) });
}

export function getTourHandler(req: Request, res: Response) {
  const id = String(req.params.id);
  const tour = findTour(id);
  if (!tour) {
    res.status(404).json({ error: "tour_not_found", id });
    return;
  }
  res.json(tour);
}

export function getTourAudioHandler(req: Request, res: Response) {
  const tourId = String(req.params.id);
  const waypointFile = String(req.params.waypointFile); // e.g. "01-bethesda-metro.mp3"

  if (!/^[a-z0-9-]+\.mp3$/.test(waypointFile)) {
    res.status(400).json({ error: "invalid_waypoint_filename" });
    return;
  }

  const tour = findTour(tourId);
  if (!tour) {
    res.status(404).json({ error: "tour_not_found", id: tourId });
    return;
  }

  const waypointId = waypointFile.replace(/\.mp3$/, "");
  const waypointExists = tour.waypoints.some((w) => w.id === waypointId);
  if (!waypointExists) {
    res.status(404).json({ error: "waypoint_not_found", waypointId });
    return;
  }

  const filePath = path.join(AUDIO_CACHE_DIR, tourId, waypointFile);
  if (!fs.existsSync(filePath)) {
    res.status(404).json({
      error: "audio_not_synthesized",
      message: "Audio file is missing from the deploy. Run `npm run synthesize-tours` and redeploy.",
      filePath,
    });
    return;
  }

  res.setHeader("Content-Type", "audio/mpeg");
  res.setHeader("Cache-Control", "public, max-age=86400");
  fs.createReadStream(filePath).pipe(res);
}
