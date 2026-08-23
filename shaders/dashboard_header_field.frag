#include <flutter/runtime_effect.glsl>

// Retained, full-surface Color Lab field.  This is intentionally a fragment
// program rather than a ui.Vertices colour mesh: every visible fragment runs
// the source-style field and touch displacement math.
uniform vec2 uSize;
uniform float uElapsed;
uniform float uPhase;
uniform float uEffect;
uniform float uOpacity;
uniform float uPaletteSplit;
uniform float uPulse;
uniform float uRenderQuality;
uniform vec4 uGradient0;
uniform vec4 uGradient1;
uniform vec4 uGradient2;
uniform vec4 uGradient3;
uniform vec4 uGradient4;
uniform vec4 uGradient5;
uniform vec4 uGradient6;
uniform vec4 uGradient7;
uniform vec4 uGradient8;
uniform vec4 uGradient9;
uniform vec4 uGradientStops0;
uniform vec4 uGradientStops1;
uniform vec4 uGradientStops2;
uniform vec4 uMain0;
uniform vec4 uMain1;
uniform vec4 uMain2;
uniform vec4 uMain3;
uniform vec4 uMain4;
uniform vec4 uMain5;
uniform vec4 uMain6;
uniform vec4 uMain7;
uniform vec4 uMain8;
uniform vec4 uMain9;

// Deep Drift: 3 retained depth transforms and 3 × 5 compact blob transforms.
// Each blob is center.xy + inverseRadius.xy. Values are prepared with bounded
// O(15) CPU scalar work; the density field itself remains per-fragment.
uniform vec4 uDeepBlob0;
uniform vec4 uDeepBlob1;
uniform vec4 uDeepBlob2;
uniform vec4 uDeepBlob3;
uniform vec4 uDeepBlob4;
uniform vec4 uDeepBlob5;
uniform vec4 uDeepBlob6;
uniform vec4 uDeepBlob7;
uniform vec4 uDeepBlob8;
uniform vec4 uDeepBlob9;
uniform vec4 uDeepBlob10;
uniform vec4 uDeepBlob11;
uniform vec4 uDeepBlob12;
uniform vec4 uDeepBlob13;
uniform vec4 uDeepBlob14;
// layer = directional flow X/Y, coherent breathing, depth offset.
uniform vec4 uDeepLayer0;
uniform vec4 uDeepLayer1;
uniform vec4 uDeepLayer2;

uniform float uBackgroundEnabled;
uniform float uBackgroundEffect;
uniform float uBackgroundPhase;
uniform float uBackgroundCenter;
uniform float uBackgroundWindow;
uniform float uBackgroundRotationEnabled;
uniform float uBackgroundRotationSpeed;
uniform vec4 uBackground0;
uniform vec4 uBackground1;
uniform vec4 uBackground2;

uniform float uInteriorEnabled;
uniform float uInteriorEffect;
uniform float uInteriorPhase;
uniform float uInteriorCenter;
uniform float uInteriorWindow;
uniform float uInteriorRotationEnabled;
uniform float uInteriorRotationSpeed;
uniform vec4 uInterior0;
uniform vec4 uInterior1;
uniform vec4 uInterior2;

uniform float uRippleCount;
uniform float uRippleRadiusTravel;
uniform float uRippleIntensity;
uniform float uTapPulseLight;
uniform vec4 uRipple0;
uniform vec4 uRipple1;
uniform vec4 uRipple2;
uniform vec4 uRipple3;
uniform vec4 uRipple4;
uniform vec4 uRipple5;
uniform vec4 uRipple6;
uniform vec4 uRipple7;
uniform vec4 uRipple8;
uniform vec4 uRipple9;

// The CSS-source pink overlay and pointer trail are analytical, native-size
// fragment fields. Keeping them in this retained program removes the former
// Canvas saveLayer/ImageFilter blur surface from the normal Header path.
uniform float uTouchOverlayActive;
uniform vec2 uTouchOverlayOrigin;
uniform float uTouchOverlayOpacity;
uniform float uTouchOverlayScale;
uniform float uTouchOverlayBlur;
uniform float uTouchInteractionOpacity;
uniform float uTrailCount;
uniform float uTrailSize;
uniform vec4 uTrail0;
uniform vec4 uTrail1;
uniform vec4 uTrail2;
uniform vec4 uTrail3;
uniform vec4 uTrail4;
uniform vec4 uTrail5;
uniform vec4 uTrail6;
uniform vec4 uTrail7;
uniform vec4 uTrail8;
uniform vec4 uTrail9;
uniform vec4 uTrail10;
uniform vec4 uTrail11;
uniform vec4 uTrail12;
uniform vec4 uTrail13;
uniform vec4 uTrail14;
uniform vec4 uTrail15;
uniform vec4 uTrail16;
uniform vec4 uTrail17;
uniform vec4 uTrail18;
uniform vec4 uTrail19;
uniform vec4 uTrail20;
uniform vec4 uTrail21;
uniform vec4 uTrail22;
uniform vec4 uTrail23;
uniform vec4 uTrail24;
uniform vec4 uTrail25;

out vec4 fragColor;

const float PI = 3.1415926535897932384626433832795;

float saturate(float value) { return clamp(value, 0.0, 1.0); }
float fract01(float value) { return value - floor(value); }
float smooth01(float left, float right, float value) {
  float safe = max(0.000001, right - left);
  float t = saturate((value - left) / safe);
  return t * t * (3.0 - 2.0 * t);
}
float gaussian(vec2 delta, vec2 radius) {
  vec2 safe = max(radius, vec2(0.0001));
  return exp(-dot(delta / safe, delta / safe));
}
float portalGaussian(vec2 delta, vec2 radius) {
  vec2 safe = max(radius, vec2(0.0001));
  return exp(-.5 * dot(delta / safe, delta / safe));
}
float fbm3(vec2 value, float seed);
float zeroMeanSine(float value, float waveNumber, float phase) {
  float safe = max(.000001, abs(waveNumber));
  float signedWave = waveNumber < 0.0 ? -safe : safe;
  float mean = (cos(phase) - cos(signedWave + phase)) / signedWave;
  return sin(signedWave * value + phase) - mean;
}
float antisymmetricFbm(float y, float offsetX, float offsetY, float scale, float seed) {
  return fbm3(vec2(y * scale + offsetX, offsetY), seed) -
      fbm3(vec2((1.0 - y) * scale + offsetX, offsetY), seed);
}
float limitDeformation(float raw, float maximum, float base) {
  float safe = max(.001, min(base - .04, .96 - base));
  float normalization = maximum > safe ? safe / max(.000001, maximum) : 1.0;
  return raw * normalization;
}
// Runtime effects do not support unsigned integers. This float-only lattice
// hash preserves the deterministic value-noise structure without relying on
// an unsupported ABI construct that can fail at FragmentProgram load time.
float energyHash(vec2 value, float seed) {
  vec2 cell = floor(value);
  vec3 lattice = fract(vec3(cell.xyx) * .1031 + seed * .0173);
  lattice += dot(lattice, lattice.yzx + 33.33);
  return fract((lattice.x + lattice.y) * lattice.z);
}
float valueNoise(vec2 value, float seed) {
  vec2 cell = floor(value);
  vec2 fraction = fract(value);
  vec2 eased = fraction * fraction * (3.0 - 2.0 * fraction);
  float top = mix(energyHash(cell, seed), energyHash(cell + vec2(1.0, 0.0), seed), eased.x);
  float bottom = mix(energyHash(cell + vec2(0.0, 1.0), seed), energyHash(cell + vec2(1.0), seed), eased.x);
  return mix(top, bottom, eased.y);
}
// Portal source modules deliberately use a separate floating sin-hash. Keep
// that source channel distinct from MindPortalEnergy's integer lattice.
float portalHash2(vec2 value, float seed) {
  return fract(sin(dot(value, vec2(127.1, 311.7)) + seed * .0173) * 43758.5453123);
}
float portalValueNoise(vec2 value, float seed) {
  vec2 cell = floor(value);
  vec2 fraction = fract(value);
  vec2 eased = fraction * fraction * (3.0 - 2.0 * fraction);
  float top = mix(portalHash2(cell, seed), portalHash2(cell + vec2(1.0, 0.0), seed), eased.x);
  float bottom = mix(portalHash2(cell + vec2(0.0, 1.0), seed), portalHash2(cell + vec2(1.0), seed), eased.x);
  return mix(top, bottom, eased.y);
}
float fbm3(vec2 value, float seed) {
  float sum = 0.0;
  float amplitude = .58;
  float normalizer = 0.0;
  float frequency = 1.0;
  for (int octave = 0; octave < 3; octave++) {
    sum += valueNoise(value * frequency, seed + float(octave) * 17.3) * amplitude;
    normalizer += amplitude;
    frequency *= 1.93;
    amplitude *= .46;
  }
  return sum / normalizer;
}
float portalFbm(vec2 value, float seed, int octaves) {
  float sum = 0.0;
  float amplitude = .5;
  float weight = 0.0;
  float frequency = 1.0;
  for (int octave = 0; octave < 3; octave++) {
    if (octave >= octaves) break;
    sum += portalValueNoise(value * frequency, seed + float(octave) * 97.0) * amplitude;
    weight += amplitude;
    frequency *= 2.03;
    amplitude *= .5;
  }
  return weight == 0.0 ? 0.0 : sum / weight;
}

float mainValue(int index) {
  // SkSL runtime effects require every vector index to be compile-time
  // constant. This explicit bank keeps the existing packed ABI while avoiding
  // a dynamic-index FragmentProgram load failure.
  if (index == 0) return uMain0.x;
  if (index == 1) return uMain0.y;
  if (index == 2) return uMain0.z;
  if (index == 3) return uMain0.w;
  if (index == 4) return uMain1.x;
  if (index == 5) return uMain1.y;
  if (index == 6) return uMain1.z;
  if (index == 7) return uMain1.w;
  if (index == 8) return uMain2.x;
  if (index == 9) return uMain2.y;
  if (index == 10) return uMain2.z;
  if (index == 11) return uMain2.w;
  if (index == 12) return uMain3.x;
  if (index == 13) return uMain3.y;
  if (index == 14) return uMain3.z;
  if (index == 15) return uMain3.w;
  if (index == 16) return uMain4.x;
  if (index == 17) return uMain4.y;
  if (index == 18) return uMain4.z;
  if (index == 19) return uMain4.w;
  if (index == 20) return uMain5.x;
  if (index == 21) return uMain5.y;
  if (index == 22) return uMain5.z;
  if (index == 23) return uMain5.w;
  if (index == 24) return uMain6.x;
  if (index == 25) return uMain6.y;
  if (index == 26) return uMain6.z;
  if (index == 27) return uMain6.w;
  if (index == 28) return uMain7.x;
  if (index == 29) return uMain7.y;
  if (index == 30) return uMain7.z;
  if (index == 31) return uMain7.w;
  if (index == 32) return uMain8.x;
  if (index == 33) return uMain8.y;
  if (index == 34) return uMain8.z;
  if (index == 35) return uMain8.w;
  if (index == 36) return uMain9.x;
  if (index == 37) return uMain9.y;
  if (index == 38) return uMain9.z;
  return uMain9.w;
}

