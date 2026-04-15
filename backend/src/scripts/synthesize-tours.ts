// Pre-generate mp3 audio for every waypoint of every tour using ElevenLabs.
//
// Usage:
//   ELEVENLABS_API_KEY=<key> npx tsx src/scripts/synthesize-tours.ts
//
// Or, against the secret in Google Secret Manager:
//   ELEVENLABS_API_KEY=$(gcloud secrets versions access latest --secret=ELEVENLABS_API_KEY) \
//     npx tsx src/scripts/synthesize-tours.ts
//
// Output: backend/audio-cache/{tourId}/{waypointId}.mp3, committed to the
// repo so the running Cloud Run service serves them as static files. We do
// NOT regenerate at runtime — that keeps the request path free of an
// outbound TTS dependency and the per-tour cost is paid once at author time.
//
// Idempotent: if a file already exists on disk it is skipped. Pass --force to
// regenerate everything.

import path from "node:path";
import fs from "node:fs";
import { TOURS } from "../tours/registry";

// Voice config:
//
// - "Adam" voice (pNInz6obpgDQGcFmaJgB) is one of the ElevenLabs default
//   premade voices, deep American male — a reasonable narrator default.
//   Easy to swap later by editing this constant.
// - eleven_multilingual_v2 model: highest fidelity, slowest. We're generating
//   offline so latency does not matter; quality does.
const VOICE_ID = "pNInz6obpgDQGcFmaJgB";
const MODEL_ID = "eleven_multilingual_v2";

const API_KEY = process.env.ELEVENLABS_API_KEY;
if (!API_KEY) {
  console.error("ELEVENLABS_API_KEY env var is not set.");
  console.error("Run: ELEVENLABS_API_KEY=$(gcloud secrets versions access latest --secret=ELEVENLABS_API_KEY) npx tsx src/scripts/synthesize-tours.ts");
  process.exit(1);
}

const FORCE = process.argv.includes("--force");
const OUT_ROOT = path.join(__dirname, "..", "..", "audio-cache");

async function synthesize(text: string): Promise<Buffer> {
  const res = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`,
    {
      method: "POST",
      headers: {
        "xi-api-key": API_KEY!,
        "Content-Type": "application/json",
        Accept: "audio/mpeg",
      },
      body: JSON.stringify({
        text,
        model_id: MODEL_ID,
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.75,
          style: 0.0,
          use_speaker_boost: true,
        },
      }),
    }
  );

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`ElevenLabs ${res.status}: ${body}`);
  }

  const arrayBuf = await res.arrayBuffer();
  return Buffer.from(arrayBuf);
}

async function main() {
  let totalGenerated = 0;
  let totalSkipped = 0;

  for (const tour of TOURS) {
    const tourDir = path.join(OUT_ROOT, tour.id);
    fs.mkdirSync(tourDir, { recursive: true });

    console.log(`\n== Tour: ${tour.id} (${tour.waypoints.length} waypoints)`);

    for (const wp of tour.waypoints) {
      const outPath = path.join(tourDir, `${wp.id}.mp3`);

      if (!FORCE && fs.existsSync(outPath)) {
        console.log(`  - ${wp.id}: skip (exists)`);
        totalSkipped++;
        continue;
      }

      process.stdout.write(`  - ${wp.id}: synthesizing... `);
      try {
        const buf = await synthesize(wp.narration_text);
        fs.writeFileSync(outPath, buf);
        const kb = (buf.length / 1024).toFixed(1);
        console.log(`✓ (${kb} KB)`);
        totalGenerated++;
      } catch (err) {
        console.log(`✗`);
        console.error(err);
        process.exit(1);
      }
    }
  }

  console.log(`\nDone. Generated ${totalGenerated}, skipped ${totalSkipped}.`);
}

main();
