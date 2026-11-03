# Workshop UI redesign

Installed and applied create-game-assets, godot-ui-control, game-ui-ux,
godot-3d-essentials and level-design from gamedev-skills/awesome-gamedev-agent-skills.
The selected visual system is recorded in assets/art-direction-brief.md; asset
sources and font terms are recorded in assets/asset-manifest.json and assets/fonts/OFL.txt.

Changes:
- Shared charcoal/chalk/citron theme and bundled Barlow typography.
- Home screen shows actual completion/stars, the selected vehicle and a Continue action.
- Garage has a larger showroom preview and one swipe-scrollable list of all 12 cars,
  with lightweight vector silhouettes, prices/ownership and a clear selected state.
- Level selection has five district illustrations and clearer number/name/record hierarchy.
- Settings, pause and results inherit the same type/colors/control states.
- HUD is slimmer; existing 124 px touch targets, pressed-only highlighting and compact
  parking feedback are retained. Detailed targets/rewards remain in Pause.
- District atmosphere/floor palettes and the menu showroom have been updated using
  the existing mobile-compatible renderer, without adding realtime lights or collisions.

The driving controller, level IDs, route data, economy and save schema are unchanged.
Original detailed-car licensing restrictions remain in assets/cars/TRIAL_ASSETS.md.

Graphical checks: tools/check_mobile_ui.gd (isolated save; no --headless).
Visual captures: tools/capture_workshop.gd (isolated save; no --headless).
Campaign checks: tools/check_phase7.ps1, tools/check_campaign_data.ps1.
Driving samples: tools/check_expansion.ps1 -Only '1,20,40,60,80,100'.
Build and signature/package verification: tools/build_android.ps1.

Verification results: 443 campaign/reload, 95 schema/error handling, 21 graphical
UI, 58 resource and 42 representative driving assertions passed (659 total).
Rendered menus, compact HUD and all five district atmospheres were inspected.
The verified APK was installed on the connected Samsung SM-A175F with data kept.
Startup logs show the Compatibility renderer and no fatal/script errors; the phone
was locked during the final visual check. Unlock it to try the redesign.
