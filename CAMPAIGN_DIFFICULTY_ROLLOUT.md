# Campaign visual and difficulty rollout

## Changes
- All 100 levels retain their IDs, names, starts, authored routes, and district membership (20 per district). No save fields or player saves changed.
- Levels 1–5 have byte-equivalent parsed level definitions to the pre-change snapshot: their existing easy introduction is preserved.
- Levels 6–20: Hard; 21–60: Very hard; 61–100: Extreme. These are tuning bands, not a claim of human playtest certification.
- Added 640 collision-enabled cones across 74 layouts: 120/144/132/122/122 by district. Other layouts retain existing obstacles and receive the stricter parking settings. Cones form sustained straight approach corridors while keeping turning arcs and spawn/target footprints clear.
- Levels 6–100 use progressive bay limits of 3.05 × 5.85 m down to 2.55 × 5.30 m, alignment tolerance of 9 down to 5.5 degrees, and stationary holds of 1.2–1.6 seconds. Added corridor clear widths decrease from 4.3 to 3.6 m. Vehicle speed/physics and three-hit failure are unchanged.
- Gold time allowances increased 12% for changed levels to accommodate careful driving; silver allows at least 1.65 times gold. No countdown failure added. Coin amounts and saved reward eligibility remain unchanged.
- All districts now use the automotive concrete/asphalt/epoxy material library, architectural perimeter detailing, metal rails, fixtures, district signage, drainage, and road markings. Downtown adds windowed buildings; Rooftops retain a flat guarded deck with lower skyline; indoor districts reuse scaled garage architecture and distinct trim.
- Concrete obstacle materials now match the surroundings. Static batching separates mesh classes so bevel geometry does not disappear when combined with textured BoxMeshes. No renderer switch, downloaded assets, new lights, or gameplay colliders in decorative architecture.

## Files
- Modified: `data/campaign_levels.json`, `scripts/district_world.gd`, `scripts/automotive_world.gd`.
- Added: `tools/harden_campaign.py`, `tools/fixtures/campaign_before_difficulty_rollout.json`, `tools/capture_district_rollout.gd`, this report.
- The Python tuning tool is deterministic against its preserved snapshot; do not run it over later hand-authored edits without updating the baseline deliberately.
- Test logs, isolated test saves, screenshots, and metrics are under `artifacts/`.

## Validation actually performed
- All 100 levels × all 12 cars: 8,400 passing checks. Each run checks district/ID, unique collision layout, grounded spawn, clear spawn and destination footprints, scripted driving through the existing controller to actual completion, and restart. Logs: `all100_<imported-car>.log`, `difficulty_metro.log`, `difficulty_touring.log`, `difficulty_sport.log`.
- 130 current expansion-system checks passed, plus 2 checks in a separate process restoring the test save. Includes migration, unlocks, selected vehicle, coins, settings, four touch arrows, three-hit failure/retry, reverse parking containment/hold, and navigation.
- Programmatic comparison confirms the first five definitions are unchanged and all 100 IDs, names, and routes are retained.
- Compatibility renderer launched successfully. Captures cover Levels 1, 6, 21, 41, 61, 81, 100. Visual inspection caught and corrected disappearing bevel geometry after material merging. Final screenshots show concrete obstacles again.
- Desktop warm stationary Level 100 profiling is recorded in `artifacts/district_rollout_metrics.json`. This is a small desktop sample, not an Android performance claim.

## Limits
- Automated route driving is not manual playtesting. Human difficulty, alternate routes, and medal-time fairness need playtesting; headless run elapsed times are not used to establish achievable medal targets.
- No physical Android testing performed. Existing vehicle-asset licensing/trial limitations remain unchanged.
- Godot reports the existing Windows root certificate store warning. It does not prevent local gameplay/checks; no new unresolved script errors were seen in the final capture.

## Run
Open `project.godot` in Godot and press F6 only for a standalone scene, or F5 to launch the full campaign. Choose an unlocked level. Existing player progress and purchases are preserved; validation uses separate `res://artifacts/` saves.
