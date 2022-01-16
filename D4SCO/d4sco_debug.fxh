////////// D4SCO Debug - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// INCLUDES
#include "d4sco_macros.fxh"
#include "d4sco_helpers.fxh"
#include "ReforgedUI.fxh"



////////// PARAMETERS
#define UI_SEPARATOR_MODE COLON
#define UI_INDENT_MODE INDENT

UI_WHITESPACE(50)

#define UI_CATEGORY Testing
UI_SEPARATOR_CUSTOM("Test Tool Settings")

UI_SPLITTER(51)

UI_BOOL(bEnableTestTool, "# Show Testing Tool ?", false)
UI_FLOAT(fPosX, "pos.x Divider", 1.0, 20.0, 1.0)
UI_FLOAT(fPosXOffset, "pos.x Offset", 0.0, 20.0, 0.0)
UI_FLOAT(fPosY, "pos.y Divider", 1.0, 20.0, 1.0)
UI_FLOAT(fPosYOffset, "pos.y Offset", 0.0, 20.0, 0.0)
UI_FLOAT(fPosZ, "pos.z Divider", 1.0, 10.0, 1.0)
UI_WHITESPACE(51)
UI_FLOAT(fScaleX, "Width", -100.0, 100.0, 16.0);
UI_FLOAT(fPosOutX, "Position on x", 0.0, 1.0, 1.0);
UI_FLOAT(fScaleY, "Height", -100.0, 100.0, 16.0);
UI_FLOAT(fPosOutY, "Position on y", 0.0, 1.0, 1.0);
UI_FLOAT(fAlpha, "res.a", 0.0, 1.0, 1.0);
UI_WHITESPACE(52)
UI_BOOL(bEnableVisualisation, "# Show Inbound Textures ?", false)
UI_FLOAT(fVisualisationScale, "Visualisation Scale", 1.0, 5.0, 1.0)
UI_FLOAT(fVisualisationScroll, "Visualisation Scroll", -10.0, 1.0, 1.0)



////////// SHADERS
// Testing
void VS_TestTool(inout float4 pos : SV_POSITION, inout float2 txcoord0 : TEXCOORD0)
{
  pos = float4(
    pos.x / fPosX + fPosXOffset / fPosX,
    pos.y / fPosY - fPosYOffset / fPosY,
    pos.z / fPosZ,
    1.0
  );
}

float4 PS_TestTool(float4 pos : SV_POSITION, float2 txcoord0 : TEXCOORD0) : SV_TARGET
{
  clip(bEnableTestTool ? 1.0 : -1.0);

  float invWidth = ScreenSize.y;
  float invHeight = 1.0 / (ScreenSize.x / ScreenSize.z);

  float r = step(txcoord0.x, fPosOutX + invWidth * fScaleX) * step(fPosOutX - invWidth * fScaleX, txcoord0.x);
  // float r = rtmp * (txcoord0.x);
  r *= step(txcoord0.y, fPosOutY + invHeight * fScaleY) * step(fPosOutY - invHeight * fScaleY, txcoord0.y);
  // float g = gtmp * txcoord0.y;

  return float4(r * txcoord0.x, r * txcoord0.y, r, fAlpha);
}

// Visualisation
void VS_Visualisation(
  inout float4 pos : SV_POSITION,
  inout float2 txcoord0 : TEXCOORD0,
  uniform uint order
)
{
  float divider = 10.0 / fVisualisationScale;
  pos = float4(
    pos.x / divider + (divider - 1.0) / divider,
    pos.y / divider + (fVisualisationScroll * (divider - 1.0) - order * 2.0) / divider,
    pos.z,
    1.0
  );
}

float4 PS_Visualisation(
  float4 pos : SV_POSITION,
  float2 txcoord0: TEXCOORD0,
  uniform Texture2D TextureInput,
  uniform bool bIsSingleChannel
) : SV_TARGET
{
  clip(bEnableVisualisation ? -1.0 : 1.0);
  float3 color = bIsSingleChannel ?
    TextureInput.Sample(PointSampler, txcoord0.xy).rrr :
    TextureInput.Sample(PointSampler, txcoord0.xy).rgb;
  
  return float4(color, 1.0);
}



////////// PASSES
#define PASS_DEBUG_TEST PASS(p10, VS_TestTool(), PS_TestTool())

#define PASS_VISUALISATION(NAME, ORDER, TEXTURE, SCHANNEL) \
  PASS(NAME, VS_Visualisation(ORDER), PS_Visualisation(TEXTURE, SCHANNEL))

#define PASS_VIS_COLOR \
  PASS(p11, VS_Visualisation(0), PS_Visualisation(TextureColor, false))
#define PASS_VIS_ADAPTATION \
  PASS(p12, VS_Visualisation(1), PS_Visualisation(TextureAdaptation, true))