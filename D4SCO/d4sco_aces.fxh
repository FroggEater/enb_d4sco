////////// D4SCO ACES - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates

// sRGB input is always assumed to be linear, and as such is noted
// sRGBl.



////////// CONSTANTS
static const float RRT_GLOW_GAIN = 0.05;
static const float RRT_GLOW_MID = 0.08;
static const float RRT_RED_SCALE = 0.82;
static const float RRT_RED_PIVOT = 0.03;
static const float RRT_RED_HUE = 0.0;
static const float RRT_RED_WIDTH = 135.0;
static const float RRT_SAT_FACTOR = 0.96;



////////// UTILS
// ACES utils
float RGBtoSaturation(float3 color)
{
  return (max(max3(color), DELTA6) - max(min3(color), DELTA6)) / max(max3(rgb), DELTA3);
}

float RGBtoYC(float3 color, float radiusWeight = 1.75)
{
  // Convert RGB to a luminance proxy YC
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
  // Convert RGB to a geometric hue angle in degrees
  float res;

  // Returns NaN if the color is neutral
  if (same3(color)) res = 0.0 / 0.0;
  else res = (180.0 / PI) * atan2(sqrt(3.0) * (sub2(color.gb)), 2.0 * color.r - sub2(color.gb));

  if (res < 0.0) res += 360.0;

  return res;
}

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

  // TODO
}

float glowForward(float yc, float gain, float mid)
{
  float res;

  if (yc <= (2.0 / 3.0 * mid)) res = gain;
  else if (yc >= (2.0 * mid)) res = 0.0;
  else res = gain * (mid / yc - 1.0 / 2.0);

  return res;
}

float glowInvert(float yc, float gain, float mid)
{
  float res;

  if (yc <= ((1.0 + gain) * 2.0 / 3.0 * mid)) res = (-1.0 * gain) / (1.0 + gain);
  else if (yc >= (2.0 * mid)) res = 0.0;
  else res = gain * (mid / yc - 1.0 / 2.0) / (gain / 2.0 - 1.0);

  return res;
}



////////// CONVERSIONS (WITH RRT)
// ACES (any) > RRT > sRGBl | D65 | AP <> Rec. 709 primaries
float3 ACEStoOCES(float3 color)
{
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

  // TODO
}