# Detailed-car selection latency

## Changes

- Garage/home detailed-car resources load on a Godot worker thread. The selection
  callback no longer performs synchronous file loading. A loading label appears
  while the requested resource is being prepared.
- Only one threaded load runs at a time; rapid taps replace the pending request.
  Old results cannot replace the most recently selected preview.
- A two-car LRU cache retains recent PackedScenes and their shared materials/textures.
  The collection is not preloaded wholesale into Android memory. Gameplay reuses
  the selected cached resource; direct level entry still has a synchronous fallback.
- Re-selecting the displayed car reuses its preview node. Opening the garage no
  longer builds the selected car twice. Purchasing/selecting is guarded while loading.
- All 209 generated detailed-car texture import files now use VRAM compression.
  S3TC desktop and ETC2 mobile imports are enabled; Compatibility renderer retained.
  Source GLBs, source images, geometry, dimensions, driving and player saves are unchanged.

Godot documents these texture formats and their memory advantages in
[Importing images](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_images.html).
GPU block compression is lossy; representative car previews were visually inspected
after import, with their existing bodywork, textures, glass and wheels intact.

## Measured desktop results

Same graphical profile on the RTX 5050 laptop, with isolated test saves:

| Selection | Before display | After display | After selection callback |
|---|---:|---:|---:|
| Patrol, first access | 1,345 ms | 1,109 ms | 0.415 ms |
| Mustang, first access | 3,474 ms | 2,856 ms | 0.306 ms |
| Patrol, return from Mustang | 1,011 ms | 16 ms | 1.318 ms |
| Mustang, return from Patrol | 3,242 ms | 16 ms | 1.672 ms |
| Mustang, already displayed | 16 ms | 16 ms | 0.127 ms |

These are observations from one before/after run, not guaranteed device timings.
Logs/data: `artifacts/selection_before.*`, `artifacts/selection_after.*`.

**First access is not instant.** Worker loading removes the file-loading block,
but initial GPU upload and OpenGL shader preparation can still pause the first
display. Returning to either of the two cached cars is much faster. Cars evicted
from the bounded cache must load again. This fix does not claim to eliminate all
cold-load stutter or solve dense-mesh gameplay performance on Android.

The restricted test environment cannot save Godot's global shader cache (reports
`_save_to_cache: f.is_null()`); that limits conclusions about persistent shader
warming. No physical Android device was tested.

## Checks executed

- Headless editor import completed: desktop S3TC and mobile ETC2 texture variants
  generated; no new GDScript parse errors.
- `check_car_loading.gd`: 41 checks passed, including all nine cars, latest-tap
  selection, navigating away during loading, reuse and cache bounds.
- Existing `check_phase7.gd`: 439 checks passed (economy, timers, saves, navigation).
- Existing `check_imported_cars.gd`: 117 checks passed (models, wheel structure,
  brake materials, collision footprints, purchasing and reset).
- All nine garage and gameplay captures completed under Compatibility; Mustang,
  Stradale and Patrol garage images inspected after compression.
- Existing restricted-environment certificate/cache/editor-setting messages and
  occasional test-exit ObjectDB warnings remain. No new script error observed.

## Files

Created: `scripts/car_resource_cache.gd`, `tools/check_car_loading.gd`,
`tools/profile_car_selection.gd`, `tools/configure_car_texture_imports.py`, this report.

Modified: `scripts/campaign.gd`, `scripts/imported_car_visual.gd`, `project.godot`,
`tools/capture_imported_cars.gd`, and 209 `assets/cars/prepared/*.png.import` files.
The exact texture-file list is `artifacts/car_texture_import_changes.json`.

After future car regeneration/import, run `python tools/configure_car_texture_imports.py`
and let Godot reimport to apply the same compression settings to newly generated textures.

Run the game with F5 after stopping any older running copy and finishing editor imports.
