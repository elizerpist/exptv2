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
uniform vec4 uColorA;
uniform vec4 uColorB;
uniform vec4 uGradient0;
uniform vec4 uGradient1;
uniform vec4 uGradient2;
uniform vec4 uGradient3;
uniform vec4 uGradientStops;
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
// layer = rotation cosine, rotation sine, coherent breathing, depth offset.
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
// Exact integer hash used by MindPortalEnergy's source value-noise path.
// The previous sin-hash was continuous but generated a visibly different
// field character from the Color Lab's deterministic lattice.
float energyHash(vec2 value, float seed) {
  uint x = uint(int(floor(value.x)));
  uint y = uint(int(floor(value.y)));
  uint seedInt = uint(int(floor(seed * 1000.0 + .5)));
  uint hashed = x * 374761393u ^ y * 668265263u ^ seedInt * 1442695041u;
  hashed = (hashed ^ (hashed >> 13u)) * 1274126177u;
  hashed ^= hashed >> 16u;
  return float(hashed) / 4294967295.0;
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
  if (index < 4) return uMain0[index];
  if (index < 8) return uMain1[index - 4];
  if (index < 12) return uMain2[index - 8];
  if (index < 16) return uMain3[index - 12];
  if (index < 20) return uMain4[index - 16];
  if (index < 24) return uMain5[index - 20];
  if (index < 28) return uMain6[index - 24];
  if (index < 32) return uMain7[index - 28];
  if (index < 36) return uMain8[index - 32];
  return uMain9[index - 36];
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

vec3 colorMix(float coordinate, float light, float chroma) {
  vec3 color = mix(uColorA.rgb, uColorB.rgb, saturate(coordinate));
  float gray = (color.r + color.g + color.b) / 3.0;
  color = mix(vec3(gray), color, 1.0 + chroma);
  return clamp(color * (1.0 + light), 0.0, 1.0);
}

vec4 gradientColorAt(int index) {
  if (index == 0) return uGradient0;
  if (index == 1) return uGradient1;
  if (index == 2) return uGradient2;
  return uGradient3;
}
float gradientStopAt(int index) { return uGradientStops[index]; }
vec3 canonicalGradient(vec2 uv) {
  // Flutter's current static Header is `Alignment.topLeft → bottomRight`.
  // The dot projection is the corresponding local normalized coordinate.
  float coordinate = saturate((uv.x + uv.y) * .5);
  int segment = 2;
  for (int index = 0; index < 3; index++) {
    if (coordinate <= gradientStopAt(index + 1)) {
      segment = index;
      break;
    }
  }
  float left = gradientStopAt(segment);
  float right = gradientStopAt(segment + 1);
  float amount = saturate((coordinate - left) / max(.000001, right - left));
  return mix(gradientColorAt(segment).rgb, gradientColorAt(segment + 1).rgb, amount);
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

// Fluvi-native pseudo-volumetric material. The layer sequence is intentionally
// near → middle → far: later layers contribute through front transmittance.
// The five-blob inner loop contains no sqrt/exp/trigonometric animation.
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
  vec3 base = colorMix(uv.x, uPulse * .025 + rippleLight * uTapPulseLight, 0.0);
  vec3 accumulated = vec3(0.0);
  float transmittance = 1.0;
  float aspect = uSize.x / max(1.0, uSize.y);

  for (int layerIndex = 0; layerIndex < 3; layerIndex++) {
    vec4 layer = deepLayerAt(layerIndex);
    vec2 centered = uv - vec2(.5);
    // Farther material occupies a broader, calmer projection. This is the
    // live depth-separation control prepared by the retained layer skeleton.
    centered *= 1.0 + layer.w * .22;
    centered.x *= aspect;
    mat2 rotation = mat2(layer.x, -layer.y, layer.y, layer.x);
    centered = rotation * centered;
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

    // One deliberately weak density-only modulation per depth layer. It is
    // not part of the analytic form-light gradient and cannot form tendrils.
    float noise = (fbm3(point * noiseScale + vec2(uPhase * (.021 + float(layerIndex) * .009),
        -uPhase * (.017 + float(layerIndex) * .006)), 913.0 + float(layerIndex) * 71.0) - .5) * 2.0;
    float materialDensity = rawDensity * densityControl * (1.0 + noise * noiseAmount);
    float edgeStart = .10 + (1.0 - softness) * .24;
    float edgeEnd = edgeStart + .58 + softness * .42;
    float fieldAlpha = smooth01(edgeStart, edgeEnd, materialDensity);
    float layerOpacity = layerIndex == 0 ? nearOpacity :
        (layerIndex == 1 ? middleOpacity : farOpacity);
    float alpha = saturate(fieldAlpha * layerOpacity * strength * (1.0 + layer.z * .75));

    float bWeight = layerIndex == 0 ? (.5 + depthColorSeparation * .25) :
        (layerIndex == 1 ? .5 : (.5 - depthColorSeparation * .25));
    vec3 materialColor = mix(uColorA.rgb, uColorB.rgb, saturate(bWeight));
    vec3 normal = normalize(vec3(gradient * 2.25, .86));
    vec3 lightDirection = normalize(vec3(-.32, -.18, .93));
    float layerLight = layerIndex == 0 ? 1.0 : (layerIndex == 1 ? .45 : .05);
    float formLight = (dot(normal, lightDirection) - .42) * lighting * layerLight;
    float core = smooth01(.92, 1.68, rawDensity);
    materialColor *= 1.0 + formLight + core * coreGlow + layer.z * .18;
    accumulated += transmittance * clamp(materialColor, 0.0, 1.0) * alpha;
    transmittance *= 1.0 - alpha;
  }
  return clamp(accumulated + transmittance * base, 0.0, 1.0);
}

// The dual-tide implementation is a direct fragment-level transcription of
// the common Color Lab path. Other source modes retain distinct, continuous
// procedural projections rather than falling back to a sparse mesh.
vec3 commonField(vec2 uv, float rippleLight) {
  if (uEffect < .5) return clamp(canonicalGradient(uv) * (1.0 + uPulse * .025), 0.0, 1.0);
  if (uEffect < 8.5 && uEffect > 7.5) return deepDriftField(uv, rippleLight);
  float strength = mainValue(0);
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
  float broad = (fbm3(p * vec2(1.17, 1.09) + vec2(morphTime * .07, -morphTime * .05), 31.7) - .5) * morphAmount;
  // Render minőség remains meaningful on the shader path as procedural fine
  // detail only. It cannot reduce spatial evaluation to a sparse mesh.
  float fine = (fbm3(p * vec2(2.8, 2.5) + vec2(-morphTime * .09, morphTime * .08), 67.3) - .5) * detail * mix(.45, 1.0, uRenderQuality);
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
    // Money modes keep the source's non-wrapping split boundary.  The
    // calculation is fragment-resolved, so the line is no longer reconstructed
    // from sparse mesh nodes.
    float base = .08 + saturate(uPaletteSplit) * .84;
    float boundary = base;
    float rawLight = 0.0;
    float rawChroma = 0.0;
    if (uEffect < 5.5) {
      float drift = uPhase * mainValue(14) * PI * 2.0;
      float primary = zeroMeanSine(p.y, PI * 2.0 / mainValue(10), drift);
      float secondary = zeroMeanSine(p.y, PI * 2.0 / mainValue(12), -(drift * .71) + mainValue(13) * PI / 180.0);
      float warp = antisymmetricFbm(p.y, uPhase * mainValue(18) * .08,
          uPhase * mainValue(18) * .06 + .37, mainValue(17), 701.3) * mainValue(16);
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
      float warp = antisymmetricFbm(p.y, -(uPhase * mainValue(19) * .07),
          uPhase * mainValue(19) * .05 + .73, mainValue(18), 811.9) * mainValue(17);
      float raw = normalized * mainValue(9) * gain * .5 + warp;
      float maximum = mainValue(9) * gain * .5 + mainValue(17);
      boundary = base + limitDeformation(raw, maximum, base);
      rawLight = abs(paired) / max(1.0, maximumShape) * .72;
      rawChroma = normalized * .55;
    } else {
      float rawSeam = zeroMeanSine(p.y, PI * 2.0 / mainValue(10),
          uPhase * mainValue(11) * PI * 2.0) * mainValue(9);
      boundary = base + limitDeformation(rawSeam, mainValue(9) * 2.0, base);
      int side = p.x <= boundary ? 0 : 1;
      int count = int(clamp(mainValue(12), 2.0, 8.0));
      for (int index = 0; index < 8; index++) {
      if (index >= count || index % 2 != side) continue;
        vec3 seed = balanceChargeSeedAt(index);
        float start = side == 0 ? 0.0 : base;
        float width = side == 0 ? base : 1.0 - base;
        vec2 center = vec2(start + width * (.12 + seed.x * .76) +
            sin(uPhase * .13 + seed.z) * mainValue(15) * width,
            seed.y + cos(uPhase * .11 + seed.z) * mainValue(15));
        float variation = 1.0 + ((float(index) / max(1.0, float(count - 1))) - .5) * mainValue(14);
        float morph = 1.0 + sin(uPhase * .17 + seed.z * mainValue(20)) * mainValue(19) * .35;
        float radius = max(.03, mainValue(13) * variation * morph);
        float charge = gaussian(p - center, vec2(radius, radius * .82));
        float polarity = sin(uPhase * .16 + seed.z + float(side) * mainValue(18) * PI / 180.0);
        rawLight += charge * polarity * mainValue(16);
        rawChroma += charge * polarity * mainValue(17);
      }
    }
    if (strength <= 0.0) return colorMix(p.x, 0.0, 0.0);
    boundary = clamp(mix(base, boundary, strength), .04, .96);
    float mapped = p.x <= boundary ? base * p.x / max(.000001, boundary) :
        base + (1.0 - base) * (p.x - boundary) / max(.000001, 1.0 - boundary);
    float seam = exp(-abs(p.x - boundary) / max(.01, mainValue(2)));
    float pulse = sin(uPhase * mainValue(6) * PI * 2.0) * mainValue(5) * seam;
    return colorMix(mapped,
      clamp((rawLight * mainValue(3) + pulse) * strength + uPulse * .025 + rippleLight * uTapPulseLight, -.22, .22),
      clamp(rawChroma * mainValue(4) * strength, -.35, .35));
  }
  float mixture = smooth01(.5 - softness, .5 + softness, field);
  float seam = 4.0 * mixture * (1.0 - mixture);
  float pulse = sin(uPhase * pulseSpeed * PI * 2.0) * pulseAmount;
  float light = clamp((pulse + (broad + fine) * lightAmount + localLight) * seam +
      uPulse * .025 + rippleLight * uTapPulseLight, -.25, .25);
  return colorMix(mix(uv.x, mixture, saturate(strength)), light, 0.0);
}

