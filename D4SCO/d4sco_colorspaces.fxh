////////// D4SCO Colorspaces - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates

// Except in specific cases (eg. sRGB to sRGB', or sRGBl as noted here), all colorspaces
// are assumed to be linear, with a final conversion from sRGB to sRGB' having to
// be done at the end for a gamma corrected output.

// All RGB space to RGB space conversions use the Bradford CAT.



////////// INCLUDES
#include "d4sco_helpers.fxh"
#include "d4sco_aces.fxh"



////////// MATRIXES
// sRGB > CIE XYZ > D65 to D60 > AP1 > RRT SAT
static const float3x3 MAT_ACES_INPUT = float3x3(
  0.59719, 0.35458, 0.04823,
  0.07600, 0.90834, 0.01566,
  0.02840, 0.13383, 0.83777
);

// ODT SAT > CIE XYZ > D60 to D65 > sRGB
static const float3x3 MAT_ACES_OUTPUT = float3x3(
  1.60475, -0.53108, -0.07367,
  -0.10208, 1.10813, -0.00605,
  -0.00327, -0.07276, 1.07602
);



////////// CONVERSIONS
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

// sRGBl <> CIE XYZ | D65 | Rec. 709 primaries
float3 sRGBltoCIEXYZ(float3 color)
{
  static const float3x3 mat = float3x3(
    0.4124564, 0.3575761, 0.1804375,
    0.2126729, 0.7151522, 0.0721750,
    0.0193339, 0.1191920, 0.9503041
  );
  return mul(mat, color);
}

float3 CIEXYZtosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    3.2404542, -1.5371385, -0.4985314,
    -0.9692660, 1.8760108, 0.0415560,
    0.0556434, -0.2040259, 1.0572252
  );
  return mul(mat, color);
}

// sRGBl <> ACEScg | D65 | Rec. 709 <> AP1 primaries
float3 sRGBltoACEScg(float3 color)
{
  static const float3x3 mat = float3x3(
    0.6131324224,  0.3395380158,  0.0474166960,
    0.0701243808,  0.9163940113,  0.0134515240,
    0.0205876575,  0.1095745716,  0.8697854040
  );
  return mul(mat, color);
}

float3 ACEScgtosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    1.7048586763, -0.6217160219, -0.0832993717,
    -0.1300768242, 1.1407357748, -0.0105598017,
    -0.0239640729, -0.1289755083, 1.1530140189
  );
  return mul(mat, color);
}

// sRGBl <> ACEScc | D65 | Rec. 709 <> AP1 primaries
float3 sRGBltoACEScc(float3 color)
{
  static const float3x3 mat = float3x3(
    0.6131324224, 0.3395380158, 0.0474166960,
    0.0701243808, 0.9163940113, 0.0134515240,
    0.0205876575, 0.1095745716, 0.8697854040
  );
  return mul(mat, color);
}

float3 ACEScctosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    1.7048586763, -0.6217160219, -0.0832993717,
    -0.1300768242, 1.1407357748, -0.0105598017,
    -0.0239640729, -0.1289755083, 1.1530140189
  );
  return mul(mat, color);
}

// AP0 <> AP1 | D60 | AP0 <> AP1 primaries
float3 AP0toAP1(float3 color)
{
  static const float3x3 mat = float3x3(
    1.4514393161, -0.2365107469, -0.2149285693,
    -0.0765537733, 1.1762296998, -0.0996759265,
    0.0083161484, -0.0060324498, 0.9977163014
  );
  return mul(mat, color);
}

float3 AP1toAP0(float3 color)
{
  static const float3x3 mat = float3x3(
    0.6954522414, 0.1406786965, 0.1638690622,
    0.0447945634, 0.8596711184, 0.0955343182,
    -0.0055258826, 0.0040252103, 1.0015006723
  );
  return mul(mat, color);
}

// AP1 <> XYZ | D60 | From AP1 primaries
float3 AP1toXYZ(float3 color)
{
  static const float3x3 mat = float3x3(
    0.6624541811, 0.1340042065, 0.1561876870,
    0.2722287168, 0.6740817658, 0.0536895174,
    -0.0055746495, 0.0040607335, 1.0103391003
  );
  return mul(mat, color);
}

float3 XYZtoAP1(float3 color)
{
  static const float3x3 mat = float3x3(
    1.6410233797, -0.3248032942, -0.2364246952,
    -0.6636628587, 1.6153315917, 0.0167563477,
    0.0117218943, -0.0082844420, 0.9883948585
  );
  return mul(mat, color);
}

// // AP1 <> Y (XYZ) | D60 | From AP1 primaries
// float3 AP1toY(float3 color)
// {
//   static const float3 v = float3(-0.6636628587, 1.6153315917, 0.0167563477);
//   return mul(v, color);
// }



/////////// FITMENT & TONEMAPPING

///// ACES
float3 applyRRTODT(float3 color)
{
  float3 a = color * (color + 0.0245786) - 0.000090537;
  float3 b = color * (0.983729 * color + 0.4329510) + 0.238081;
  return a / b;
}

// sRGB > sRGB
float3 applyACES(float3 color)
{
  // # Credits to Stephen Hill, MJP and David Neubelt
  // # https://github.com/TheRealMJP/BakingLab/blob/1a043117506ac5b5bcade5c86d808485f3c70b12/BakingLab/ACES.hlsl
  color = mul(MAT_ACES_INPUT, color);
  color = applyRRTODT(color);

  // Return clamped sRGB color
  return saturate(mul(MAT_ACES_OUTPUT, color));
}

// CIE RGB > CIE RGB
float3 applyACESApprox(float3 color)
{
  // # Credits to Krzystof Narkowicz
  // # https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
  static const float a = 2.51;
  static const float b = 0.03;
  static const float c = 2.43;
  static const float d = 0.59;
  static const float e = 0.14;

  // Correct exposure
  color *= 0.6;

  // Return clamped CIE RGB color
  return saturate((color * (a * color + b)) / (color * (c * color + d) + e));
}
