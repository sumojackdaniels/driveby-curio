// Tour registry — single source of truth for which tours exist.
//
// This is intentionally a hand-curated array, not a database. For milestone 1
// we have exactly one tour. The registry exists so that adding a second tour
// (or wiring up backend-generated tours later) is a one-line change.

import type { Tour } from "./types";
import { connecticutAvenue } from "./connecticut-avenue";

export const TOURS: Tour[] = [
  connecticutAvenue,
];

export function findTour(id: string): Tour | undefined {
  return TOURS.find((t) => t.id === id);
}
