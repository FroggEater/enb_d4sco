////////// D4SCO ACES - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// INCLUDES
#include "d4sco_helpers.fxh"

#include "d4sco_colorspaces.fxh"



////////// CONSTANTS
static const float ACES_CC_MAX = 1.4679964;
static const float ACES_CC_MID = 0.4135884;
static const float ACES_MIN = 0.00006103515;
static const float OCES_MIN = DELTA4;

static const float CINEMA_WHITE = 48.0;
static const float CINEMA_BLACK = 0.02;
static const float DIM_SURROUND_GAMMA = 0.9811;

static const float RRT_GLOW_GAIN = 0.05;
static const float RRT_GLOW_MID = 0.08;
static const float RRT_RED_SCALE = 0.82;
static const float RRT_RED_PIVOT = 0.03;
static const float RRT_RED_HUE = 0.0;
static const float RRT_RED_WIDTH = 135.0;
static const float RRT_SAT_FACTOR = 0.96;
static const float3x3 RRT_SAT_MAT = float3x3(
  0.9708890, 0.0269633, 0.00214758,
  0.0108892, 0.9869630, 0.00214758,
  0.0108892, 0.0269633, 0.96214800
);

static const float ODT_SAT_FACTOR = 0.93;
static const float3x3 ODT_SAT_MAT = float3x3(
  0.949056, 0.0471857, 0.00375827,
  0.019056, 0.9771860, 0.00375827,
  0.019056, 0.0471857, 0.93375800
);

static const float3 AP1_TO_Y = float3(0.2722287168, 0.6740817658, 0.0536895174);

static const float3x3 MAT3 = float3x3(
  0.5, -1.0, 0.5,
  -1.0, 1.0, 0.0,
  0.5, 0.5, 0.0
);

static const float4x4 MAT4 = float4x4(
  -1.0 / 6.0,  3.0 / 6.0, -3.0 / 6.0,  1.0 / 6.0,
  3.0 / 6.0, -6.0 / 6.0,  3.0 / 6.0,  0.0 / 6.0,
  -3.0 / 6.0,  0.0 / 6.0,  3.0 / 6.0,  0.0 / 6.0,
  1.0 / 6.0,  4.0 / 6.0,  1.0 / 6.0,  0.0 / 6.0
);



////////// UTILS
// Special conversions
float3 surroundDarkToDim(float3 color)
{
  float3 cieColor = AP1toXYZ(color);
  float3 xyyColor = XYZtoxyY(cieColor);

  xyyColor.z = clamp(xyyColor.z, 0.0, HALF_MAX);
  xyyColor.z = pow(xyyColor.z, DIM_SURROUND_GAMMA);
  cieColor = xyYtoXYZ(xyyColor);

  return XYZtoAP1(cieColor);
}

float YtoLinear(float y, float yMin, float yMax)
{
  return (y - yMin) / (yMax - yMin);
}

float RGBtoSaturation(float3 color)
{
  float ma = max3(color);
  float mi = min3(color);

  return (max(ma, DELTA4) - max(mi, DELTA4)) / max(ma, DELTA2);
}

float RGBtoYC(float3 color, float radiusWeight = 1.75)
{
  float chroma = sqrt(
    color.b * (color.b - color.g) +
    color.g * (color.g - color.r) +
    color.r * (color.r - color.b)
  );

  return (sum3(color) + radiusWeight * chroma) / 3.0;
}

float RGBtoHue(float3 color)
{
  float hue = same3(color) ?
    0.0 : (180.0 / PI) * atan2(sqrt(3.0) * sub2(color.gb), 2.0 * color.r - sum2(color.gb));

  if (hue < 0.0) hue += 360.0;

  return hue;
}

// Shapes and angles
float centerHue(float hue, float center)
{
  float centeredHue = hue - center;
  if (centeredHue < -180) centeredHue += 360.0;
  else if (centeredHue > 180) centeredHue -= 360.0;

  return centeredHue;
}

float sigmoidShaper(float x)
{
  // Sigmoid function between 0 and 1 spanning -2 to +2
  float t = max(1.0 - abs(x / 2.0), 0.0);
  float y = 1.0 + sign(x) * (1.0 - sq(t));

  return y / 2.0;
}

float cubicBasisShaper(float x, float width)
{
  return sq(smoothstep(0.0, 1.0, 1.0 - abs(2.0 * x / width)));
}

