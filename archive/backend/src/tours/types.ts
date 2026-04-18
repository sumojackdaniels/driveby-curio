// Tour data model — shared between backend storage and HTTP API.
//
// This is the source of truth for the Tour shape. The Swift mirror lives in
// DriveByCurio/Models/Tour.swift; the two must stay in sync. Field names are
// snake_case in JSON to match existing nearby.ts conventions and to keep the
// Swift Codable mapping straightforward.

export interface Waypoint {
  /** Stable ID, slug-like ("01-bethesda-metro"). Used as the audio cache key. */
  id: string;
  /** 1-based ordering within the tour. */
  order: number;
  lat: number;
  lng: number;
  title: string;
  /** Short subject line (Now Playing "artist" slot). */
  subject: string;
  /** Distance from the waypoint at which the narration should fire. */
  trigger_radius_m: number;
  /** Hand-authored or backend-generated narration text. Sent to TTS. */
  narration_text: string;
}

export interface Tour {
  id: string;
  title: string;
  subtitle: string;
  region: string;
  duration_minutes: number;
  distance_km: number;
  cover_image_url: string | null;
  author: string;
  waypoints: Waypoint[];
}

/** Slim DTO for the catalog list — narration text and full waypoint list omitted. */
export interface TourSummary {
  id: string;
  title: string;
  subtitle: string;
  region: string;
  duration_minutes: number;
  distance_km: number;
  cover_image_url: string | null;
  author: string;
  waypoint_count: number;
}

export function tourSummary(tour: Tour): TourSummary {
  return {
    id: tour.id,
    title: tour.title,
    subtitle: tour.subtitle,
    region: tour.region,
    duration_minutes: tour.duration_minutes,
    distance_km: tour.distance_km,
    cover_image_url: tour.cover_image_url,
    author: tour.author,
    waypoint_count: tour.waypoints.length,
  };
}