vec4 deepBlobAt(int index) {
  if (index == 0) return uDeepBlob0;
  if (index == 1) return uDeepBlob1;
  if (index == 2) return uDeepBlob2;
  if (index == 3) return uDeepBlob3;
  if (index == 4) return uDeepBlob4;
  if (index == 5) return uDeepBlob5;
  if (index == 6) return uDeepBlob6;
  if (index == 7) return uDeepBlob7;
  if (index == 8) return uDeepBlob8;
  if (index == 9) return uDeepBlob9;
  if (index == 10) return uDeepBlob10;
  if (index == 11) return uDeepBlob11;
  if (index == 12) return uDeepBlob12;
  if (index == 13) return uDeepBlob13;
  return uDeepBlob14;
}

vec4 deepLayerAt(int index) {
  if (index == 0) return uDeepLayer0;
  if (index == 1) return uDeepLayer1;
  return uDeepLayer2;
}

float deepBlobWeight(int index) {
  if (index == 0) return .94;
  if (index == 1) return 1.08;
  if (index == 2) return .86;
  if (index == 3) return 1.02;
  return .91;
}

vec3 cellularSeedAt(int index) {
  if (index == 0) return vec3(.13, .18, .1);
  if (index == 1) return vec3(.34, .76, 1.7);
  if (index == 2) return vec3(.52, .32, 3.1);
  if (index == 3) return vec3(.72, .80, 4.8);
  if (index == 4) return vec3(.88, .24, 6.4);
  if (index == 5) return vec3(.22, .51, 8.2);
  return vec3(.66, .52, 10.3);
}

vec3 balanceChargeSeedAt(int index) {
  if (index == 0) return vec3(.16, .18, .7);
  if (index == 1) return vec3(.34, .72, 1.9);
  if (index == 2) return vec3(.56, .36, 3.2);
  if (index == 3) return vec3(.78, .81, 4.6);
  if (index == 4) return vec3(.88, .22, 6.1);
  if (index == 5) return vec3(.44, .54, 7.8);
  if (index == 6) return vec3(.24, .88, 9.4);
  return vec3(.68, .10, 11.2);
}

vec4 rippleAt(int index) {
  if (index == 0) return uRipple0;
  if (index == 1) return uRipple1;
  if (index == 2) return uRipple2;
  if (index == 3) return uRipple3;
  if (index == 4) return uRipple4;
  if (index == 5) return uRipple5;
  if (index == 6) return uRipple6;
  if (index == 7) return uRipple7;
  if (index == 8) return uRipple8;
  return uRipple9;
}

vec4 trailAt(int index) {
  if (index == 0) return uTrail0;
  if (index == 1) return uTrail1;
  if (index == 2) return uTrail2;
  if (index == 3) return uTrail3;
  if (index == 4) return uTrail4;
  if (index == 5) return uTrail5;
  if (index == 6) return uTrail6;
  if (index == 7) return uTrail7;
  if (index == 8) return uTrail8;
  if (index == 9) return uTrail9;
  if (index == 10) return uTrail10;
  if (index == 11) return uTrail11;
  if (index == 12) return uTrail12;
  if (index == 13) return uTrail13;
  if (index == 14) return uTrail14;
  if (index == 15) return uTrail15;
  if (index == 16) return uTrail16;
  if (index == 17) return uTrail17;
  if (index == 18) return uTrail18;
  if (index == 19) return uTrail19;
  if (index == 20) return uTrail20;
  if (index == 21) return uTrail21;
  if (index == 22) return uTrail22;
  if (index == 23) return uTrail23;
  if (index == 24) return uTrail24;
  return uTrail25;
}

vec3 applyMaterialOptics(vec3 color, float light, float chroma) {
  float gray = (color.r + color.g + color.b) / 3.0;
  color = mix(vec3(gray), color, 1.0 + chroma);
  return clamp(color * (1.0 + light), 0.0, 1.0);
}

// The first two scalars in the third packed stop vector stay reserved by the
// fixed v3 ABI. Its third scalar carries the active count. The real Budget
// Header input is the Color Lab A/M/B probe window, so its live material field
// has exactly two or three knots; keeping the extended ten-slot branch out of
// this program prevents swangle from compiling an unused interval cascade for
// every animated fragment.
float canonicalActiveStopCount() {
  return clamp(floor(uGradientStops2.z + .5), 2.0, 3.0);
}
vec3 sampleCanonicalSegment(
    vec3 leftColor,
    float leftStop,
    vec3 rightColor,
    float rightStop,
    float coordinate) {
  float amount = saturate(
      (coordinate - leftStop) / max(.000001, rightStop - leftStop));
  return mix(leftColor, rightColor, amount);
}
// The exact 112° CSS source field is a scalar material coordinate. Every
// animated effect transports this coordinate and then samples this one shared
// palette function; effects never receive RGB endpoint authority.
float canonicalGradientCoordinate(vec2 uv) {
  // Audited historical static Budget geometry: CSS linear-gradient(112deg).
  // CSS angles use up=0°/right=90°; Flutter fragment coordinates use down Y.
  const vec2 direction = vec2(.9271838546, .3746065934);
  float lineLength = abs(direction.x) * uSize.x + abs(direction.y) * uSize.y;
  vec2 start = uSize * .5 - direction * lineLength * .5;
  return saturate(dot(uv * uSize - start, direction) / lineLength);
}

// The dynamic CSS-axis helper is deliberately separate from the literal
// audited 112° helper above. Disabled Full Field orientation calls the
// existing function directly, preserving b2ec151 pixel output exactly.
float canonicalGradientCoordinateAtAngle(vec2 uv, float degrees) {
  if (abs(degrees - 112.0) < .0001) {
    return canonicalGradientCoordinate(uv);
  }
  float radians = degrees * PI / 180.0;
  // CSS angles use up=0°/right=90° while Flutter fragment Y grows downward.
  vec2 direction = vec2(sin(radians), -cos(radians));
  float lineLength = abs(direction.x) * uSize.x + abs(direction.y) * uSize.y;
  vec2 start = uSize * .5 - direction * lineLength * .5;
  return saturate(dot(uv * uSize - start, direction) / lineLength);
}

vec3 sampleCanonicalPalette(float coordinate) {
  coordinate = saturate(coordinate);
  float activeStopCount = canonicalActiveStopCount();
  if (activeStopCount < 2.5) {
    return sampleCanonicalSegment(
        uGradient0.rgb, uGradientStops0.x,
        uGradient1.rgb, uGradientStops0.y,
        coordinate);
  }
  if (coordinate <= uGradientStops0.y) {
    return sampleCanonicalSegment(
        uGradient0.rgb, uGradientStops0.x,
        uGradient1.rgb, uGradientStops0.y,
        coordinate);
  }
  return sampleCanonicalSegment(
      uGradient1.rgb, uGradientStops0.y,
      uGradient2.rgb, uGradientStops0.z,
      coordinate);
}

vec3 canonicalGradient(vec2 uv) {
  return sampleCanonicalPalette(canonicalGradientCoordinate(uv));
}

// Exact pre-seamless palette-coordinate tail retained solely for the
// 69d109c1e1f53ab4c0d2b66f5c576577de3e99c9 comparison lane. It is never used
// by the full-field family and does not restore endpoint RGB authority.
float classicTransportPaletteCoordinate(float baseCoordinate, float displacement) {
  float boundedBase = saturate(baseCoordinate);
  float edgeEnvelope = 4.0 * boundedBase * (1.0 - boundedBase);
  return saturate(boundedBase + displacement * edgeEnvelope);
}

// Animated effects transport Header space, not palette territories.  The
// envelope smoothly takes material velocity to zero at the rectangular bounds,
// avoiding a clipped source-UV border without wrapping or mirroring U.
float materialBoundaryEnvelope(vec2 uv) {
  vec2 edge = min(uv, vec2(1.0) - uv);
  return smooth01(0.0, .115, edge.x) * smooth01(0.0, .115, edge.y);
}

vec2 boundedMaterialSourceUv(vec2 uv, vec2 displacement) {
  return uv + displacement * materialBoundaryEnvelope(uv);
}

float softBoundedMaterialDelta(float delta, float limit) {
  // This rational bound is continuous, odd, and cheap on the fragment path.
  // It has no hard coordinate clip or repeated/folded palette domain.
  return delta / (1.0 + abs(delta) / max(.000001, limit));
}

float distributionSafePaletteCoordinate(
    float baseCoordinate,
    float candidateCoordinate,
    float strength) {
  float boundedBase = saturate(baseCoordinate);
  float safeStrength = saturate(strength);
  // Normal settings live at the .16 domain bound; deliberately maximum
  // strength can approach, but not exceed, the .28 material-advection bound.
  float strongExtension = smooth01(.82, 1.0, safeStrength);
  float displacementLimit = mix(.16, .28, strongExtension);
  float delta = softBoundedMaterialDelta(
      candidateCoordinate - boundedBase, displacementLimit);
  // Palette-domain edges progressively resist outward movement. The final
  // saturate is a numerical guard, not the visual shaping mechanism.
  float domainEnvelope = mix(.22, 1.0, 4.0 * boundedBase * (1.0 - boundedBase));
  return saturate(boundedBase + delta * safeStrength * domainEnvelope);
}

vec2 displaceRipples(vec2 uv, out float pulseLight) {
  vec2 result = uv;
  pulseLight = 0.0;
  for (int index = 0; index < 10; index++) {
    if (float(index) >= uRippleCount) break;
    vec4 ripple = rippleAt(index);
    if (ripple.w <= 0.0 || ripple.z < 0.0 || ripple.z >= 1.0) continue;
    vec2 delta = result - ripple.xy;
    float distanceToOrigin = length(delta);
    if (distanceToOrigin < .000001) continue;
    float ring = sin(distanceToOrigin * 10.5 - ripple.z * PI * 2.2) *
        exp(-abs(distanceToOrigin - ripple.z * uRippleRadiusTravel) * 7.2) *
        (1.0 - ripple.z) * .32 * uRippleIntensity;
    result.x += delta.x / distanceToOrigin * ring * .018;
    result.y += delta.y / distanceToOrigin * ring * .014;
    pulseLight = max(pulseLight, max(0.0, 1.0 - ripple.z));
  }
  return clamp(result, vec2(0.0), vec2(1.0));
}

// A depth-local advection moves the entire material field coherently.  The
// retained Dart skeleton supplies layer.xy; no per-blob animation is needed.
vec2 advectDeepDriftLayer(vec2 uv, vec4 layer, float apparentDepth) {
  vec2 flow = layer.xy * (1.0 - apparentDepth * .18);
  vec2 centered = uv - vec2(.5);
  // A tiny static depth shear retains only a secondary rotational cue. It is
  // intentionally much weaker than the old full-field layer rotation.
  centered += vec2(-centered.y, centered.x) * (.010 + apparentDepth * .012);
  return clamp(centered + vec2(.5) + flow, vec2(0.0), vec2(1.0));
}