// Glow functions
float forwardGlow(float yc, float glowGain, float glowMid)
{
  float glowGainOut;

  if (yc <= 2.0 / 3.0 * glowMid) glowGainOut = glowGain;
  else if (yc >= 2.0 * glowMid) glowGainOut = 0.0;
  else glowGainOut = glowGain * (glowMid / yc - 1.0 / 2.0);

  return glowGainOut;
}



////////// SPLINES
// C5 Segmented spline - Params set to ACES ones for RRT
static const int SPL5_KNOTS_LOW = 4;
static const int SPL5_KNOTS_HIGH = 4;
static const float SPL5_SLOPE_LOW = 0.0;
static const float SPL5_SLOPE_HIGH = 0.0;
static const float2 SPL5_MINPOINT = float2(0.18 * exp2(-15.0), 0.0001);
static const float2 SPL5_MIDPOINT = float2(0.18, 0.48);
static const float2 SPL5_MAXPOINT = float2(0.18 * exp2(18.0), 10000.0);
static const float SPL5_COEFS_LOW[6] =
  {-4.0000000000, -4.0000000000, -3.1573765773, -0.4852499958, 1.8477324706, 1.8477324706};
static const float SPL5_COEFS_HIGH[6] =
  {-0.7185482425, 2.0810307172, 3.6681241237, 4.0000000000, 4.0000000000, 4.0000000000};

float applySegmentedSplineC5(float x)
{
  if (x <= 0.0) x = ACES_MIN;

  float logx = log10(x);
  float logy;

  if (logx <= log10(SPL5_MINPOINT.x))
  {
    logy = logx * SPL5_SLOPE_LOW + (log10(SPL5_MINPOINT.y) - SPL5_SLOPE_LOW * log10(SPL5_MINPOINT.x));
  }
  else if ((logx > log10(SPL5_MINPOINT.x)) && (logx < log10(SPL5_MIDPOINT.x)))
  {
    float coord = (SPL5_KNOTS_LOW - 1) * (logx - log10(SPL5_MINPOINT.x)) / (log10(SPL5_MIDPOINT.x) - log10(SPL5_MINPOINT.x));
    int j = coord;
    float t = coord - j;

    float3 cf = float3(SPL5_COEFS_LOW[j], SPL5_COEFS_LOW[j + 1], SPL5_COEFS_LOW[j + 2]);
    float3 monomials = float3(t * t, t, 1.0);

    logy = dot(monomials, mul(MAT3, cf));
  }
  else if ((logx >= log10(SPL5_MIDPOINT.x)) && (logx < log10(SPL5_MAXPOINT.x)))
  {
    float coord = (SPL5_KNOTS_HIGH - 1) * (logx - log10(SPL5_MIDPOINT.x)) / (log10(SPL5_MAXPOINT.x) - log10(SPL5_MIDPOINT.x));
    int j = coord;
    float t = coord - j;

    float3 cf = float3(SPL5_COEFS_HIGH[j], SPL5_COEFS_HIGH[j + 1], SPL5_COEFS_HIGH[j + 2]);
    float3 monomials = float3(t * t, t, 1.0);

    logy = dot(monomials, mul(MAT3, cf));
  }
  else
  {
    logy = logx * SPL5_SLOPE_HIGH + (log10(SPL5_MAXPOINT.y) - SPL5_SLOPE_HIGH * log10(SPL5_MAXPOINT.x));
  }

  return pow(10.0, logy);
}

// C9 Segmented spline - Params set to ACES ones for 48 nits
static const int SPL9_KNOTS_LOW = 8;
static const int SPL9_KNOTS_HIGH = 8;
static const float SPL9_SLOPE_LOW = 0.0;
static const float SPL9_SLOPE_HIGH = 0.04;
static const float2 SPL9_MINPOINT = float2(applySegmentedSplineC5(0.18 * exp2(-6.5)), 0.02);
static const float2 SPL9_MIDPOINT = float2(applySegmentedSplineC5(0.18), 4.8);
static const float2 SPL9_MAXPOINT = float2(applySegmentedSplineC5(0.18 * exp2(6.5)), 48.0);
static const float SPL9_COEFS_LOW[10] =
  {-1.6989700043, -1.6989700043, -1.4779000000, -1.2291000000, -0.8648000000, -0.4480000000, 0.0051800000, 0.4511080334, 0.9113744414, 0.9113744414};
