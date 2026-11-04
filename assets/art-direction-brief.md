# PARKSHIFT visual direction

## Frame
- Godot 4.7.2, Compatibility renderer; Android ARM64 / desktop.
- 1280 x 720 reference canvas, expanding landscape aspect; touch controls stay 124 px base.
- Precision parking with a clear road, readable bay and calm menus.

## Visual system
- Matte graphite #151b19; surfaces #202824 / #2b3530; dividers #39463e.
- Warm white #f2f1e8; secondary text #a8b3aa; primary/selection #d4ec78.
- Barlow Regular body, Barlow Condensed Semibold titles. Fonts bundled under SIL OFL.
- Small 6-10 px corners, thin borders, simple line/car icons, consistent spacing.
- One primary action per screen. Compact HUD. Pedals highlight only while held.
- A split garage uses a continuous left list and a larger 3D preview on the right.
- District selection uses original vector city plans and clear level records.
- Warm courtyard, cool downtown, open rooftop, warm precision workshop, muted master yard.
- No screen-space effects, additional realtime lights, flat bitmap backgrounds or new collision props.

## Technical and gameplay constraints
- Keep all 12 cars in a single list; swipe gestures must propagate through the rows.
- Keep 100 level IDs, all routes/clearances, physics, prices, rewards and saves intact.
- World dressing remains outside the tested collision/parking layout.
- Fonts total about 210 KiB; vector artwork and silhouettes have no raster texture budget.
- Menu backdrop, silhouettes and district plans are original code-native assets.
- Screens must remain usable at 1280x720, 1600x720 and 1280x960.

## Chosen visual target and verification
- Direction selected under the user's instruction to install skills and redesign the game.
- Captures: artifacts/realism_workshop_home.png, realism_workshop_garage.png,
  realism_workshop_district_*.png, realism_workshop_settings.png,
  realism_workshop_level_*.png, realism_workshop_pause.png.
- Automated checks cover rendered touch states, swipe behavior, layout and campaign regressions.
- Final rendering is reviewed in the actual Godot Compatibility renderer.

## District environment extension
- Original procedural architecture: courtyard workshops, office blocks, rooftop
  skyline and plant, testing hangars and loading warehouses.
- Shared generated asphalt albedo (1024 maximum import, mipmapped/compressed) and
  seamless 256-pixel procedural grain/normal maps; no flat background images.
- Material finishes, district sun angles, sky hues and subtle distance haze make
  districts distinct while keeping white course markings and mint bays readable.
- Static batching preserves texture/normal mapping and shadow state. Fixtures are
  emissive meshes, with no new realtime lights or collision objects.
- See ../DISTRICT_ENVIRONMENTS.md for render evidence and all-level collision audit.