// Low-frequency carrier material joins nearby compact blobs before alpha/tone
// composition. It is subordinate to the metaball density and never enters the
// analytic lighting gradient, so it cannot turn the material into smoke.
float continuousCarrierDensity(
    vec2 point,
    vec4 layer,
    int layerIndex,
    float noiseScale,
    float densityControl,
    float softness) {
  float scale = max(.20, noiseScale * .82);
  float carrierNoise = valueNoise(
      point * scale + layer.xy * 8.0 + vec2(float(layerIndex) * .37, float(layerIndex) * .19),
      913.0 + float(layerIndex) * 71.0);
  float coverage = smooth01(.26, .74, carrierNoise);
  return coverage * (.075 + .075 * densityControl + .040 * softness);
}

// Fluvi-native pseudo-volumetric material. The layer sequence is intentionally
// near → middle → far: later layers contribute through front transmittance.
// Geometry layers first contribute density and optical depth; exactly one
// continuous palette-material coordinate is derived only after accumulation. The
// five-blob inner loop contains no sqrt/exp/trigonometric animation.
vec3 deepDriftField(vec2 uv, float rippleLight) {
  float strength = mainValue(0);
  float densityControl = mainValue(4);
  float softness = mainValue(5);
  float noiseAmount = mainValue(6);
  float noiseScale = max(.01, mainValue(7));
  float depthColorSeparation = mainValue(9);
  float lighting = mainValue(11);
  float coreGlow = mainValue(12);
  float nearOpacity = mainValue(15);
  float middleOpacity = mainValue(16);
  float farOpacity = mainValue(17);
  float baseCoordinate = canonicalGradientCoordinate(uv);
  vec3 base = applyMaterialOptics(
      sampleCanonicalPalette(baseCoordinate),
      uPulse * .025 + rippleLight * uTapPulseLight,
      0.0);
  float transmittance = 1.0;
  float totalDensity = 0.0;
  float weightedDepthNumerator = 0.0;
  float weightedLighting = 0.0;
  float weightedCore = 0.0;
  float weightedVariation = 0.0;
  vec2 weightedFlow = vec2(0.0);
  float aspect = uSize.x / max(1.0, uSize.y);

  for (int layerIndex = 0; layerIndex < 3; layerIndex++) {
    vec4 layer = deepLayerAt(layerIndex);
    float apparentDepth = saturate(layer.w);
    vec2 advected = advectDeepDriftLayer(uv, layer, apparentDepth);
    vec2 centered = advected - vec2(.5);
    // Farther material occupies a broader, calmer projection. This is the
    // live depth-separation control prepared by the retained layer skeleton.
    centered *= 1.0 + (apparentDepth - .5) * .22;
    centered.x *= aspect;
    centered.x /= aspect;
    vec2 point = centered + vec2(.5);
    float rawDensity = 0.0;
    vec2 gradient = vec2(0.0);
    int blobOffset = layerIndex * 5;
    for (int blobIndex = 0; blobIndex < 5; blobIndex++) {
      vec4 blob = deepBlobAt(blobOffset + blobIndex);
      vec2 q = (point - blob.xy) * blob.zw;
      float r2 = dot(q, q);
      float h = max(0.0, 1.0 - r2);
      float value = h * h * (3.0 - 2.0 * h);
      float derivative = -6.0 * h * (1.0 - h);
      float weight = deepBlobWeight(blobIndex);
      rawDensity += value * weight;
      gradient += derivative * 2.0 * q * blob.zw * weight;
    }

    // A single weak low-frequency modulation changes only density.  The
    // carrier supplies continuous overlap between the compact forms instead
    // of creating a separate, high-frequency/noisy shape system.
    float noise = (valueNoise(point * max(.20, noiseScale) + layer.xy * 6.0,
        1007.0 + float(layerIndex) * 37.0) - .5) * 2.0;
    float carrier = continuousCarrierDensity(
        point, layer, layerIndex, noiseScale, densityControl, softness);
    float materialDensity = rawDensity * densityControl *
        (1.0 + noise * noiseAmount) + carrier;
    float edgeStart = .035 + (1.0 - softness) * .13;
    float edgeEnd = .78 + softness * .58;
    float fieldAlpha = smooth01(edgeStart, edgeEnd, materialDensity);
    float layerOpacity = layerIndex == 0 ? nearOpacity :
        (layerIndex == 1 ? middleOpacity : farOpacity);
    float alpha = saturate(fieldAlpha * layerOpacity * strength *
        (1.0 + layer.z * .75 + (.5 - apparentDepth) * .08));
    vec3 normal = normalize(vec3(gradient * 2.25, .86));
    vec3 lightDirection = normalize(vec3(-.32, -.18, .93));
    // Optical light is a continuous apparent-Z response: near material gets
    // most of it, middle less, far only a faint trace — no stepped colours.
    float layerLight = mix(.05, 1.0, pow(1.0 - apparentDepth, 1.15));
    float formLight = (dot(normal, lightDirection) - .42) * lighting * layerLight;
    float core = smooth01(.92, 1.68, rawDensity);
    totalDensity += materialDensity * alpha;
    weightedDepthNumerator += alpha * apparentDepth;
    weightedLighting += alpha * formLight;
    weightedCore += alpha * core;
    weightedVariation += alpha * (noise * .55 + (carrier * 2.0 - .10));
    weightedFlow += alpha * layer.xy;
    transmittance *= 1.0 - alpha;
  }
  if (totalDensity <= .000001) return base;
  float weightedDepth = weightedDepthNumerator / max(.000001, 1.0 - transmittance);
  float densityTone = smooth01(.08, 1.45, totalDensity) - .5;
  vec2 materialFlow = weightedFlow / max(.000001, 1.0 - transmittance);
  vec2 materialWarp = materialFlow * .16 + vec2(
      (weightedDepth - .5) * depthColorSeparation * .045,
      densityTone * .025 +
          weightedVariation / max(.000001, 1.0 - transmittance) * .018);
  float warpedCoordinate = canonicalGradientCoordinate(
      clamp(uv + materialWarp, vec2(0.0), vec2(1.0)));
  float materialCoordinate = classicTransportPaletteCoordinate(
      baseCoordinate, warpedCoordinate - baseCoordinate);
  vec3 continuousMaterialColor = sampleCanonicalPalette(materialCoordinate);
  float materialLight = weightedLighting / max(.000001, 1.0 - transmittance);
  float materialCore = weightedCore / max(.000001, 1.0 - transmittance);
  continuousMaterialColor *= 1.0 + materialLight + materialCore * coreGlow;
  float compositeAlpha = 1.0 - transmittance;
  return clamp(continuousMaterialColor * compositeAlpha +
      transmittance * base, 0.0, 1.0);
}