static const float SPL9_COEFS_HIGH[10] =
  {0.5154386965, 0.8470437783, 1.1358000000, 1.3802000000, 1.5197000000, 1.5985000000, 1.6467000000, 1.6746091357, 1.6878733390, 1.6878733390};

float applySegmentedSplineC9(float x)
{
  if (x <= 0.0) x = OCES_MIN;

  float logx = log10(x);
  float logy;

  if (logx <= log10(SPL9_MINPOINT.x))
  {
    logy = logx * SPL9_SLOPE_LOW + (log10(SPL9_MINPOINT.y) - SPL9_SLOPE_LOW * log10(SPL9_MINPOINT.x));
  }
  else if ((logx > log10(SPL9_MINPOINT.x)) && (logx < log10(SPL9_MIDPOINT.x)))
  {
    float coord = (SPL9_KNOTS_LOW - 1) * (logx - log10(SPL9_MINPOINT.x)) / (log10(SPL9_MIDPOINT.x) - log10(SPL9_MINPOINT.x));
    int j = coord;
    float t = coord - j;

    float3 cf = float3(SPL9_COEFS_LOW[j], SPL9_COEFS_LOW[j + 1], SPL9_COEFS_LOW[j + 2]);
    float3 monomials = float3(t * t, t, 1.0);

    logy = dot(monomials, mul(MAT3, cf));
  }
  else if ((logx >= log10(SPL9_MIDPOINT.x)) && (logx < log10(SPL9_MAXPOINT.x)))
  {
    float coord = (SPL9_KNOTS_HIGH - 1) * (logx - log10(SPL9_MIDPOINT.x)) / (log10(SPL9_MAXPOINT.x) - log10(SPL9_MIDPOINT.x));
    int j = coord;
    float t = coord - j;

    float3 cf = float3(SPL9_COEFS_HIGH[j], SPL9_COEFS_HIGH[j + 1], SPL9_COEFS_HIGH[j + 2]);
    float3 monomials = float3(t * t, t, 1.0);

    logy = dot(monomials, mul(MAT3, cf));
  }
  else
  {
    logy = logx * SPL9_SLOPE_HIGH + (log10(SPL9_MAXPOINT.y) - SPL9_SLOPE_HIGH * log10(SPL9_MAXPOINT.x));
  }

  return pow(10.0, logy);
}



////////// RRT - ACES > OCES
float3 applyRRT(float3 color)
{
  // Computing glow
  float saturation = RGBtoSaturation(color);
  float yc = RGBtoYC(color);
  float sigmoid = sigmoidShaper((saturation - 0.4) / 0.2);
  float addedGlow = 1.0 + forwardGlow(yc, RRT_GLOW_GAIN * sigmoid, RRT_GLOW_MID);

  color *= addedGlow;

  // Adjusting red
  float hue = RGBtoHue(color);
  float centeredHue = centerHue(hue, RRT_RED_HUE);
  float hueWeight = cubicBasisShaper(centeredHue, RRT_RED_WIDTH);

  color.r += hueWeight * saturation * (RRT_RED_PIVOT - color.r) * (1.0 - RRT_RED_SCALE);

  // ACES to RGB rendering space
  color = clamp(color, 0.0, HALF_MAX);

  float3 preColor = AP0toAP1(color);
  preColor = clamp(preColor, 0.0, HALF_MAX);

  // Desaturation
  // preColor = mul(RRT_SAT_MAT, preColor);
  preColor = lerp(dot(preColor, AP1_TO_Y), preColor, RRT_SAT_FACTOR);

  // Apply tonescale
  float3 postColor = float3(
    applySegmentedSplineC5(preColor.r),
    applySegmentedSplineC5(preColor.g),
    applySegmentedSplineC5(preColor.b)
  );

  // RGB rendering space to OCES
  return AP1toAP0(postColor);
}

