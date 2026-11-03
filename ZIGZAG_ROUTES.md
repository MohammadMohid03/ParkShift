# Long zigzag parking routes

This supersedes the corridor geometry in `CAMPAIGN_DIFFICULTY_ROLLOUT.md`.

## Layout changes
- Levels 1–5 retain their previous definitions and introductory difficulty.
- Levels 6–100 now have 74.7–125.9 metre slalom routes. Levels 6–35 have three alternating bends, 36–70 four, and 71–100 five; amplitude, spacing, mirroring and orientation vary per level.
- All 17 reverse challenges after Level 5 now follow a curved zigzag approach. Their camera faces along the reverse route consistently, including on restart, rather than looking away from the cones. Switching pedals does not spin the camera.
- Each changed layout has 119–211 collision-enabled cones forming both edges, with approximately 1.1 m spacing. The rounded turns allow the existing cars to maneuver; no steering/physics changes were made.
- The last straight section provides room to align for the tight final parking maneuver. Neighbour cars face parallel to the target, with centre offsets of 2.13–2.23 m, leaving about 23–33 cm between the widest 1.98 m car and the 1.82 m neighbour collision footprint when centered. Narrow cars naturally have more clearance.
- Larger arenas accommodate the longer routes; floor joints and drainage now use the actual arena size. Existing district materials/architecture and mobile controls are retained.
- Gold/silver times are recalculated from route length and reverse driving. Rewards, level IDs, names, district grouping, stars, ownership, and save data are preserved. Old obstacle arrangements after Level 5 are replaced with the requested continuous cone slaloms.

## Files
- Modified `data/campaign_levels.json`, `scripts/district_world.gd`, `scripts/follow_camera.gd`, `scripts/campaign_level.gd`, and `tools/check_imported_campaign.py` (optional sample levels, original cars, and separate report prefixes).
- Added `tools/author_zigzag_campaign.py`, `tools/fixtures/campaign_before_zigzag.json`, `tools/capture_zigzag.gd`, this report.
- The authoring script reads the preserved snapshot and is repeatable. Older campaign authoring scripts should not be run afterward unless intentionally reverting these layouts.
- Test saves/logs and screenshots are isolated under `artifacts/`; player saves are untouched.

## Visual and performance review
- Rendered and inspected the reverse-level start, full zigzag overview, and the three-car destination arrangement using Compatibility rendering.
- Desktop Level 100 stationary sample: median 16.658 ms, p95 17.126 ms, 165 draw calls at 1152×648 on RTX 5050. This sample is not a physical Android measurement or a moving gameplay benchmark.
- Existing Windows root-certificate-store warning remains unrelated to local gameplay.

## Validation
- All 100 levels passed SUV spawn, destination footprint, driven completion and restart checks. Across two batches, all 700 unique per-level checks are present with no failures: `zigzag_touring.log`, `zigzag_touring_tail.log`, and `zigzag_full_campaign_summary.json`. The tail run printed a five-instance ObjectDB exit warning; it did not produce gameplay/script failures.
- All 12 cars passed Levels 6 and 100 (reverse and final five-bend slaloms): 168 checks, zero failures; `artifacts/zigzag_sample_results.json` and corresponding logs.
- Representative SUV trial: 13 levels across all districts, 91 checks, zero failures.
- Current campaign systems: 130 checks plus 2 fresh-process save reload checks, zero failures. Includes reverse-parking hold, touch controls, three-hit retry, unlocks and progress migration.
- Structural validation: 100 unique layouts, IDs preserved, first five unchanged, all new cones/spawns/targets within arena bounds, all 95 new routes at least 74 m, and configured gold/silver targets.
- Normal-speed automated driving with the Shelby: Level 6 reverse completed in 35.91 seconds and Level 100 in 50.60 seconds, both without hits. These are demonstrations with a cautious scripted driver, not minimum times or human difficulty ratings.
- Broad concurrent stress runs were stopped to reduce test-machine contention; their partial logs are not reported as full passes. Prior `imported_campaign_results.json` belongs to the previous rollout. Use the new `zigzag_sample_results.json` for this change.

Automated driving is not manual human playtesting. Accelerated headless elapsed wall times are not representative gameplay completion times. Physical Android testing and human difficulty balancing remain unverified.
