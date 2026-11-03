# Adjustable level camera

Drag the open 3D scene to rotate around the selected car and adjust elevation.
Pinch with two fingers that both started over the scene to zoom. Pedal and
steering fingers are excluded from camera gestures. The camera continues following
the car with the chosen relative viewing angle while driving.

The HUD offers Front, Rear and Reset view buttons. Front/Rear frame the vehicle
at 20 degrees and 9 metres, irrespective of reverse-course camera orientation.
Reset returns to the course-facing driving view at 35 degrees and 13 metres
(the earlier fixed camera was 45 degrees). Desktop controls are right-drag,
mouse-wheel zoom and C to reset. New levels start with the driving view.

Elevation is limited to 12–75 degrees, requested distance to 6–24 metres. The
existing sphere-swept SpringArm3D still retracts against world collision, so its
actual distance can be shorter near walls and parked vehicles. The camera does
not change car controls, campaign layouts, time targets or save formats.

Touches acquire camera ownership only after driving controls and the GUI decline
the initial press. Owned drag/release events continue across HUD boundaries;
cancel, pause, results and app focus changes clear ownership. Pausing retains the
chosen angle and requires fresh gestures on resume.

## Validation

`tools/check_camera_controls.gd` feeds real viewport events under the Compatibility
renderer using an isolated artifacts save. It covers drag, pinch, concurrent
pedal input, steering wheel exclusion, HUD crossing, cancel, pause/resume, bounds,
GUI presets, reverse-route orientation, camera collision, three viewport sizes,
desktop mouse controls and reset. Screenshots under `artifacts/camera_*.png`
include the hatchback, SUV and imported Shelby from different angles.
All 33 camera assertions passed. Existing checks passed: 21 graphical mobile UI,
439 + 4 campaign/persistence, 60 resource loads, and 42 representative driven
completion assertions across all districts.

Existing mobile UI, campaign/persistence, resource loading and representative
driven completion checks are also rerun. Sustained performance and comfortable
gesture sensitivity still benefit from hands-on phone testing.
