////////// D4SCO ACES - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates

// sRGB input is always assumed to be linear, and as such is noted
// sRGBl.



////////// INCLUDES
#include "d4sco_helpers.fxh"
#include "d4sco_colorspaces.fxh"



////////// STRUCTS
struct SegmentedSplineParamsC5
{
  float lowCoefs[6];      // coefs for B-spline between minPoint and midPoint (log lum)
  float highCoefs[6];     // coefs for B-spline between midPoint and maxPoint (log lum)
  float slopeLow;         // log-log slope of low linear extension
  float slopeHigh;        // log-log slope of high linear extension

  float2 minPoint;        // all as (lum, lum)
  float2 midPoint;
  float2 maxPoint;
}



////////// CONSTANTS
static const float RRT_GLOW_GAIN = 0.05;
static const float RRT_GLOW_MID = 0.08;
static const float RRT_RED_SCALE = 0.82;
static const float RRT_RED_PIVOT = 0.03;
static const float RRT_RED_HUE = 0.0;
static const float RRT_RED_WIDTH = 135.0;
static const float RRT_SAT_FACTOR = 0.96;

static const SegmentedSplineParamsC5 RRT_PARAMS =
{
  {-4.0000000000, -4.0000000000, -3.1573765773, -0.4852499958, 1.8477324706, 1.8477324706},
  {-0.7185482425, 2.0810307172, 3.6681241237, 4.0000000000, 4.0000000000, 4.0000000000},
  0.0,
  0.0,
  float2(0.18 * pow(2.0, -15.0), 0.0001),
  float2(0.18, 4.8),
  float2(0.18 * pow(2.0, 18.0), 10000.0)
};

static const float AP1_TO_Y = float3(-0.6636628587, 1.6153315917, 0.0167563477);



////////// UTILS
// Specific conversions
float RGBtoSaturation(float3 color)
{
  // Converts RGB value to saturation as in HSV
  return (max(max3(color), DELTA6) - max(min3(color), DELTA6)) / max(max3(color), DELTA6);
}

float RGBtoYC(float3 color, float radiusWeight = 1.75)
{
  // Converts RGB to a luminance proxy YC
  // YC ~ Y + K + chroma
  float chroma = sqrt(
    color.b * (color.b - color.g) +
    color.g * (color.g - color.r) +
    color.r * (color.r - color.b)
  );

  return (sum3(color) + radiusWeight * chroma) / 3.0;
}

float RGBtoHueAngle(float3 color)
{
  // Converts RGB to a geometric hue angle in degrees
  float res;

  // Returns NaN if the color is neutral
  if (same3(color)) res = NAN;
  else res = (180.0 / PI) * atan2(sqrt(3.0) * (sub2(color.gb)), 2.0 * color.r - sub2(color.gb));

  if (res < 0.0) res += 360.0;

  return res;
}

// Hue controls
float getCenteredHue(float hue, float centerHue)
{
  float res = hue - centerHue;

  if (res < -180.0) res += 360.0;
  else if (res > 180.0) res -= 360.0;

  return res;
}

float getUncenteredHue(float hue, float centerHue)
{
  float res = hue + centerHue;

  if (res < 0.0) res += 360.0;
  else if (res > 360.0) res -= 360.0;

  return res;
}

// Glow functions
float glowForward(float yc, float glowGain, float glowMid)
{
  float res;

  if (yc <= (2.0 / 3.0 * glowMid)) res = glowGain;
  else if (yc >= (2.0 * glowMid)) res = 0.0;
  else res = glowGain * (glowMid / yc - 1.0 / 2.0);

  return res;
}

float glowInvert(float yc, float glowGain, float glowMid)
{
  float res;

  if (yc <= ((1.0 + glowGain) * 2.0 / 3.0 * glowMid)) res = (-1.0 * glowGain) / (1.0 + glowGain);
  else if (yc >= (2.0 * glowMid)) res = 0.0;
  else res = glowGain * (glowMid / yc - 1.0 / 2.0) / (glowGain / 2.0 - 1.0);

  return res;
}