// The exact 69d109 classic comparison lane intentionally preserves the old
// separator/lens/shape mathematics while retaining the current canonical v3
// palette infrastructure. It is not the architecture used by IDs 9–13.
vec3 classicReferenceField(vec2 uv, float rippleLight) {
  if (uEffect < .5) return applyMaterialOptics(
      canonicalGradient(uv), uPulse * .025 + rippleLight * uTapPulseLight, 0.0);
  if (uEffect < 8.5 && uEffect > 7.5) return deepDriftField(uv, rippleLight);
  float strength = mainValue(0);
  float baseCoordinate = canonicalGradientCoordinate(uv);
  float bias = mainValue(2);
  float ratioSwing = mainValue(3);
  float ratioSpeed = mainValue(4);
  float fieldScale = max(.01, mainValue(5));
  float morphAmount = mainValue(6);
  float morphSpeed = mainValue(7);
  float softness = max(.001, mainValue(8));
  float detail = mainValue(9);
  float pulseAmount = mainValue(10);
  float pulseSpeed = mainValue(11);
  float lightAmount = mainValue(12);
  vec2 p = vec2(.5) + (uv - vec2(.5)) * fieldScale;
  float ratio = bias + sin(uPhase * ratioSpeed * PI * 2.0) * ratioSwing;
  float morphTime = uPhase * morphSpeed;
  float broad = (fbm3(p * vec2(1.17, 1.09) +
      vec2(morphTime * .07, -morphTime * .05), 31.7) - .5) * morphAmount;
  float fine = (fbm3(p * vec2(2.8, 2.5) +
      vec2(-morphTime * .09, morphTime * .08), 67.3) - .5) * detail *
      mix(.45, 1.0, uRenderQuality);
  float field = p.x + ratio + broad * .20 + fine * .12;
  float localLight = 0.0;
  if (uEffect < 1.5) {
    float offset = mainValue(23) * PI / 180.0;
    float aPhase = uPhase * .52;
    float bPhase = uPhase * .47 + offset;
    float aX = .5 - mainValue(18) * .5 + sin(aPhase * .83) * mainValue(15) +
        (.5 + .5 * sin(aPhase * .31)) * mainValue(17);
    float bX = .5 + mainValue(18) * .5 - sin(bPhase * .79) * mainValue(15) -
        (.5 + .5 * sin(bPhase * .29)) * mainValue(17);
    float aY = .5 + sin(aPhase * .61) * mainValue(16);
    float bY = .5 - sin(bPhase * .57) * mainValue(16);
    float aMass = gaussian(p - vec2(aX, aY), vec2(mainValue(19), mainValue(19) / max(.01, mainValue(21))));
    float bMass = gaussian(p - vec2(bX, bY), vec2(mainValue(20), mainValue(20) / max(.01, mainValue(22))));
    float warp = (fbm3(p * mainValue(26) + vec2(uPhase * mainValue(27) * .11, -uPhase * mainValue(27) * .09), 103.2) - .5) * mainValue(25);
    field += warp + (bMass - aMass) * mainValue(24) * .46;
    localLight = (aMass + bMass - .7) * lightAmount * .12;
  } else if (uEffect < 2.5) {
    float spread = mainValue(19) * PI / 180.0;
    float nodeTop = mainValue(15) + sin(uPhase * .23) * mainValue(18);
    float nodeMiddle = mainValue(16) + sin(uPhase * .23 + spread) * mainValue(18);
    float nodeBottom = mainValue(17) + sin(uPhase * .23 + spread * 2.0) * mainValue(18);
    float iy = saturate(p.y);
    float nodeCurve = (1.0 - iy) * (1.0 - iy) * nodeTop + 2.0 * (1.0 - iy) * iy * nodeMiddle + iy * iy * nodeBottom;
    float primary = sin(p.y / mainValue(21) * PI * 2.0 + uPhase * mainValue(22) * PI * 2.0) * mainValue(20);
    float secondary = sin(p.y / mainValue(24) * PI * 2.0 - uPhase * mainValue(25) * PI * 2.0 + 1.7) * mainValue(23);
    float warp = (fbm3(vec2(p.y * 1.4 + uPhase * mainValue(29) * .08, p.x * .9 - uPhase * mainValue(29) * .05), 211.6) - .5) * mainValue(28);
    float boundary = .5 + ratio + nodeCurve * (1.0 - mainValue(27) * .68) + primary + secondary + mainValue(26) * (p.y - .5) + warp + broad * .18 + fine * .10;
    field = .5 + (p.x - boundary);
    localLight = abs(primary + secondary) * lightAmount * .16;
  } else if (uEffect < 3.5) {
    float breathPhase = uPhase * mainValue(23) * PI * 2.0;
    float centerX = mainValue(15) + sin(uPhase * .31) * mainValue(17);
    float centerY = mainValue(16) + cos(uPhase * .27) * mainValue(18);
    float radiusX = max(.03, mainValue(19) * (1.0 + sin(breathPhase) * mainValue(21)));
    float radiusY = max(.03, mainValue(20) * (1.0 + cos(breathPhase * .83) * mainValue(22)));
    vec2 delta = (p - vec2(centerX, centerY)) / vec2(radiusX, radiusY);
    float lens = exp(-dot(delta, delta) / max(.01, mainValue(26)));
    float satelliteAngle = mainValue(30) * PI / 180.0;
    vec2 satelliteCenter = vec2(centerX, centerY) + vec2(cos(satelliteAngle + uPhase * .13), sin(satelliteAngle + uPhase * .11)) * mainValue(29);
    float satellite = gaussian(p - satelliteCenter, vec2(mainValue(28)));
    float pressure = (lens * mainValue(24) + satellite * mainValue(27)) * mainValue(25);
    field += pressure + broad * .19 + fine * .10;
    localLight = (lens + satellite) * lightAmount * .12;
  } else if (uEffect < 4.5) {
    float count = clamp(mainValue(15), 3.0, 7.0);
    float pressureSum = 0.0;
    float lightSum = 0.0;
    for (int index = 0; index < 7; index++) {
      if (float(index) >= count) break;
      vec3 seed = cellularSeedAt(index);
      float curl = (fbm3(seed.xy * mainValue(21) + vec2(uPhase * .04, -uPhase * .03), seed.z + 301.0) - .5) * mainValue(20);
      vec2 center = fract(seed.xy + vec2(uPhase * mainValue(18) * .025, uPhase * mainValue(19) * .025) +
          vec2(sin(uPhase * .19 + seed.z), cos(uPhase * .17 + seed.z)) * mainValue(24) + vec2(curl, -curl));
      float variation = 1.0 + ((float(index) / max(1.0, count - 1.0)) - .5) * mainValue(17);
      float radius = max(.04, mainValue(16) * variation * (1.0 + sin(uPhase * .21 + seed.z) * mainValue(25) * .35));
      float cell = gaussian(p - center, vec2(radius, radius * (.84 + mod(float(index), 3.0) * .11)));
      float polarity = mod(float(index), 2.0) < .5 ? -1.0 : 1.0;
      pressureSum += cell * (polarity + mainValue(23));
      lightSum += cell;
    }
    float noise = (fbm3(p * mainValue(26) + vec2(uPhase * mainValue(28) * .07, -uPhase * mainValue(28) * .06), 409.4) - .5) * mainValue(27);
    field += mainValue(22) + pressureSum / count * mainValue(29) + noise + broad * .18 + fine * .10;
    localLight = lightSum / count * lightAmount * .16;
  } else {
    float base = .08 + saturate(uPaletteSplit) * .84;
    float boundary = base;
    float rawLight = 0.0;
    float rawChroma = 0.0;
    if (uEffect < 5.5) {
      float drift = uPhase * mainValue(14) * PI * 2.0;
      float primary = zeroMeanSine(p.y, PI * 2.0 / mainValue(10), drift);
      float secondary = zeroMeanSine(p.y, PI * 2.0 / mainValue(12), -(drift * .71) + mainValue(13) * PI / 180.0);
      float warp = antisymmetricFbm(p.y, uPhase * mainValue(18) * .08, uPhase * mainValue(18) * .06 + .37, mainValue(17), 701.3) * mainValue(16);
      float damping = 1.0 - mainValue(15) * .72;
      float raw = (primary * mainValue(9) + secondary * mainValue(11) + warp) * damping;
      float maximum = 2.0 * (mainValue(9) + mainValue(11) + mainValue(16)) * damping;
      boundary = base + limitDeformation(raw, maximum, base);
      rawLight = abs(primary * .68 + secondary * .32);
      rawChroma = warp;
    } else if (uEffect < 6.5) {
      float drift = uPhase * mainValue(14) * PI * 2.0;
      float wave = mainValue(10) * PI * 2.0;
      float a = zeroMeanSine(p.y, wave, drift);
      float b = zeroMeanSine(p.y, wave, drift + mainValue(13) * PI / 180.0);
      float paired = a - b * mainValue(15) * mainValue(12);
      float shaped = sign(paired) * pow(abs(paired), mainValue(16));
      float maximumShape = pow(1.0 + mainValue(15) * mainValue(12), mainValue(16));
      float normalized = shaped / max(.000001, maximumShape);
      float gain = mainValue(11) / .22;
      float warp = antisymmetricFbm(p.y, -(uPhase * mainValue(19) * .07), uPhase * mainValue(19) * .05 + .73, mainValue(18), 811.9) * mainValue(17);
      float raw = normalized * mainValue(9) * gain * .5 + warp;
      float maximum = mainValue(9) * gain * .5 + mainValue(17);
      boundary = base + limitDeformation(raw, maximum, base);
      rawLight = abs(paired) / max(1.0, maximumShape) * .72;
      rawChroma = normalized * .55;
    } else {
      float rawSeam = zeroMeanSine(p.y, PI * 2.0 / mainValue(10), uPhase * mainValue(11) * PI * 2.0) * mainValue(9);
      boundary = base + limitDeformation(rawSeam, mainValue(9) * 2.0, base);
      float side = p.x <= boundary ? 0.0 : 1.0;
      float count = clamp(mainValue(12), 2.0, 8.0);
      for (int index = 0; index < 8; index++) {
        if (float(index) >= count || mod(float(index), 2.0) != side) continue;
        vec3 seed = balanceChargeSeedAt(index);
        float start = side == 0.0 ? 0.0 : base;
        float width = side == 0.0 ? base : 1.0 - base;
        vec2 center = vec2(start + width * (.12 + seed.x * .76) + sin(uPhase * .13 + seed.z) * mainValue(15) * width,
            seed.y + cos(uPhase * .11 + seed.z) * mainValue(15));
        float variation = 1.0 + ((float(index) / max(1.0, count - 1.0)) - .5) * mainValue(14);
        float morph = 1.0 + sin(uPhase * .17 + seed.z * mainValue(20)) * mainValue(19) * .35;
        float radius = max(.03, mainValue(13) * variation * morph);
        float charge = gaussian(p - center, vec2(radius, radius * .82));
        float polarity = sin(uPhase * .16 + seed.z + side * mainValue(18) * PI / 180.0);
        rawLight += charge * polarity * mainValue(16);
        rawChroma += charge * polarity * mainValue(17);
      }
    }
    if (strength <= 0.0) return sampleCanonicalPalette(baseCoordinate);
    boundary = clamp(mix(base, boundary, strength), .04, .96);
    float mapped = p.x <= boundary ? base * p.x / max(.000001, boundary) :
        base + (1.0 - base) * (p.x - boundary) / max(.000001, 1.0 - boundary);
    float seam = exp(-abs(p.x - boundary) / max(.01, mainValue(2)));
    float pulse = sin(uPhase * mainValue(6) * PI * 2.0) * mainValue(5) * seam;
    float coordinate = classicTransportPaletteCoordinate(
        baseCoordinate, (mapped - p.x) * strength);
    return applyMaterialOptics(sampleCanonicalPalette(coordinate),
      clamp((rawLight * mainValue(3) + pulse) * strength + uPulse * .025 + rippleLight * uTapPulseLight, -.22, .22),
      clamp(rawChroma * mainValue(4) * strength, -.35, .35));
  }
  float mixture = smooth01(.5 - softness, .5 + softness, field);
  float seam = 4.0 * mixture * (1.0 - mixture);
  float pulse = sin(uPhase * pulseSpeed * PI * 2.0) * pulseAmount;
  float light = clamp((pulse + (broad + fine) * lightAmount + localLight) * seam +
      uPulse * .025 + rippleLight * uTapPulseLight, -.25, .25);
  if (strength <= 0.0) return sampleCanonicalPalette(baseCoordinate);
  float coordinate = classicTransportPaletteCoordinate(
      baseCoordinate, (mixture - p.x) * saturate(strength));
  return applyMaterialOptics(sampleCanonicalPalette(coordinate), light, 0.0);
}

/* Removed in the full-field-flow refactor. This preserved working-tree
 * context is intentionally excluded from the compiled runtime; IDs 0–8 use
 * classicReferenceField and IDs 9–13 use the full-field engine below. */
