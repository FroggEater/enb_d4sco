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