// Assumes an AP1 input and directly outputs it as such
float3 applyModifiedRRT(float3 color)
{
  // Computing glow
  float saturation = RGBtoSaturation(color);
  float yc = RGBtoYC(color);
  float sigmoid = sigmoidShaper((saturation - 0.4) / 0.2);
  float addedGlow = 1.0 + forwardGlow(yc, RRT_GLOW_GAIN * sigmoid, RRT_GLOW_MID);

  color *= addedGlow;

  // Adjusting red
  float hue = RGBtoHue(color);
  float centeredHue = centerHue(hue, RRT_RED_HUE);
  float hueWeight = cubicBasisShaper(centeredHue, RRT_RED_WIDTH);

  color.r += hueWeight * saturation * (RRT_RED_PIVOT - color.r) * (1.0 - RRT_RED_SCALE);

  // ACES to RGB rendering space
  // No conversion this time as we should already be in ACEScg, or AP1
  float3 preColor = clamp(color, 0.0, HALF_MAX);

  // Desaturation
  // preColor = mul(RRT_SAT_MAT, preColor);
  preColor = lerp(dot(preColor, AP1_TO_Y), preColor, RRT_SAT_FACTOR);

  // Apply tonescale
  float3 postColor = float3(
    applySegmentedSplineC5(preColor.r),
    applySegmentedSplineC5(preColor.g),
    applySegmentedSplineC5(preColor.b)
  );

  // RGB rendering space to OCES
  // We output AP1 instead of AP0, since ODT directly converts to AP1 afterwards
  return postColor;
}



////////// ODT - OCES > sRGB (D65, 100 nits)
float3 applyODT(float3 color)
{
  // OCES to RGB rendering space
  float3 preColor = AP0toAP1(color);

  // Apply tonescale
  float3 postColor = float3(
    applySegmentedSplineC9(preColor.r),
    applySegmentedSplineC9(preColor.g),
    applySegmentedSplineC9(preColor.b)
  );

  // Scale luminance to linear color value and compensate luminance
  // surroundDarkToDim also goes back to AP1
  float3 linColor = float3(
    YtoLinear(postColor.r, CINEMA_BLACK, CINEMA_WHITE),
    YtoLinear(postColor.g, CINEMA_BLACK, CINEMA_WHITE),
    YtoLinear(postColor.b, CINEMA_BLACK, CINEMA_WHITE)
  );
  linColor = surroundDarkToDim(linColor);

  // Desaturation
  // linColor = mul(ODT_SAT_MAT, linColor);
  linColor = lerp(dot(linColor, AP1_TO_Y), linColor, ODT_SAT_FACTOR);

  // Rendering space RGB to XYZ
  float3 cieColor = AP1toXYZ(linColor);
  cieColor = D60toD65(cieColor);

  // Back to display primaries
  linColor = XYZtosRGBl(cieColor);

  // Return
  return saturate(linColor);
}

// Assumes an AP1 input
float3 applyModifiedODT(float3 color)
{
  // Apply tonescale
  float3 postColor = float3(
    applySegmentedSplineC9(color.r),
    applySegmentedSplineC9(color.g),
    applySegmentedSplineC9(color.b)
  );

  // Scale luminance to linear color value and compensate luminance
  // surroundDarkToDim also goes back to AP1
  float3 linColor = float3(
    YtoLinear(postColor.r, CINEMA_BLACK, CINEMA_WHITE),
    YtoLinear(postColor.g, CINEMA_BLACK, CINEMA_WHITE),
    YtoLinear(postColor.b, CINEMA_BLACK, CINEMA_WHITE)
  );
  linColor = surroundDarkToDim(linColor);

  // Desaturation
  // linColor = mul(ODT_SAT_MAT, linColor);
  linColor = lerp(dot(linColor, AP1_TO_Y), linColor, ODT_SAT_FACTOR);

  // Rendering space RGB to XYZ
  float3 cieColor = AP1toXYZ(linColor);
  cieColor = D60toD65(cieColor);

  // Back to display primaries
  linColor = XYZtosRGBl(cieColor);

  // Return
  return saturate(linColor);
}



////////// FULL TRANSFORMS - ACES > sRGB (D65, 100 nits)
// ACES2065-1 or ACEScg to Rec. 709 sRGBl
float3 applyACESMapping(float3 color, bool modified = false)
{
  float3 rrtColor;
  float3 odtColor;
  if (modified)
  {
    rrtColor = applyModifiedRRT(color);
    odtColor = applyModifiedODT(rrtColor);
  }
  else
  {
    rrtColor = applyRRT(color);
    odtColor = applyODT(rrtColor);
  }
  return odtColor;
}