/*
  if (uEffect < .5) return applyMaterialOptics(
      canonicalGradient(uv), uPulse * .025 + rippleLight * uTapPulseLight, 0.0);
  if (uEffect < 8.5 && uEffect > 7.5) return deepDriftField(uv, rippleLight);

  float strength = mainValue(0);
  float baseCoordinate = canonicalGradientCoordinate(uv);
  if (strength <= 0.0) return sampleCanonicalPalette(baseCoordinate);

  if (uEffect < 4.5) {
    float bias = mainValue(2);
    float ratioSwing = mainValue(3);
    float ratioSpeed = mainValue(4);
    float fieldScale = max(.01, mainValue(5));
    float morphAmount = mainValue(6);
    float morphSpeed = mainValue(7);
    float detail = mainValue(9);
    float pulseAmount = mainValue(10);
    float pulseSpeed = mainValue(11);
    float lightAmount = mainValue(12);
    vec2 p = vec2(.5) + (uv - vec2(.5)) * fieldScale;
    float ratio = bias + sin(uPhase * ratioSpeed * PI * 2.0) * ratioSwing;
    float morphTime = uPhase * morphSpeed;
    float broad = (fbm3(p * vec2(1.17, 1.09) +
        vec2(morphTime * .07, -morphTime * .05), 31.7) - .5) * morphAmount;
    float fine = (fbm3(p * vec2(2.8, 2.5) +
        vec2(-morphTime * .09, morphTime * .08), 67.3) - .5) * detail *
        mix(.45, 1.0, uRenderQuality);
    vec2 flow = vec2(ratio * .18 + broad * .055 + fine * .035,
        -broad * .035 + fine * .025);
    float localOptics = 0.0;

    if (uEffect < 1.5) {
      // Dual Tide: broad opposite lobe advection plus weak tangential flow.
      float offset = mainValue(23) * PI / 180.0;
      float aPhase = uPhase * .52;
      float bPhase = uPhase * .47 + offset;
      vec2 aCenter = vec2(.5 - mainValue(18) * .5 + sin(aPhase * .83) * mainValue(15) +
          (.5 + .5 * sin(aPhase * .31)) * mainValue(17),
          .5 + sin(aPhase * .61) * mainValue(16));
      vec2 bCenter = vec2(.5 + mainValue(18) * .5 - sin(bPhase * .79) * mainValue(15) -
          (.5 + .5 * sin(bPhase * .29)) * mainValue(17),
          .5 - sin(bPhase * .57) * mainValue(16));
      vec2 aDelta = p - aCenter;
      vec2 bDelta = p - bCenter;
      float aMass = gaussian(aDelta, vec2(mainValue(19), mainValue(19) / max(.01, mainValue(21))));
      float bMass = gaussian(bDelta, vec2(mainValue(20), mainValue(20) / max(.01, mainValue(22))));
      float warp = (fbm3(p * mainValue(26) +
          vec2(uPhase * mainValue(27) * .11, -uPhase * mainValue(27) * .09), 103.2) - .5) * mainValue(25);
      vec2 tideCurl = vec2(-aDelta.y, aDelta.x) * aMass -
          vec2(-bDelta.y, bDelta.x) * bMass;
      flow += tideCurl * mainValue(24) * .18 +
          vec2((bMass - aMass) * mainValue(24) * .075, warp * .11);
      localOptics = (aMass + bMass) * lightAmount * .025;
    } else if (uEffect < 2.5) {
      // Magnetic Membrane: a deforming sheet shear, never a colour boundary.
      float spread = mainValue(19) * PI / 180.0;
      float nodeTop = mainValue(15) + sin(uPhase * .23) * mainValue(18);
      float nodeMiddle = mainValue(16) + sin(uPhase * .23 + spread) * mainValue(18);
      float nodeBottom = mainValue(17) + sin(uPhase * .23 + spread * 2.0) * mainValue(18);
      float iy = saturate(p.y);
      float nodeCurve = (1.0 - iy) * (1.0 - iy) * nodeTop +
          2.0 * (1.0 - iy) * iy * nodeMiddle + iy * iy * nodeBottom;
      float primary = sin(p.y / mainValue(21) * PI * 2.0 +
          uPhase * mainValue(22) * PI * 2.0) * mainValue(20);
      float secondary = sin(p.y / mainValue(24) * PI * 2.0 -
          uPhase * mainValue(25) * PI * 2.0 + 1.7) * mainValue(23);
      float warp = (fbm3(vec2(p.y * 1.4 + uPhase * mainValue(29) * .08,
          p.x * .9 - uPhase * mainValue(29) * .05), 211.6) - .5) * mainValue(28);
      float sheetBend = nodeCurve * (1.0 - mainValue(27) * .68) +
          primary + secondary + mainValue(26) * (p.y - .5) + warp;
      float membraneInfluence = gaussian(vec2(p.x - (.5 + sheetBend), 0.0), vec2(.34, 1.0));
      flow += vec2(sheetBend * .12, -(primary + secondary) * membraneInfluence * .075);
      localOptics = (abs(primary + secondary) + membraneInfluence * .35) * lightAmount * .028;
    } else if (uEffect < 3.5) {
      // Breathing Lens: monotonic, bounded radial refraction through source UV.
      float breathPhase = uPhase * mainValue(23) * PI * 2.0;
      vec2 center = vec2(mainValue(15) + sin(uPhase * .31) * mainValue(17),
          mainValue(16) + cos(uPhase * .27) * mainValue(18));
      vec2 radius = vec2(max(.03, mainValue(19) * (1.0 + sin(breathPhase) * mainValue(21))),
          max(.03, mainValue(20) * (1.0 + cos(breathPhase * .83) * mainValue(22))));
      vec2 radial = p - center;
      float lens = exp(-dot(radial / radius, radial / radius) / max(.01, mainValue(26)));
      float satelliteAngle = mainValue(30) * PI / 180.0;
      vec2 satelliteCenter = center + vec2(cos(satelliteAngle + uPhase * .13),
          sin(satelliteAngle + uPhase * .11)) * mainValue(29);
      vec2 satelliteDelta = p - satelliteCenter;
      float satellite = gaussian(satelliteDelta, vec2(mainValue(28)));
      // The radial scale stays positive and small, so concentric source rings
      // cannot pile up into one palette ring.
      flow += radial * lens * mainValue(24) * mainValue(25) * .18 +
          vec2(-satelliteDelta.y, satelliteDelta.x) * satellite * mainValue(27) * .075;
      localOptics = (lens * .42 + satellite * .28) * lightAmount * .035;
    } else {
      // Cellular Field: overlapping local vector pushes/curls, no cell owns U.
      float count = clamp(mainValue(15), 3.0, 7.0);
      float density = 0.0;
      for (int index = 0; index < 7; index++) {
        if (float(index) >= count) break;
        vec3 seed = cellularSeedAt(index);
        float curl = (fbm3(seed.xy * mainValue(21) +
            vec2(uPhase * .04, -uPhase * .03), seed.z + 301.0) - .5) * mainValue(20);
        vec2 center = fract(seed.xy + vec2(uPhase * mainValue(18) * .025,
            uPhase * mainValue(19) * .025) +
            vec2(sin(uPhase * .19 + seed.z), cos(uPhase * .17 + seed.z)) * mainValue(24) +
            vec2(curl, -curl));
        float variation = 1.0 + ((float(index) / max(1.0, count - 1.0)) - .5) * mainValue(17);
        float radius = max(.04, mainValue(16) * variation *
            (1.0 + sin(uPhase * .21 + seed.z) * mainValue(25) * .35));
        vec2 delta = p - center;
        float cell = gaussian(delta, vec2(radius, radius * (.84 + mod(float(index), 3.0) * .11)));
        float orientation = mod(float(index), 2.0) < .5 ? -1.0 : 1.0;
        vec2 vectorPush = vec2(-delta.y, delta.x) * orientation * .14 + delta * .045;
        flow += vectorPush * cell * mainValue(29);
        density += cell;
      }
      float noise = (fbm3(p * mainValue(26) +
          vec2(uPhase * mainValue(28) * .07, -uPhase * mainValue(28) * .06), 409.4) - .5) * mainValue(27);
      flow += vec2(noise, -noise * .55) * .09;
      localOptics = density / count * lightAmount * .025;
    }

    vec2 sourceUv = boundedMaterialSourceUv(uv, flow);
    float candidateCoordinate = canonicalGradientCoordinate(sourceUv);
    float coordinate = distributionSafePaletteCoordinate(
        baseCoordinate, candidateCoordinate, strength);
    float pulse = sin(uPhase * pulseSpeed * PI * 2.0) * pulseAmount * .18;
    float light = clamp((pulse + (broad + fine) * lightAmount * .18 + localOptics) * strength +
        uPulse * .025 + rippleLight * uTapPulseLight, -.12, .12);
    return applyMaterialOptics(sampleCanonicalPalette(coordinate), light, 0.0);
  }

  // Balance effects retain their moving geometric characters, but every side
  // now advects the same material. No piecewise boundary mapping reaches U.
  float base = .08 + saturate(uPaletteSplit) * .84;
  float boundary = base;
  float rawLight = 0.0;
  float rawChroma = 0.0;
  vec2 flow = vec2(0.0);
  if (uEffect < 5.5) {
    float drift = uPhase * mainValue(14) * PI * 2.0;
    float primary = zeroMeanSine(uv.y, PI * 2.0 / mainValue(10), drift);
    float secondary = zeroMeanSine(uv.y, PI * 2.0 / mainValue(12),
        -(drift * .71) + mainValue(13) * PI / 180.0);
    float warp = antisymmetricFbm(uv.y, uPhase * mainValue(18) * .08,
        uPhase * mainValue(18) * .06 + .37, mainValue(17), 701.3) * mainValue(16);
    float damping = 1.0 - mainValue(15) * .72;
    float raw = (primary * mainValue(9) + secondary * mainValue(11) + warp) * damping;
    float maximum = 2.0 * (mainValue(9) + mainValue(11) + mainValue(16)) * damping;
    boundary = base + limitDeformation(raw, maximum, base);
    float influence = gaussian(vec2(uv.x - boundary, 0.0), vec2(.36, 1.0));
    flow = vec2(raw * .16, -(primary + secondary) * influence * .06);
    rawLight = abs(primary * .68 + secondary * .32) * .18 + influence * .012;
    rawChroma = warp * .18;
  } else if (uEffect < 6.5) {
    float drift = uPhase * mainValue(14) * PI * 2.0;
    float wave = mainValue(10) * PI * 2.0;
    float a = zeroMeanSine(uv.y, wave, drift);
    float b = zeroMeanSine(uv.y, wave, drift + mainValue(13) * PI / 180.0);
    float paired = a - b * mainValue(15) * mainValue(12);
    float shaped = sign(paired) * pow(abs(paired), mainValue(16));
    float maximumShape = pow(1.0 + mainValue(15) * mainValue(12), mainValue(16));
    float normalized = shaped / max(.000001, maximumShape);
    float gain = mainValue(11) / .22;
    float warp = antisymmetricFbm(uv.y, -(uPhase * mainValue(19) * .07),
        uPhase * mainValue(19) * .05 + .73, mainValue(18), 811.9) * mainValue(17);
    float raw = normalized * mainValue(9) * gain * .5 + warp;
    float maximum = mainValue(9) * gain * .5 + mainValue(17);
    boundary = base + limitDeformation(raw, maximum, base);
    flow = vec2(raw * .17, (a + b) * .042);
    rawLight = abs(paired) / max(1.0, maximumShape) * .12;
    rawChroma = normalized * .10;
  } else {
    float rawSeam = zeroMeanSine(uv.y, PI * 2.0 / mainValue(10),
        uPhase * mainValue(11) * PI * 2.0) * mainValue(9);
    boundary = base + limitDeformation(rawSeam, mainValue(9) * 2.0, base);
    float count = clamp(mainValue(12), 2.0, 8.0);
    for (int index = 0; index < 8; index++) {
      if (float(index) >= count) break;
      vec3 seed = balanceChargeSeedAt(index);
      vec2 center = vec2(base + (seed.x - .5) * .76 +
          sin(uPhase * .13 + seed.z) * mainValue(15) * .42,
          seed.y + cos(uPhase * .11 + seed.z) * mainValue(15));
      float variation = 1.0 + ((float(index) / max(1.0, count - 1.0)) - .5) * mainValue(14);
      float morph = 1.0 + sin(uPhase * .17 + seed.z * mainValue(20)) * mainValue(19) * .35;
      float radius = max(.03, mainValue(13) * variation * morph);
      vec2 delta = uv - center;
      float charge = gaussian(delta, vec2(radius, radius * .82));
      float polarity = sin(uPhase * .16 + seed.z + mainValue(18) * PI / 180.0);
      flow += (vec2(-delta.y, delta.x) * polarity * .15 + delta * .035) * charge;
      rawLight += charge * abs(polarity) * .025;
      rawChroma += charge * polarity * .08;
    }
  }
  vec2 sourceUv = boundedMaterialSourceUv(uv, flow);
  float candidateCoordinate = canonicalGradientCoordinate(sourceUv);
  float coordinate = distributionSafePaletteCoordinate(
      baseCoordinate, candidateCoordinate, strength);
  float broadPulse = sin(uPhase * mainValue(6) * PI * 2.0) * mainValue(5) * .18;
  float light = clamp((rawLight * mainValue(3) + broadPulse) * strength +
      uPulse * .025 + rippleLight * uTapPulseLight, -.12, .12);
  return applyMaterialOptics(sampleCanonicalPalette(coordinate), light,
      clamp(rawChroma * mainValue(4) * strength, -.12, .12));
}
*/
// Full-field flow has no palette-side, lens or separator input. A seed only
// changes analytical velocity-mode phases; it never assigns RGB or U ranges.
float fullFieldSeedPhase(float seed, float index) {
  return sin(seed * (.00173 + index * .00019) + index * 17.31) * PI;
}

