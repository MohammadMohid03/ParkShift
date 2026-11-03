# Detailed-car local trial

## Collection and structure

All nine user-supplied GLBs are integrated as local-development trial cars, alongside
the three existing Kiln vehicles: **12 garage entries, nine newly detailed assets**.
The original source files, original three save IDs, 100 level definitions, player
save and campaign systems are preserved. This does not satisfy ten commercially
cleared detailed vehicles: only nine detailed source files were supplied.

- `assets/cars/`: untouched source GLBs and Godot-extracted source textures.
- `assets/cars/prepared/`: normalized derivatives, extracted textures/import metadata,
  and per-car JSON describing dimensions, wheel pivots, sources and modifications.
- `data/imported_cars.json`: stable IDs, garage labels, prices, dimensions and wheel data.
- `tools/prepare_imported_cars.py`: repeatable offline preparation using numpy/Pillow.
  Run `python tools/prepare_imported_cars.py --car all` to rebuild derivatives, then
  let Godot import them. There are no new runtime plugins or dependencies.
- `scripts/imported_car_catalog.gd`: shared manifest reader.
- `scripts/imported_car_visual.gd`: textured mesh adapter with Body and four separate
  steering pivots, each containing Roll/WheelMesh; dedicated brake materials.
- Existing vehicle profile, controller, parking footprint and garage code reuse
  these adapters. No replacement driving physics or campaign rebuild.

Cars are uniformly scaled, never stretched, to fit existing campaign clearances.
Individual wheelbases, visual radii and full footprints feed the existing controller.
Maximum forward speed is 6.5 m/s; steering is tuned for a 3 m low-speed turning radius.
Four independent wheel pivots steer/roll; rear lamps respond to braking.
Source paint, glass, wheels, interiors and body details remain present.

## Garage and saves

New cars cost 750, 1,000, 1,250, 1,750, 2,500, 3,000, 3,500, 4,000 and 5,000 coins.
They use the existing confirmation, ownership, single-charge purchase and save logic.
New players still own only Metro. Existing owners and selections remain intact.
All additional cars cost 24,750 coins including the original Sport and Touring;
the campaign offers 34,750 total Gold entitlement. Previewing locked cars is free.

Open `project.godot` in Godot, wait for imports, then press **F5** for the full game. Choose Garage and use its scroll list or Previous/Next buttons.
Unlock a car with earned coins, confirm, then Select it before starting a level.
All validation uses separate `res://artifacts/` saves; the player's save is untouched.

## Validation

- Godot 4.7.2 imports all nine prepared cars under the existing Compatibility renderer.
- Nine garage previews and nine gameplay screenshots captured; every garage preview
  visually inspected for recognizable bodywork, preserved textures and proportions.
- `check_imported_cars.gd`: 117 checks passed, covering all nine models, four wheel
  pivots, ground contact, movement/rotation, brake mappings, footprints, locked
  selection, single-charge purchases and restart state.
- Separate process reload: all nine purchases and final selection persisted (10 checks).
- Phase 7 fresh-process reward and purchased-selection regression: 4 checks passed.
- Expanded Phase 7 suite: 439 checks passed for rewards, timers, migration, transaction
  safety, garage wrapping, completion UI and life/restart behavior.
- Seven representative levels per new car: 441 automated checks passed, including
  driven completion and restart in every district. Full campaign sweep: **all nine cars drove all 100 levels and restarted successfully**
  (900 car/level combinations; 6,300 checks, zero failures). Detailed per-car results:
  `artifacts/imported_campaign_results.json` and `artifacts/all100_*.log`.
- Graphical captures and desktop render counters: `artifacts/imported_render_metrics.json`.
  These samples include shader compilation/loading and concurrent headless checks,
  so process-time values are not steady-state benchmarks or Android performance results.

Driving validation is scripted steering/throttle through routes, not teleporting to
completion and not manual human playtesting. Fixed-FPS accelerated tests validate
physics/completion, not achievable real-world medal times. No Android export/device
test was performed during this integration.

## Release limitations

See `assets/cars/TRIAL_ASSETS.md` for every source, author and embedded license.
Six assets prohibit commercial use; all nine are branded and underlying design,
logo, livery and model provenance rights remain unverified. These are **local trial
assets, not commercially cleared release assets**.

Textures are capped at 1024 pixels, compatible surfaces merged, preview floors and
known duplicate blurred wheels removed, and Godot-generated LODs preferred. Dense
race cars remain roughly 375k–489k source triangles; no polygon decimation occurred.
Dedicated mobile LOD work and physical-device profiling are still needed. Exact
counts and omitted incompatible UV maps are in each car's JSON. Stradale's original
specular/glossiness materials undergo Godot's approximate PBR conversion.

Raw source GLBs and their extracted textures are excluded from the Android export
preset to avoid shipping duplicate source data. Prepared assets remain included;
this filtering has not been validated by an APK export.

The restricted test environment reports unavailable root certificates, denied writes
to global Godot editor settings and shader cache, and occasional ObjectDB instances
at test-process exit. These remain environment/test-exit warnings; no GDScript parse
or runtime error was observed in the successful checks.

## Files created or changed

Created: `scripts/imported_car_catalog.gd`, `scripts/imported_car_visual.gd`,
`data/imported_cars.json`, all nine prepared GLBs/JSONs and generated import resources,
`tools/prepare_imported_cars.py`, `tools/check_imported_cars.gd`,
`tools/capture_imported_cars.gd`, `tools/check_imported_campaign.py`,
`assets/cars/TRIAL_ASSETS.md`, this report.

Changed: `scripts/car.gd`, `scripts/vehicle_profiles.gd`,
`scripts/vehicle_visual.gd`, `scripts/level_catalog.gd`, `scripts/campaign.gd`,
`data/economy.json`, `export_presets.cfg`, `tools/check_phase7.gd`, `PHASE7.md`.
Test logs, screenshots and isolated saves are under `artifacts/`.

## Repeat the full campaign check

After Godot imports finish, run:

```powershell
python tools/check_imported_campaign.py --godot "C:/path/to/Godot.exe" --workers 3
```

This validates each car on all 100 levels using test-only save files, prints results
and writes `artifacts/imported_campaign_results.json`. It does not modify player progress.