float portalValue(int index, bool background) {
  vec4 a = background ? uBackground0 : uInterior0;
  vec4 b = background ? uBackground1 : uInterior1;
  vec4 c = background ? uBackground2 : uInterior2;
  if (index < 4) return a[index];
  if (index < 8) return b[index - 4];
  return c[index - 8];
}
float portalSample(vec2 uv, float effect, float phase, bool background) {
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
    int count = int(clamp(portalValue(0, background), 2.0, 12.0));
    for (int i = 0; i < 12; i++) {
      if (i >= count) break;
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
  int count = max(2, int(portalValue(0, background)) * 2);
  for (int i = 0; i < 20; i++) {
    if (i >= count) break;
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

vec3 screenBlend(vec3 base, vec3 overlay) { return 1.0 - (1.0 - base) * (1.0 - overlay); }

void main() {
  vec2 uv = FlutterFragCoord().xy / max(uSize, vec2(1.0));
  float rippleLight;
  vec2 displaced = displaceRipples(uv, rippleLight);

  float backgroundMatter = uBackgroundEnabled > .5
      ? portalSample(displaced, uBackgroundEffect, uBackgroundPhase, true)
      : 0.0;
  float backgroundLeft = saturate(uBackgroundCenter - uBackgroundWindow * .5);
  float backgroundRight = saturate(uBackgroundCenter + uBackgroundWindow * .5);
  vec3 background = mix(mix(uColorA.rgb, uColorB.rgb, backgroundLeft),
      mix(uColorA.rgb, uColorB.rgb, backgroundRight), backgroundMatter);
  vec3 base = commonField(displaced, rippleLight);
  vec3 composed = mix(background, base, saturate(uOpacity));

  vec2 interiorUv = displaced;
  if (uInteriorEnabled > .5 && uInteriorRotationEnabled > .5) {
    float aspect = uSize.x / max(1.0, uSize.y);
    float angle = uInteriorPhase * uInteriorRotationSpeed * PI * 2.0;
    mat2 rotate = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 centered = interiorUv - .5;
    centered.x *= aspect;
    centered = rotate * centered;
    centered.x /= aspect;
    interiorUv = clamp(centered + .5, 0.0, 1.0);
  }
  if (uInteriorEnabled > .5) {
    float matter = portalSample(interiorUv, uInteriorEffect, uInteriorPhase, false);
    float tint = smooth01(uPaletteSplit - .18, uPaletteSplit + .18, interiorUv.x);
    vec3 interior = mix(uColorA.rgb, uColorB.rgb, tint);
    composed = mix(composed, screenBlend(composed, interior), matter * .38 * saturate(uOpacity));
  }
  fragColor = vec4(composed, 1.0);
}
