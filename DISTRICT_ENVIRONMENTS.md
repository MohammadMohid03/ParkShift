# District environments

The October 2026 environment pass gives the five districts distinct architecture,
surface finishes and light, while retaining the campaign's driving layouts.

| District | Environment |
| --- | --- |
| Starter Garage | Warm courtyard, brick workshops, landscaped verges, sidewalks and driving-school entrance. |
| Downtown | Cool asphalt, varied office heights, glazed façades, parking meters and street furniture. |
| Rooftops | Concrete deck, parapet rails, lower city skyline, HVAC plant and solar panels. |
| Precision | Neutral concrete, vehicle-testing hangars, control building and safety columns. |
| Master | Freight depot at dusk, warehouse doors, loading docks, corrugated cargo and warm fixtures. |

All districts have subtle surface grain, fine normal detail, low-contrast wear,
drainage grates, district-specific sun angles and light distance haze. Existing
background obstacle proxies are retained; their skins now suit each district.

## Implementation and asset provenance

- `scripts/district_environment.gd`: original procedural architecture and dressing.
- `scripts/environment_materials.gd`: shared cached PBR surfaces; world-space UVs.
- `assets/environment/asphalt_albedo.png`: AI-generated seamless asphalt albedo,
  created with OpenAI image generation for this project on 25 October 2026.
  Source is 1254×1254; Godot import caps it at 1024, enables mipmaps and VRAM
  compression, including ETC2 on Android. It depicts aggregate only, without lane
  markings, baked lighting or signage. No third-party texture was downloaded.
- Concrete/plaster grain and fine normals use seamless 256×256 NoiseTexture2D.
  These are surface detail rather than a claim of physically scanned materials.
- Opaque architectural glass avoids alpha sorting. Lamp fixtures use emissive
  meshes with no added realtime lights. Static geometry is batched by material
  and shadow state. One directional sun remains per level.

## Verification

- Captured all five districts at 1280×720 with the real chase camera and an
  inspection overview: `artifacts/realism_district_environment_*_*.png`.
- Compared sorted box-collider transforms, sizes, layers and enabled states
  against the pre-change baseline for all 100 levels: zero differences.
  Run `tools/audit_environment_collisions.gd -- --compare` in Godot using the
  retained `artifacts/environment_collision_baseline.json` baseline. Running
  without `--compare` writes a new baseline; do not overwrite it during review.
- Campaign data: 95 checks; campaign/progression: 439 + 4 checks; resource loads:
  60 checks; graphical mobile UI: 21 checks. All passed.
- Representative driven completions (levels 1, 20, 40, 60, 80, 100): 42 checks
  passed, including grounded/clear starts and bays, completion and restart.

Desktop captures use Godot's Compatibility renderer. Recorded render counts are
inspection snapshots, not sustained phone performance measurements. Dense vehicle
scenes and the new environments still need the user's hands-on phone assessment.
Imported car trial licensing remains documented in `assets/cars/TRIAL_ASSETS.md`.
