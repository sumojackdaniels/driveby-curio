import Foundation
import CoreLocation

// MARK: - Tour Consumption Tokens
//
// Design tokens and shared constants for the tour consumption UI.
// The actual data types (TourSegment, TourStop, TourPath, TourAuthor)
// now live in WalkingTour.swift as first-class model types.
//
// This file previously contained synthesized computed properties that
// derived segments/paths from flat WalkingWaypoint data. That bridge
// code has been removed — the data model is now canonical.

// (This file is intentionally minimal. If you need to add shared
// consumption-layer helpers or view model logic, this is the place.)
