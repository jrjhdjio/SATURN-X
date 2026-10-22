# AURORA changelog

## 2.0.0 — ULTRA OCEAN

Visual tuning informed by the user's daytime, sunset and midnight screenshots of the previous build. These are configuration changes; their actual rendered result still requires an in-game comparison.

- Increased outdoor midtone contrast and saturation, lowered highlight gain, and reduced the daytime sky/horizon brightness and scattering coefficients to target the washed-out daylight appearance. Existing biome fog and render-distance fade remain intact.
- Strengthened golden/peach sunlight near the horizon with pink/lilac twilight; slightly warmer midday directional light.
- Increased outdoor moon peak illuminance from 0.4 to 0.6 and outdoor ambient floor from approximately 0.028 to 0.042. Lifted shadow gamma from 2.23 to 2.30 with a restrained blue tint. Native cave, Nether and End grading stays as in v1.
- Authored wider ocean/deep-ocean swells by lowering wave frequency and increasing wave depth; reduced fine ripple sharpness and caustics intensity to target noisy water highlights.
- Three presets: ULTRA OCEAN (16 wave octaves), BALANCED (8 octaves and reduced depth), CALM (waves disabled). All share the same lighting and color design. Ultra is the default; saved previous selections may need changing in-game.
- Kept stable pack/module UUIDs, bumped both versions to 2.0.0, and retained the 1.21.120 minimum.
- No extra block textures, PBR maps, custom entities, gameplay scripts, or experimental-only features added. No claim of faster FPS. Waves remain image-based and do not displace water geometry.

## 1.0.0

Initial release: 87 client biome bindings, six outdoor looks, seven water styles, two wave presets, and a self-contained importable `.mcpack`.
