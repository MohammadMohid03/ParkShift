# Driving controls and road features

## Player controls
- Settings → Driving controls, or Pause → Driving controls: choose **arrow buttons** or **touch wheel**.
- The wheel captures one finger (or mouse drag), supports ±135 degrees of rotation, supplies proportional steering, and returns to centre on release. A second finger can hold either right-side pedal. Keyboard controls remain available.
- Mode is stored in the existing optional `driving_settings` object. Older/malformed fields default to buttons without resetting progress, coins, cars or other preferences.
- Mode changes, pause, restart and hidden controls clear held input. Sensitivity and control-size options still apply.

## Campaign
- Levels 1–5 retain their definitions. Levels 6–100 now have 124.7–207.6 metre routes with alternating 90-degree left/right junctions. Corners retain 4.2 m fillets to accommodate the existing vehicle turning radius.
- Four, five or six cross-lane sections according to campaign tier; existing reverse flags, close neighbours, scenery, district grouping and IDs are retained.
- Each of Levels 6–100 configures one boom barrier and two speed breakers (three from Level 61). The shared builder selects straight route sections for the breakers.
- Stop at the line before the boom. Stay almost stationary for one second, then wait for **GO / BARRIER OPEN**. The arm lifts and its collision clears; it stays open for the rest of the attempt. Restart closes it. Pause freezes its state, and the closed arm remains a normal collision hazard.
- Black/yellow low-profile speed breakers apply controlled resistance toward 1.6 m/s and a subtle 3.5 cm visual bob. This is an arcade surface response on the existing flat collision floor, not new ramp/elevation physics. Breaker geometry participates in static batching; the moving gate remains separate.
- Gold/silver targets have been lengthened to accommodate the longer route, slowing and barrier stop. Base coin rewards and reward-claim/save rules are unchanged.

## Files
Modified:
- `scripts/drive_input.gd`, `scripts/driving_preferences.gd`, `scripts/progress_store.gd`, `scripts/parking_hud.gd`
- `scripts/car.gd`, `scripts/campaign_level.gd`
- `tools/author_zigzag_campaign.py`, `data/campaign_levels.json`

Added:
- `scripts/touch_steering_wheel.gd`, `scripts/road_features.gd`
- `tools/preview_road_features.gd`, this report

## Review and limits
- Graphical Compatibility-renderer previews launched without script errors. Reviewed the wheel/pedal layout, pause settings, main-menu settings, barrier closed/open presentation, and restart presentation using an isolated `res://artifacts/` save. Preview screenshots/logs are in `artifacts/road_controls_preview.log` and `realism_wheel_*.png`, `realism_boom_*.png`.
- The gate preview places the car at its stopping position; this is not a complete manually driven level.
- No automated regression suite or complete campaign driving run was performed for this change. Earlier zigzag driving results apply to earlier layouts, not these extended routes. Existing route-driving checks also need explicit stop/wait behavior for the new gate before reuse.
- Physical Android touch/performance, driving every new turn with every car, and human difficulty/medal timing remain unverified. Existing Windows certificate-store warning persists.
