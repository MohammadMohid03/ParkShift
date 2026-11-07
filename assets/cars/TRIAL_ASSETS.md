# User-supplied cars: local development trial

Original files are retained unchanged. Prepared derivatives are for local development; this is not commercial-release clearance. Six source licenses prohibit commercial use. Manufacturer, livery, logo and underlying model rights still require verification for every branded asset.

| Vehicle | Source / author | Embedded license | Prepared triangles |
|---|---|---|---:|
| Shelby GT500 / 2010 | [amogusstrikesback2](https://sketchfab.com/3d-models/2010-ford-shelby-gt500-5ddb4811f5134c28bdd43198c6fc7a6a) | CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/) | 25893 |
| Alfa Spider / 1986 | [OUTPISTON](https://sketchfab.com/3d-models/1986-alfa-romeo-spider-quadrifoglio-verde-f918dd0e74c445b98ab0d2dd3edfa591) | CC-BY-NC-SA-4.0 (http://creativecommons.org/licenses/by-nc-sa/4.0/) | 191750 |
| Alfa 155 Q4 / 1992 | [OUTPISTON](https://sketchfab.com/3d-models/1992-alfa-romeo-155-q4-9be37de2d57d4c93bd472637a42b9db3) | CC-BY-NC-SA-4.0 (http://creativecommons.org/licenses/by-nc-sa/4.0/) | 220225 |
| Shelby Patrol / 2013 | [Ddiaz Design](https://sketchfab.com/3d-models/2013-ford-shelby-gt500-patrol-6cef8f01bd924bac8e28903c8d5e7596) | CC-BY-NC-SA-4.0 (http://creativecommons.org/licenses/by-nc-sa/4.0/) | 84233 |
| McLaren F1 GTR / 1995 | [Kevin Love SketchFab](https://sketchfab.com/3d-models/1995-mclaren-f1-gtr-202ad0309d3f45b69277c85322b580d2) | CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/) | 141499 |
| Porsche GT3 R / 2024 | [Dave Love SketchFab](https://sketchfab.com/3d-models/2024-porsche-992-gt3-r-b76c9b2ae2d548c3869426eac4ab8a19) | CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/) | 475384 |
| Alfa Stradale / 1967 | [Ipatov Kirill](https://sketchfab.com/3d-models/alfa-romeo-stradale-1967-fbb6adc7a6e84c3db6969e1debcd364b) | CC-BY-NC-4.0 (http://creativecommons.org/licenses/by-nc/4.0/) | 414570 |
| Mustang GT3 | [VTX](https://sketchfab.com/3d-models/ford-mustang-gt3-78c40bf430c94e588136b1412247bcbb) | CC-BY-NC-SA-4.0 (http://creativecommons.org/licenses/by-nc-sa/4.0/) | 375545 |
| McLaren F1 / 1993 | [ᗩᒪE᙭. Kᗩ.🚗](https://sketchfab.com/3d-models/mclaren-f1-1993-by-alexka-294df724d96241cdbe0e0f3c91ad7fce) | CC-BY-NC-4.0 (http://creativecommons.org/licenses/by-nc/4.0/) | 78385 |

## Derivative changes

PARKSHIFT preparation flattens node transforms, rotates the forward axis to -Z, uniformly scales to campaign-compatible dimensions, separates four wheel groups with independent pivots, merges compatible mesh surfaces, limits textures to 1024 pixels, and maps rear lamps to brake feedback. Source paint, texture UVs, glass and PBR material values are preserved where supported. Source preview floors, blurred duplicate wheels and nonphysical glow meshes are omitted when identified. No original asset is overwritten.

Godot converts Stradale specular/glossiness materials to metallic/roughness approximately. Incompatible secondary-UV normal/metallic maps in the GTR and Mustang are omitted; per-car metadata records exactly which ones. No polygon decimation was performed: dense race cars still require device profiling and potentially dedicated mobile LODs.

Attribution metadata, modifications, source links and licenses are retained in each prepared GLB and JSON. Noncommercial/share-alike restrictions continue to apply to derivatives. Do not distribute a commercial build with these trial assets without resolving the rights.