// Curve shapers
float sigmoidShaper(float x)
{
  // Was fabs instead of abs
  float t = max(1.0 - abs(x / 2.0), 0.0);
  float y = 1.0 + sign(x) * (1.0 - t * t);

  return y / 2.0;
}

float cubicBasisShaper(float x, float width)
{
  static const float4x4 mat = float4x4(
    -1.0 / 6.0, 3.0 / 6.0, -3.0 / 6.0, 1.0 / 6.0,
    3.0 / 6.0, -6.0 / 6.0, 3.0 / 6.0, 0.0 / 6.0,
    -3.0 / 6.0, 0.0 / 6.0, 3.0 / 6.0, 0.0 / 6.0,
    1.0 / 6.0, 4.0 / 6.0, 1.0 / 6.0, 0.0 / 6.0
  );

  float knots[5] = {
    -width / 2.0,
    -width / 4.0,
    0.0,
    width / 4.0,
    width / 2.0
  };

  float y = 0;
  if (x > knots[0] && x < knots[4])
  {
    float coord = (x - knots[0]) * 4.0 / width;
    int j = trunc(coord);
    float t = coord - j;

    float monomials[4] = {
      cb(t),
      sq(t),
      t,
      1.0
    };

    if (j <= 3 && j >= 0)
      y = monomials[0] * mat[0][3 - j] +
        monomials[1] * mat[1][3 - j] +
        monomials[2] * mat[2][3 - j] +
        monomials[3] * mat[3][3 - j];
    else y = 0.0;
  }

  return y * 3.0 / 2.0;
}

float segmentedSplineShaper(float x, float params = RRT_PARAMS)
{
  static const int N_KNOTS_LOW = 4;
  static const int N_KNOTS_HIGH = 4;

  float logx = log10(max(x, FMIN));

  // TODO
}

// Saturation calculation
// Needs AP1 to Y vector as input
float3x3 getSaturationMatrix(float sat, float3 color)
{
  lum = AP1toY(color);
  float factor = 1.0 - clamp(sat, 0.0, 1.0);

  return float3x3(
    factor * lum.r + sat, factor * lum.g, factor * lum.b,
    factor * lum.r, factor * lum.g + sat, factor * lum.b,
    factor * lum.r, factor * lum.g, factor * lum.b + sat
  );
}



////////// CONVERSIONS (WITH RRT)
// ACES (any) > RRT > sRGBl | D65 | AP <> Rec. 709 primaries
float3 ACEStoOCES(float3 color)
{
  // Constants
  static const float3x3 maxSatMat = getSaturationMatrix(RRT_SAT_FACTOR, AP1_TO_Y);

  // Computing glow
  float saturation = RGBtoSaturation(color);
  float ycInput = RGBtoYC(color);
  float s = sigmoidShaper((saturation - 0.4) / 0.2);
  float addedGlow = 1.0 + glowForward(ycInput, RRT_GLOW_GAIN * s, RRT_GLOW_MID);

  // Was mult_f_f3(addedGlow, color)
  color *= addedGlow;

  // Computing red modifier
  float hue = RGBtoHueAngle(color);
  float hueCentered = getCenteredHue(hue, RRT_RED_HUE);
  float hueWeight = cubicBasisShaper(hueCentered, RRT_RED_WIDTH);

  color.r += hueWeight * saturation * (RRT_RED_PIVOT - color.r) * (1.0 - RRT_RED_SCALE);

  // Going back from ACES to RGB
  color = clamp3(color, 0.0, POSINF);

  // Global desaturation
  float3 precolor = clamp3(color, 0.0, FMAX);
  precolor = mul(precolor, maxSatMat);

  // Apply tonescale
  float3 postcolor = applySegmentedSpline(precolor);

  return AP1toAP0(postcolor);
}