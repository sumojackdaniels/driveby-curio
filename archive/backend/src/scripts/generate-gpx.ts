// Generate a .gpx file for one tour, suitable for loading into the Xcode iOS
// Simulator's "Simulate Location" feature.
//
// Usage:
//   npx tsx src/scripts/generate-gpx.ts connecticut-avenue > sim/connecticut-avenue.gpx
//
// Behaviour:
//   - Reads the tour's waypoint list.
//   - For each consecutive pair of waypoints, interpolates N intermediate
//     points along a great-circle line so the simulator emits a smooth
//     stream of location updates, not just 9 jumps.
//   - Spaces the timestamps so each narration window is ~SEGMENT_DURATION_SEC
//     long. With 9 waypoints and 95 sec/segment that's a ~14-minute sim run.
//   - Writes a single <trk>/<trkseg> with <trkpt> entries, each carrying
//     <time> in ISO 8601 UTC. The iOS Simulator parses these and advances
//     through the points in real time.
//
// Note: the iOS Simulator's GPX consumption respects timestamps — points
// fire at the difference between consecutive <time> elements. If you find
// the playback too slow when iterating, lower SEGMENT_DURATION_SEC and
// regenerate.

import { findTour } from "../tours/registry";

const SEGMENT_DURATION_SEC = 110; // time between hitting waypoint N and waypoint N+1
// Sized so each ~75-90 second narration finishes before the next trigger fires.
// The trigger circle is 200-250m before the next waypoint center, which at
// constant simulated speed costs ~25 sec, leaving ~85 sec of audible narration
// per stop. Lower this if you want faster sim runs (some narration will get
// cut off mid-sentence as the next stop triggers).
const POINTS_PER_SEGMENT = 8;    // intermediate points (inclusive of endpoints)

const tourId = process.argv[2];
if (!tourId) {
  console.error("usage: tsx generate-gpx.ts <tour-id>");
  process.exit(1);
}

const tour = findTour(tourId);
if (!tour) {
  console.error(`tour not found: ${tourId}`);
  process.exit(1);
}

interface SimPoint {
  lat: number;
  lng: number;
  /** seconds offset from start */
  t: number;
}

function interpolate(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
  steps: number
): { lat: number; lng: number }[] {
  // Linear interpolation in lat/lng — fine for a 12 km city drive, the
  // great-circle correction is negligible at this scale.
  const out: { lat: number; lng: number }[] = [];
  for (let i = 0; i < steps; i++) {
    const f = i / (steps - 1);
    out.push({
      lat: a.lat + (b.lat - a.lat) * f,
      lng: a.lng + (b.lng - a.lng) * f,
    });
  }
  return out;
}

const points: SimPoint[] = [];
let tCursor = 0;

for (let i = 0; i < tour.waypoints.length - 1; i++) {
  const a = tour.waypoints[i];
  const b = tour.waypoints[i + 1];
  const seg = interpolate(a, b, POINTS_PER_SEGMENT);
  // Skip the first interpolated point if this isn't the first segment, to
  // avoid duplicating the joining waypoint.
  const segPoints = i === 0 ? seg : seg.slice(1);
  const dt = SEGMENT_DURATION_SEC / (segPoints.length - 1 + (i === 0 ? 0 : 1));
  for (const p of segPoints) {
    points.push({ lat: p.lat, lng: p.lng, t: tCursor });
    tCursor += dt;
  }
}

// Padding tail point so the simulator parks the location at the final
// waypoint for a while instead of immediately stopping.
const last = tour.waypoints[tour.waypoints.length - 1];
points.push({ lat: last.lat, lng: last.lng, t: tCursor + 30 });

const epoch = new Date("2026-04-15T15:00:00Z").getTime();
const isoFromOffset = (sec: number) =>
  new Date(epoch + sec * 1000).toISOString();

const trkpts = points
  .map(
    (p) =>
      `      <trkpt lat="${p.lat.toFixed(6)}" lon="${p.lng.toFixed(6)}">\n        <time>${isoFromOffset(p.t)}</time>\n      </trkpt>`
  )
  .join("\n");

const gpx = `<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="DriveByCurio generate-gpx.ts" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata>
    <name>${tour.title}</name>
    <desc>${tour.subtitle}</desc>
  </metadata>
  <trk>
    <name>${tour.id}</name>
    <trkseg>
${trkpts}
    </trkseg>
  </trk>
</gpx>
`;

process.stdout.write(gpx);
