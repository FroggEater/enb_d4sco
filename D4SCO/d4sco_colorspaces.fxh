////////// D4SCO Colorspaces - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates

// Except in specific cases (eg. sRGB to sRGB', or sRGBl as noted here), all colorspaces
// are assumed to be linear, with a final conversion from sRGB to sRGB' having to
// be done at the end for a gamma corrected output. All RGB space to RGB space conversions
// use the Bradford CAT, and have been computed using Color Dash :
// https://www.colour-science.org/apps/



////////// INCLUDES
#include "d4sco_helpers.fxh"



////////// NON-LINEAR TO LINEAR
// sRGB (non-linear) <> sRGBl (linear) | D65 | Rec. 709 primaries
float3 sRGBtosRGBl(float3 color)
{
  static const float a = 0.055;
  static const float b = 0.04045;
  return float3(
    color.r <= b ? (color.r / 12.92) : pow((color.r + a) / (1.0 + a), 2.4),
    color.g <= b ? (color.g / 12.92) : pow((color.g + a) / (1.0 + a), 2.4),
    color.b <= b ? (color.b / 12.92) : pow((color.b + a) / (1.0 + a), 2.4)
  );
}

float3 sRGBltosRGB(float3 color)
{
  static const float a = 0.055;
  static const float b = 0.0031308;
  return float3(
    color.r <= b ? (12.92 * color.r) : ((1.0 + a) * pow(color.r, 1.0 / 2.4) - a),
    color.g <= b ? (12.92 * color.g) : ((1.0 + a) * pow(color.g, 1.0 / 2.4) - a),
    color.b <= b ? (12.92 * color.b) : ((1.0 + a) * pow(color.b, 1.0 / 2.4) - a)
  );
}



////////// XYZ SPECIFIC
// XYZ <> xyY | D60 (maybe)
float3 XYZtoxyY(float3 color)
{
  float divider = max(dot(color, float3(1.0, 1.0, 1.0).xxx), DELTA4);
  return float3(color.xy / divider, color.y);
}

float3 xyYtoXYZ(float3 color)
{
  float m = color.z / max(color.y, DELTA4);
  float3 res = float3(color.xz, (1.0 - color.x - color.y));
  res.xz *= m;
  return res;
}

// XYZ <> sRGB | > Rec. 709 primaries
float3 XYZtosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    3.2409699419, -1.5373831776, -0.4986107603,
    -0.9692436363, 1.8759675015, 0.0415550574,
    0.0556300797, -0.2039769589, 1.0569715142
  );
  return mul(mat, color);
}



////////// ACES SPECIFIC
// sRGBl <> ACES2065-1 | Rec. 709 <> AP0 primaries
float3 sRGBltoAP0(float3 color)
{
  static const float3x3 mat = float3x3(
    0.439643004019961, 0.383005471371792, 0.177399308886895,
    0.089715731865361, 0.813475053791709, 0.096782252404812,
    0.017512720476296, 0.111551438549134, 0.870882792975248
  );
  return mul(mat, color);
}

float3 AP0tosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    2.521400888578221, -1.133995749382747, -0.387561856768867,
    -0.276214061561748, 1.372595566304089, -0.096282355736466,
    -0.015320200077479, -0.152992561800699, 1.168387199619315
  );
  return mul(mat, color);
}

// sRGBl <> ACEScg | Rec. 709 <> AP1 primaries
float3 sRGBltoAP1(float3 color)
{
  static const float3x3 mat = float3x3(
    0.613132422390542, 0.339538015799666, 0.047416696048269,
    0.070124380833917, 0.916394011313573, 0.013451523958235,
    0.020587657528185, 0.109574571610682, 0.869785404035327
  );
  return mul(mat, color);
}

float3 AP1tosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    1.704858676289160, -0.621716021885330, -0.083299371729057,
    -0.130076824208823, 1.140735774822504, -0.010559801677511,
    -0.023964072927574, -0.128975508299318, 1.153014018916862
  );
  return mul(mat, color);
}

// XYZ <> ACES2065-1 | XYZ <> AP0 primaries
float3 XYZtoAP0(float3 color)
{
  static const float3x3 mat = float3x3(
    1.0498110175, 0.0000000000, -0.0000974845,
    -0.4959030231, 1.3733130458, 0.0982400361,
    0.0000000000, 0.0000000000, 0.9912520182
  );
  return mul(mat, color);
}

float3 AP0toXYZ(float3 color)
{
  static const float3x3 mat = float3x3(
    0.9525523959, 0.0000000000, 0.0000936786,
    0.3439664498, 0.7281660966, -0.0721325464,
    0.0000000000, 0.0000000000, 1.0088251844
  );
  return mul(mat, color);
}

// XYZ <> ACEScg | XYZ <> AP1 primaries
float3 XYZtoAP1(float3 color)
{
  static const float3x3 mat = float3x3(
    1.6410233797, -0.3248032942, -0.2364246952,
    -0.6636628587, 1.6153315917, 0.0167563477,
    0.0117218943, -0.0082844420, 0.9883948585
  );
  return mul(mat, color);
}

float3 AP1toXYZ(float3 color)
{
  static const float3x3 mat = float3x3(
    0.6624541811, 0.1340042065, 0.1561876870,
    0.2722287168, 0.6740817658, 0.0536895174,
    -0.0055746495, 0.0040607335, 1.0103391003
  );
  return mul(mat, color);
}

// ACES2065-1 <> ACEScg | AP0 <> AP1 primaries
float3 AP0toAP1(float3 color)
{
  static const float3x3 mat = float3x3(
    1.451439316071658, -0.236510746889360, -0.214928569308364,
    -0.076553773314263, 1.176229699811789, -0.099675926450360,
    0.008316148424961, -0.006032449790909, 0.997716301412982
  );
  return mul(mat, color);
}

float3 AP1toAP0(float3 color)
{
  static const float3x3 mat = float3x3(
    0.695452241358567, 0.140678696470730, 0.163869062213569,
    0.044794563352499, 0.859671118442968, 0.095534318210286,
    -0.005525882558111, 0.004025210305977, 1.001500672251631
  );
  return mul(mat, color);
}



////////// WHITE POINT CHANGES
// XYZ D60 <> XYZ D65
float3 D60toD65(float3 color)
{
  static const float3x3 mat = float3x3(
    0.98722400, -0.00611327, 0.0159533,
    -0.00759836, 1.00186000, 0.0053302,
    0.00307257, -0.00509595, 1.0816800
  );
  return mul(mat, color);
}