// Slots 36–39 are the audited v3 tail reserve for one family-level palette
// basis. Slot 37 packs the two integral degree sliders as base + phase/1000;
// this retains 1° UI precision without inserting a new uniform or shifting
// any existing effect-control index.
float fullFieldOrientationEnabled() {
  return uEffect > 8.5 && uEffect < 13.5 && mainValue(36) > .5 ? 1.0 : 0.0;
}

float fullFieldOrientationBaseDegrees() {
  return floor(mainValue(37) + .0001);
}

float fullFieldOrientationPhaseDegrees() {
  return floor(fract(mainValue(37)) * 1000.0 + .5);
}

float fullFieldPaletteAngle() {
  if (fullFieldOrientationEnabled() < .5) return 112.0;
  float base = fullFieldOrientationBaseDegrees();
  float phase = fullFieldOrientationPhaseDegrees() * PI / 180.0;
  float sweep = mainValue(38);
  float speed = mainValue(39);
  return base + sweep * sin(uPhase * (.018 + speed * .12) + phase);
}

float activeMaterialPaletteCoordinate(vec2 uv) {
  if (fullFieldOrientationEnabled() < .5) {
    return canonicalGradientCoordinate(uv);
  }
  return canonicalGradientCoordinateAtAngle(uv, fullFieldPaletteAngle());
}

float fullFieldBoundaryEnvelope(vec2 uv, float edgeFreedom) {
  vec2 edge = min(uv, vec2(1.0) - uv);
  float width = mix(.16, .055, saturate(edgeFreedom));
  return smooth01(0.0, width, edge.x) * smooth01(0.0, width, edge.y);
}

vec2 fullFieldStreamMode(
    vec2 uv,
    float phase,
    float seed,
    float index,
    float scale,
    float amplitude) {
  // Integer-frequency stream modes keep their normal component at zero on
  // each domain edge. The seed belongs to temporal mode phase only, never to
  // a translated palette field or a visible flow object.
  float frequency = max(.40, scale);
  float kx = (1.0 + index) * PI * frequency;
  float ky = (2.0 + index) * PI * frequency;
  float a = uv.x * kx;
  float b = uv.y * ky;
  float temporal = sin(phase * (.47 + index * .173) +
      fullFieldSeedPhase(seed, index));
  // Analytical (dPsi/dy, -dPsi/dx), normalized so amplitude controls speed
  // rather than growing with spatial frequency.
  return vec2(sin(a) * cos(b), -cos(a) * sin(b)) * amplitude * temporal;
}

vec2 fullFieldVelocity(vec2 uv, float phase) {
  float effect = uEffect;
  float scale = max(.40, mainValue(2));
  float seed = mainValue(3);
  float speed = mainValue(1);
  float time = phase * (0.18 + speed * .82);
  vec2 velocity = vec2(0.0);
  float modeCount = effect < 9.5 ? clamp(mainValue(4), 2.0, 5.0) :
      (effect < 10.5 ? clamp(mainValue(6), 2.0, 6.0) :
      (effect < 11.5 ? clamp(mainValue(6), 1.0, 4.0) :
      (effect < 12.5 ? clamp(mainValue(4), 2.0, 5.0) : clamp(mainValue(4), 2.0, 4.0))));
  for (int index = 0; index < 5; index++) {
    if (float(index) >= modeCount) break;
    float i = float(index);
    float amplitude = .120 + .025 * i;
    velocity += fullFieldStreamMode(
        uv, time * (1.0 + i * .173), seed, i, scale, amplitude);
  }

  if (effect < 9.5) {
    float advection = mainValue(5);
    float curl = mainValue(6);
    float stretch = mainValue(7);
    float drift = mainValue(8);
    velocity *= mix(.38, 1.25, curl) * advection * .55;
    velocity += vec2(
        sin((uv.y + time * .73) * PI * scale * 2.0) * sin(uv.x * PI),
        sin((uv.x - time * .47) * PI * scale * 1.61) * sin(uv.y * PI)) *
        stretch * .018;
    velocity += vec2(
        sin(time * .73 + seed * .003),
        cos(time * .47 + seed * .002)) * drift * .006;
  } else if (effect < 10.5) {
    float gyreStrength = mainValue(4);
    float gyreSwitch = mainValue(5);
    float vortexRadius = max(.08, mainValue(7));
    float wander = mainValue(8);
    float asymmetry = mainValue(9);
    float stretch = mainValue(10);
    velocity *= .42;
    float gyre = sin((uv.x + sin(time * .73) * gyreSwitch * .16) * PI) *
        sin(uv.y * PI * (1.0 + asymmetry * .35));
    velocity += vec2(cos(uv.y * PI) * gyre, -cos(uv.x * PI) * gyre) *
        gyreStrength * .020;
    for (int index = 0; index < 6; index++) {
      if (float(index) >= clamp(mainValue(6), 2.0, 6.0)) break;
      float i = float(index);
      vec2 center = vec2(
          .5 + sin(seed * .001 + i * 1.71 + time * (.41 + i * .03)) * (.22 + wander * .18),
          .5 + cos(seed * .0013 + i * 2.13 - time * (.33 + i * .02)) * (.19 + wander * .16));
      vec2 delta = uv - center;
      float influence = exp(-dot(delta, delta) / max(.003, vortexRadius * vortexRadius));
      velocity += vec2(-delta.y, delta.x) * influence * (.015 + stretch * .012);
    }
  } else if (effect < 11.5) {
    float shearX = mainValue(4);
    float shearY = mainValue(5);
    float foldScale = mainValue(7);
    float phaseSpread = mainValue(8) * PI / 180.0;
    float elasticity = mainValue(9);
    float relaxation = mainValue(10);
    velocity += vec2(
        sin((uv.y * foldScale + time * .73) * PI * 2.0 + phaseSpread),
        sin((uv.x * foldScale - time * .47) * PI * 2.0 - phaseSpread)) *
        vec2(shearX, shearY) * (.035 + elasticity * .025);
    velocity *= 1.0 - relaxation * .34;
  } else if (effect < 12.5) {
    float crossFlow = mainValue(5);
    float phaseSpread = mainValue(6) * PI / 180.0;
    float drift = mainValue(7);
    float curvature = mainValue(8);
    float widthVariance = mainValue(9);
    float mixing = mainValue(10);
    velocity += vec2(
        sin((uv.y + time * .61) * PI * (2.0 + widthVariance * 1.8) + phaseSpread),
        sin((uv.x - time * .43) * PI * (1.7 + curvature * 1.6) - phaseSpread)) *
        crossFlow * .040;
    velocity += vec2(
        cos(time * .37 + seed * .002), sin(time * .53 + seed * .003)) * drift * .006;
    velocity *= .72 + mixing * .55;
  } else {
    float depthSeparation = mainValue(5);
    float zDrift = mainValue(6);
    float parallax = mainValue(7);
    float refraction = mainValue(8);
    float depthSoftness = mainValue(9);
    float nearInfluence = mainValue(10);
    float farInfluence = mainValue(11);
    float depth = .5 + .5 * sin((uv.x * 1.31 + uv.y * 1.73 + time * .37 + seed * .0007) * PI * 2.0);
    float depthWeight = mix(farInfluence, nearInfluence, pow(depth, max(.10, depthSoftness)));
    velocity *= mix(.55, 1.35, depthWeight) *
        (1.0 + depthSeparation * .32) * .48;
    velocity += vec2(
        sin((uv.y + time * zDrift) * PI * 2.0) * sin(uv.x * PI),
        -sin((uv.x - time * zDrift * .73) * PI * 2.0) * sin(uv.y * PI)) *
        parallax * .012;
    velocity += vec2(cos(uv.y * PI * 2.0), -cos(uv.x * PI * 2.0)) *
        refraction * (depth - .5) * .010;
  }
  return velocity * fullFieldBoundaryEnvelope(uv, .72);
}

vec2 fullFieldInverseFlowMap(vec2 uv, float phase) {
  float strength = saturate(mainValue(0));
  if (strength <= 0.0) return uv;
  float edgeFreedom = uEffect < 9.5 ? mainValue(9) : .72;
  float horizon = mix(.34, .92, strength) *
      (uEffect < 9.5 ? mix(.65, 1.10, mainValue(5)) : 1.0);
  float stepDepth = horizon * .5;
  vec2 sourceUv = uv;
  for (int step = 0; step < 2; step++) {
    float stepTime = phase - (float(step) + .5) * stepDepth;
    vec2 midpoint = sourceUv - fullFieldVelocity(sourceUv, stepTime) * stepDepth * .5;
    vec2 velocity = fullFieldVelocity(midpoint, stepTime);
    sourceUv -= velocity * stepDepth;
  }
  return uv + (sourceUv - uv) * fullFieldBoundaryEnvelope(uv, edgeFreedom);
}

vec3 fullFieldFlowField(vec2 uv, float rippleLight) {
  // Keep the accepted b2 off-path byte-for-byte semantically identical,
  // including zero-strength static parity. With the optional orientation
  // basis enabled, source material may remain static while its palette axis
  // intentionally moves.
  float strength = saturate(mainValue(0));
  float baseCoordinate = canonicalGradientCoordinate(uv);
  if (strength <= 0.0 && fullFieldOrientationEnabled() < .5) {
    return sampleCanonicalPalette(baseCoordinate);
  }
  vec2 sourceUv = fullFieldInverseFlowMap(uv, uPhase);
  float coordinate = canonicalGradientCoordinate(sourceUv);
  if (fullFieldOrientationEnabled() > .5) {
    coordinate = canonicalGradientCoordinateAtAngle(sourceUv, fullFieldPaletteAngle());
  }
  float relief = uEffect < 9.5 ? mainValue(10) :
      (uEffect < 12.5 ? mainValue(11) : mainValue(13));
  vec2 velocity = fullFieldVelocity(uv, uPhase);
  float energy = clamp(length(velocity) * (1.1 + relief * 5.0), 0.0, .12);
  float light = energy * relief + uPulse * .025 + rippleLight * uTapPulseLight;
  return applyMaterialOptics(sampleCanonicalPalette(coordinate), light, 0.0);
}

// Space Fabric is a separate source-space lane. Its modes are invisible
// metric generators: they never carry a palette coordinate, RGB value, alpha
// or opacity. A negative inner source derivative magnifies current material;
// the wide, weaker positive kernel compensates it in the neighborhood.
vec2 spaceFabricCompensatedKernel(
    vec2 uv,
    vec2 center,
    float angle,
    vec2 axes,
    float magnification,
    float compression) {
  vec2 relative = uv - center;
  vec2 major = vec2(cos(angle), sin(angle));
  vec2 minor = vec2(-major.y, major.x);
  vec2 local = vec2(dot(relative, major) / max(.04, axes.x),
      dot(relative, minor) / max(.04, axes.y));
  float radiusSquared = dot(local, local);
  float inner = exp(-radiusSquared * 1.45);
  float outer = exp(-radiusSquared * .19);
  // The amplitudes keep the default source-map determinant safely positive,
  // including overlapping modes. The annulus is a continuous metric term,
  // not a rendered ring or a separate visual object.
  float metric = -magnification * .145 * inner + compression * .055 * outer;
  return relative * metric;
}

