# Background scenery

Added district-aware scenery to the shared world builder, so it applies across the campaign without editing level data or player saves.

- Parked hatchbacks, sedans and SUVs in painted spaces, using the existing lightweight local CC0 models documented in `assets/vehicles/SOURCES.md`.
- Original corrugated shipping containers with door bars, reflective markings and edge rails.
- Concrete tree planters, shrubs, benches, bins and utility/ventilation equipment.
- Starter Garage and Downtown emphasize parked cars/greenery. Rooftops use low planters and utility equipment. Precision Complex and Master Garage add freight/workshop props.
- Deterministic placement reserves the driving corridor, start, destination, existing parked neighbours, cones, obstacles and other scenery footprints. Candidates that do not fit are skipped. Up to six pockets in the introductory yards and eighteen in larger slalom arenas.
- Solid scenery has simple static collision. No new dynamic bodies, lights, downloaded assets or textures. Existing shared materials and static batching are reused; hidden vehicle LODs are excluded from merging, and ArrayMesh formats are grouped separately.

## Files
- Added `scripts/background_scenery.gd`.
- Updated `scripts/district_world.gd` to build scenery and keep static mesh merging compatible with its assets.
- Added this report. Preview artifacts are under `artifacts/`.

## Review
Launched the existing graphical capture utility and visually reviewed Level 6's reverse approach and the Level 100 overview/parking arrangement with Compatibility rendering. No script errors appeared in that preview; Godot still reports the pre-existing Windows certificate-store warning.

No automated regression tests or full campaign replay were run for this scenery change. Physical Android performance is unverified. Background cars are the existing economical low-poly assets, not newly imported detailed vehicle models.