vec2 spaceFabricEnergyNormalizedDisplacement(vec2 summedDisplacement,
    float count) {
  // Independent compensated modes do not share one fixed visual-energy
  // budget. Dividing the entire sum by count made a default multi-mode field
  // less temporal than one isolated mode. Root-energy normalization keeps
  // overlapping modes perceptible while this smooth radial limit preserves
  // the positive-Jacobian, no-edge-plateau contract.
  // Per-variant gains were calibrated against the real-ticker source-map and
  // byte-raster motion contracts; they retain each variant's distinct large-
  // scale temporal grammar rather than changing the shared Header clock.
  float variantEnergy = uEffect < 14.5 ? 7.2 :
      (uEffect < 15.5 ? 12.0 : (uEffect < 16.5 ? 9.0 : 9.3));
  vec2 normalized = summedDisplacement / sqrt(max(1.0, count)) *
      variantEnergy;
  float limit = .11;
  return normalized / (1.0 + length(normalized) / limit);
}

float spaceFabricModeCount() {
  if (uEffect < 14.5) return clamp(mainValue(4), 1.0, 5.0);
  if (uEffect < 15.5) return clamp(mainValue(4), 1.0, 6.0);
  if (uEffect < 16.5) return clamp(mainValue(4), 1.0, 4.0);
  return clamp(mainValue(4) * 2.0, 2.0, 6.0);
}

float spaceFabricRelief() {
  if (uEffect < 14.5) return mainValue(12);
  if (uEffect < 15.5) return mainValue(12);
  if (uEffect < 16.5) return mainValue(11);
  return mainValue(12);
}

// uPhase is already advanced by DashboardHeaderVisualController with the
// selected effect speed. Keep that controller-owned speed contract singular:
// this calibrated conversion only maps Header phase units to the local,
// incommensurate Space Fabric mode frequencies below.
const float SPACE_FABRIC_PHASE_TO_TIME = 7.0;

vec2 spaceFabricSourceUv(vec2 uv, float phase) {
  float strength = saturate(mainValue(0));
  if (strength <= 0.0) return uv;
  float scale = max(.25, mainValue(2));
  float seed = mainValue(3);
  float localTime = phase * SPACE_FABRIC_PHASE_TO_TIME;
  float count = spaceFabricModeCount();
  vec2 displacement = vec2(0.0);
  for (int index = 0; index < 6; index++) {
    if (float(index) >= count) break;
    float i = float(index);
    float phaseOffset = fullFieldSeedPhase(seed, i + 8.0);
    float wander = uEffect < 14.5 ? mainValue(9) :
        (uEffect < 15.5 ? mainValue(7) :
        (uEffect < 16.5 ? mainValue(9) : mainValue(8)));
    float anisotropy = uEffect < 14.5 ? mainValue(8) :
        (uEffect < 15.5 ? mainValue(8) :
        (uEffect < 16.5 ? mainValue(8) : mainValue(10)));
    float softness = uEffect < 14.5 ? mainValue(7) :
        (uEffect < 15.5 ? mainValue(11) :
        (uEffect < 16.5 ? mainValue(7) : mainValue(11)));
    float breathing = uEffect < 14.5 ? mainValue(10) :
        (uEffect < 15.5 ? mainValue(9) :
        (uEffect < 16.5 ? mainValue(5) : mainValue(6)));
    float compression = uEffect < 14.5 ? mainValue(6) :
        (uEffect < 15.5 ? mainValue(6) :
        (uEffect < 16.5 ? mainValue(10) : mainValue(6)));
    float magnification = uEffect < 14.5 ? mainValue(5) :
        (uEffect < 15.5 ? mainValue(5) :
        (uEffect < 16.5 ? mainValue(5) : mainValue(5)));
    float primaryBreath = sin(localTime * (.71 + i * .083) + phaseOffset);
    float secondaryBreath = sin(localTime * (1.19 + i * .061) +
        phaseOffset * 1.73);
    float breathingWave = saturate(.5 + primaryBreath * .34 +
        secondaryBreath * .16);
    // These incommensurate trajectories and axes are the temporal grammar of
    // Space Fabric. They deliberately evolve the hidden metric geometry, not
    // palette ownership or one static magnification coefficient.
    float trajectoryGain = uEffect < 14.5 ? 1.0 :
        (uEffect < 15.5 ? 1.32 : (uEffect < 16.5 ? 1.10 : 1.12));
    float centerRadius = (.20 + wander * .42) * trajectoryGain;
    vec2 center = vec2(
        .5 + sin(phaseOffset * 1.31 + localTime * (.53 + i * .037)) * centerRadius,
        .5 + cos(phaseOffset * .83 - localTime * (.41 + i * .029)) * centerRadius * .72);
    center += vec2(
        sin(localTime * (1.07 + i * .071) + phaseOffset * 1.41),
        cos(localTime * (.89 + i * .053) - phaseOffset * 1.19)) *
        (.050 + wander * .095) * trajectoryGain;
    if (uEffect > 16.5) {
      float pairSign = mod(i, 2.0) < 1.0 ? -1.0 : 1.0;
      float separation = mainValue(7);
      center += vec2(cos(localTime * .29 + phaseOffset),
          sin(localTime * .37 - phaseOffset)) * pairSign * separation * .35;
    }
    float angle = phaseOffset + localTime * (.17 + anisotropy * .26) +
        i * (1.17 + anisotropy * .39);
    float baseAxis = mix(.17, .31, softness) / scale;
    float shapeWave = sin(localTime * (.91 + i * .047) +
        phaseOffset * 1.37);
    float aspect = mix(1.0, 2.05, anisotropy) * max(.45,
        1.0 + (breathingWave - .5) * (.52 + breathing * .95) +
        shapeWave * (.22 + anisotropy * .18));
    vec2 axes = vec2(baseAxis * aspect, baseAxis / aspect);
    float localMagnification = magnification * max(.12,
        .78 + (breathingWave - .5) * (1.05 + breathing * .70) +
        shapeWave * .22);
    if (uEffect > 16.5) {
      localMagnification *= .58 + breathingWave * mainValue(6) * .42;
    }
    displacement += spaceFabricCompensatedKernel(
        uv, center, angle, axes, localMagnification, compression);
  }
  // A source coordinate approaches its output coordinate smoothly at the
  // rectangular boundary. There is no clamp-based edge plateau or wrapping.
  return uv + spaceFabricEnergyNormalizedDisplacement(displacement, count) *
      strength * materialBoundaryEnvelope(uv);
}

vec3 spaceFabricField(vec2 uv, float rippleLight) {
  vec2 sourceUv = spaceFabricSourceUv(uv, uPhase);
  float coordinate = canonicalGradientCoordinate(sourceUv);
  float relief = spaceFabricRelief();
  float metricEnergy = clamp(length(sourceUv - uv) * (1.3 + relief * 4.0), 0.0, .10);
  float light = metricEnergy * relief + uPulse * .020 +
      rippleLight * uTapPulseLight;
  return applyMaterialOptics(sampleCanonicalPalette(coordinate), light, 0.0);
}

vec3 commonField(vec2 uv, float rippleLight) {
  if (uEffect < 8.5) return classicReferenceField(uv, rippleLight);
  if (uEffect < 13.5) return fullFieldFlowField(uv, rippleLight);
  return spaceFabricField(uv, rippleLight);
}

float portalValue(int index, float background) {
  vec4 a = mix(uInterior0, uBackground0, background);
  vec4 b = mix(uInterior1, uBackground1, background);
  vec4 c = mix(uInterior2, uBackground2, background);
  if (index == 0) return a.x;
  if (index == 1) return a.y;
  if (index == 2) return a.z;
  if (index == 3) return a.w;
  if (index == 4) return b.x;
  if (index == 5) return b.y;
  if (index == 6) return b.z;
  if (index == 7) return b.w;
  if (index == 8) return c.x;
  if (index == 9) return c.y;
  if (index == 10) return c.z;
  return c.w;
}
float portalSample(vec2 uv, float effect, float phase, float background) {
  if (effect < .5) return 0.0;
  if (effect < 1.5) {
    float frequency = 3.8 - portalValue(2, background) / 180.0 * 2.9;
    float coarse = portalFbm(uv * frequency, portalValue(5, background), 3);
    float fine = portalFbm(uv * frequency * 2.7, portalValue(5, background) + 41.0, 2);
    float value = mix(coarse, fine, portalValue(4, background) / 180.0);
    float center = 1.0 - portalValue(0, background) / 100.0;
    float width = .015 + portalValue(3, background) / 100.0 * .24;
    return smooth01(center - width, center + width, value) * portalValue(1, background) / 100.0;
  }
  if (effect < 2.5) {
    float frequency = 4.2 - portalValue(2, background) / 200.0 * 3.35;
    float drift = phase * (.035 + portalValue(4, background) / 420.0);
    float morph = phase * (.025 + portalValue(6, background) / 520.0);
    float curl = portalValue(5, background) / 100.0 * .48;
    float wx = portalFbm(uv * 1.7 + vec2(cos(drift), sin(morph)), portalValue(8, background) + 17.0, 3) - .5;
    float wy = portalFbm(uv * 1.7 + vec2(-sin(morph), cos(drift)), portalValue(8, background) + 73.0, 3) - .5;
    vec2 p = (uv + vec2(wx, wy) * curl) * frequency + vec2(cos(drift * .73), sin(drift * .61));
    float broad = portalFbm(p, portalValue(8, background), 3);
    float fine = portalFbm(p * 2.6 + vec2(-morph, morph), portalValue(8, background) + 191.0, 2);
    float value = mix(broad, fine, portalValue(7, background) / 150.0);
    float center = 1.0 - portalValue(0, background) / 100.0;
    float width = .015 + portalValue(3, background) / 100.0 * .24;
    return smooth01(center - width, center + width, value) * portalValue(1, background) / 100.0;
  }
  if (effect < 3.5) {
    float sum = 0.0;
    float count = clamp(portalValue(0, background), 2.0, 12.0);
    for (int i = 0; i < 12; i++) {
      if (float(i) >= count) break;
      float seed = portalValue(8, background);
      float index = float(i);
      float angle = portalHash2(vec2(index, 1.0), seed) * PI * 2.0;
      float rate = .08 + portalValue(5, background) / 560.0 + portalHash2(vec2(index, 2.0), seed) * .09;
      float orbit = .1 + portalHash2(vec2(index, 3.0), seed) * .34;
      vec2 center = vec2(.5 + cos(angle + phase * rate) * orbit,
          .5 + sin(angle * 1.31 - phase * rate * .83) * orbit * .72);
      float variance = 1.0 + (portalHash2(vec2(index, 4.0), seed) - .5) * portalValue(2, background) / 100.0;
      float morph = 1.0 + sin(phase * (.08 + portalValue(7, background) / 600.0) + angle) * portalValue(7, background) / 310.0;
      float radius = max(.025, portalValue(1, background) / 220.0 * variance * morph);
      sum += portalGaussian(uv - center, vec2(radius, radius * (.72 + portalHash2(vec2(index, 5.0), seed) * .42)));
    }
    float merged = 1.0 - exp(-sum * (.7 + portalValue(6, background) / 42.0));
    float width = .03 + portalValue(4, background) / 260.0;
    return smooth01(.2 - width, .2 + width, merged) * portalValue(3, background) / 100.0;
  }
  float field = 0.0;
  float count = max(2.0, floor(portalValue(0, background)) * 2.0);
  for (int i = 0; i < 20; i++) {
    if (float(i) >= count) break;
    float seed = portalValue(9, background);
    float index = float(i);
    float offset = portalHash2(vec2(index, 11.0), seed);
    float age = fract01(phase / max(2.0, portalValue(1, background)) + offset);
    float overlap = .35 + portalValue(2, background) / 125.0;
    float life = pow(max(0.0, sin(PI * age)), .65 + (100.0 - portalValue(3, background)) / 95.0);
    float irregularity = portalValue(8, background) / 100.0;
    float drift = age * (.05 + portalValue(7, background) / 170.0);
    float cx = fract01(portalHash2(vec2(index, 12.0), seed) + drift + sin((age + offset) * PI * 2.0) * .08 * irregularity);
    float cy = saturate(portalHash2(vec2(index, 13.0), seed) + sin(age * 4.7 + offset * 8.0) * .2 * irregularity);
    float radius = max(.02, portalValue(5, background) / 210.0 * (.35 + life * overlap));
    field = max(field, portalGaussian(uv - vec2(cx, cy), vec2(radius, radius * .76)) * life);
  }
  float width = .02 + portalValue(6, background) / 240.0;
  return smooth01(.18 - width, .18 + width, field) * portalValue(4, background) / 100.0;
}

// Portal matter controls coverage and the magnitude of a smooth local flow;
// it never selects a left/right palette side. Its center/window continue to
// define the channel's permitted continuous palette domain.
vec2 portalMaterialFlow(vec2 uv, float matter, float phase) {
  vec2 centered = uv - vec2(.5);
  float drift = sin(phase * PI * 2.0 + uv.y * PI) * .035;
  return vec2(-centered.y, centered.x) * (matter - .5) * .065 +
      vec2(drift, -drift * .48) * (.35 + matter * .65);
}

float portalMaterialCoordinate(
    vec2 uv,
    float matter,
    float center,
    float window,
    float phase) {
  float left = saturate(center - window * .5);
  float right = saturate(center + window * .5);
  // Full Field orientation changes the palette basis, never this Portal
  // material flow. Both background and interior therefore resolve against the
  // same active basis as the already-rendered flowing Header material.
  float baseSourceCoordinate = activeMaterialPaletteCoordinate(uv);
  vec2 sourceUv = boundedMaterialSourceUv(uv,
      portalMaterialFlow(uv, matter, phase));
  float candidateSourceCoordinate = activeMaterialPaletteCoordinate(sourceUv);
  float baseCoordinate = mix(left, right, baseSourceCoordinate);
  float candidateCoordinate = mix(left, right, candidateSourceCoordinate);
  return distributionSafePaletteCoordinate(
      baseCoordinate, candidateCoordinate, .82);
}

vec3 screenBlend(vec3 base, vec3 overlay) { return 1.0 - (1.0 - base) * (1.0 - overlay); }

vec3 saturateColor(vec3 color, float amount) {
  float gray = dot(color, vec3(.213, .715, .072));
  return clamp(mix(vec3(gray), color, amount), 0.0, 1.0);
}

// Source CSS radial overlay: pink → magenta → violet → white → transparent.
// The old Canvas path blurred a temporary layer; this stays analytical at the
// final Header surface and uses fragment derivatives for a subpixel edge.
vec3 touchOverlay(vec2 uv, out float alpha) {
  alpha = 0.0;
  if (uTouchOverlayActive < .5 || uTouchOverlayOpacity <= .0001) {
    return vec3(0.0);
  }
  vec2 point = uv - uTouchOverlayOrigin;
  point.x *= uSize.x / max(1.0, uSize.y);
  vec2 toLeft = uTouchOverlayOrigin;
  vec2 toRight = vec2(1.0) - uTouchOverlayOrigin;
  float farthest = length(vec2(max(toLeft.x, toRight.x) * uSize.x / max(1.0, uSize.y),
      max(toLeft.y, toRight.y)));
  float radius = max(.0001, farthest * .25 * uTouchOverlayScale);
  float t = length(point) / radius;
  vec4 c0 = vec4(1.0, .6549, .8863, .98);
  vec4 c1 = vec4(1.0, .5451, .8549, .86);
  vec4 c2 = vec4(.5451, .2431, 1.0, .76);
  vec4 c3 = vec4(1.0, 1.0, 1.0, .46);
  vec4 color = t < .05 ? mix(c0, c1, t / .05) :
      (t < .11 ? mix(c1, c2, (t - .05) / .06) :
      (t < .19 ? mix(c2, c3, (t - .11) / .08) :
      mix(c3, vec4(1.0, 1.0, 1.0, 0.0), saturate((t - .19) / .06))));
  float blur = uTouchOverlayBlur / max(1.0, min(uSize.x, uSize.y));
  // The current SkSL runtime-effect compiler does not expose derivatives.
  // `uSize` still gives a native-fragment-scale edge width without an
  // unsupported fwidth call or a low-resolution blur texture.
  float edge = max(1.5 / max(uSize.x, uSize.y), blur * .34);
  alpha = color.a * uTouchOverlayOpacity * uTouchInteractionOpacity *
      (1.0 - smoothstep(.25 - edge, .25 + edge, t));
  return saturateColor(color.rgb, 1.85);
}

// Source pointer-trail palette and lifetime are prepared in the retained Dart
// bank. Each point is an analytical radial field; no blurred bitmap or
// offscreen layer is enlarged over the Header.
vec3 touchTrail(vec2 uv, out float alpha) {
  vec3 mixed = vec3(0.0);
  alpha = 0.0;
  float aspect = uSize.x / max(1.0, uSize.y);
  for (int index = 0; index < 26; index++) {
    if (float(index) >= uTrailCount) break;
    vec4 trail = trailAt(index);
    if (trail.z <= .0001 || trail.w <= .0001) continue;
    vec2 delta = uv - trail.xy;
    delta.x *= aspect;
    float radius = max(.0001, (uTrailSize / max(1.0, uSize.x)) * .5 * trail.w);
    float t = length(delta) / radius;
    vec4 c0 = vec4(1.0, .6549, .8863, .96);
    vec4 c1 = vec4(1.0, .5451, .8549, .82);
    vec4 c2 = vec4(.5451, .2431, 1.0, .72);
    vec4 c3 = vec4(1.0, 1.0, 1.0, .42);
    vec4 color = t < .18 ? mix(c0, c1, t / .18) :
        (t < .38 ? mix(c1, c2, (t - .18) / .20) :
        (t < .62 ? mix(c2, c3, (t - .38) / .24) :
        mix(c3, vec4(1.0, 1.0, 1.0, 0.0), saturate((t - .62) / .14))));
    float edge = max(1.5 / max(uSize.x, uSize.y), .018);
    float localAlpha = color.a * trail.z * uTouchInteractionOpacity *
        (1.0 - smoothstep(.76 - edge, .76 + edge, t));
    mixed = screenBlend(mixed, saturateColor(color.rgb, 1.2 + trail.z * .8));
    alpha = 1.0 - (1.0 - alpha) * (1.0 - localAlpha);
  }
  return mixed;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / max(uSize, vec2(1.0));
  float rippleLight;
  vec2 displaced = displaceRipples(uv, rippleLight);

  float backgroundMatter = uBackgroundEnabled > .5
      ? portalSample(displaced, uBackgroundEffect, uBackgroundPhase, 1.0)
      : 0.0;
  // Portal masks and refracts the material that is already flowing/warped. It
  // never restarts IDs 9–17 at the static Header field.
  vec2 backgroundSourceUv = uEffect > 8.5 && uEffect < 13.5
      ? fullFieldInverseFlowMap(displaced, uPhase)
      : (uEffect > 13.5
          ? spaceFabricSourceUv(displaced, uPhase)
          : displaced);
  float backgroundCoordinate = portalMaterialCoordinate(
      backgroundSourceUv, backgroundMatter, uBackgroundCenter, uBackgroundWindow,
      uBackgroundPhase);
  vec3 background = sampleCanonicalPalette(backgroundCoordinate);
  vec3 base = commonField(displaced, rippleLight);
  // `uOpacity` must not turn a separately enabled Portal background into a
  // zero-contribution layer at 100%. Its bounded material field supplies the
  // local blend weight, preserving the canonical multi-stop base between
  // Portal material areas.
  vec3 composed = mix(base, background, backgroundMatter * saturate(uOpacity));

  vec2 interiorUv = displaced;
  if (uInteriorEnabled > .5 && uInteriorRotationEnabled > .5) {
    float aspect = uSize.x / max(1.0, uSize.y);
    float angle = uInteriorPhase * uInteriorRotationSpeed * PI * 2.0;
    mat2 rotate = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 centered = interiorUv - .5;
    centered.x *= aspect;
    centered = rotate * centered;
    centered.x /= aspect;
    interiorUv = mix(interiorUv, centered + .5,
        materialBoundaryEnvelope(interiorUv));
  }
  if (uInteriorEnabled > .5) {
    float matter = portalSample(interiorUv, uInteriorEffect, uInteriorPhase, 0.0);
    vec2 interiorSourceUv = uEffect > 8.5 && uEffect < 13.5
        ? fullFieldInverseFlowMap(interiorUv, uPhase)
        : (uEffect > 13.5
            ? spaceFabricSourceUv(interiorUv, uPhase)
            : interiorUv);
    float interiorCoordinate = portalMaterialCoordinate(
        interiorSourceUv, matter, uInteriorCenter, uInteriorWindow, uInteriorPhase);
    vec3 interior = sampleCanonicalPalette(interiorCoordinate);
    // Color Lab's PortalInteriorMotionRenderer paints this material directly
    // over the already-rendered base canvas with per-pixel alpha. Source-over
    // is intentionally not the Header touch layer's optical screen blend:
    // screen compressed the material contrast until BE/KI was imperceptible.
    composed = mix(composed, interior, matter * .38 * saturate(uOpacity));
  }
  float overlayAlpha;
  vec3 overlay = touchOverlay(uv, overlayAlpha);
  composed = mix(composed, screenBlend(composed, overlay), overlayAlpha);
  float trailAlpha;
  vec3 trail = touchTrail(uv, trailAlpha);
  composed = mix(composed, screenBlend(composed, trail), trailAlpha);
  fragColor = vec4(composed, 1.0);
}
