////////// D4SCO Debug - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// INCLUDES
#include "d4sco_helpers.fxh"
#include "d4sco_macros.fxh"
#include "ReforgedUI.fxh"



////////// PARAMETERS
#define UI_SEPARATOR_MODE COLON
#define UI_INDENT_MODE INDENT

UI_WHITESPACE(50)

#define UI_CATEGORY Testing
UI_SEPARATOR_CUSTOM("Test Tool Settings")

UI_SPLITTER(51)

// UI_BOOL(bEnableTestTool, "# Show Testing Tool ?", false)
// UI_FLOAT(fPosX, "pos.x Divider", 1.0, 20.0, 1.0)
// UI_FLOAT(fPosXOffset, "pos.x Offset", 0.0, 20.0, 0.0)
// UI_FLOAT(fPosY, "pos.y Divider", 1.0, 20.0, 1.0)
// UI_FLOAT(fPosYOffset, "pos.y Offset", 0.0, 20.0, 0.0)
// UI_FLOAT(fPosZ, "pos.z Divider", 1.0, 10.0, 1.0)
// UI_WHITESPACE(51)
// UI_FLOAT(fScaleX, "Width", -100.0, 100.0, 16.0);
// UI_FLOAT(fPosOutX, "Position on x", 0.0, 1.0, 1.0);
// UI_FLOAT(fScaleY, "Height", -100.0, 100.0, 16.0);
// UI_FLOAT(fPosOutY, "Position on y", 0.0, 1.0, 1.0);
// UI_FLOAT(fAlpha, "res.a", 0.0, 1.0, 1.0);
// UI_WHITESPACE(52)
UI_BOOL(bEnableSplitScreen, "# Show Splitscreen ?", false)
UI_BOOL(bEnableVisualisation, "# Show Inbound Textures ?", false)
UI_BOOL(bEnableCharts, "# Show Charts ?", false)
UI_WHITESPACE(53)
UI_BOOL(bUseHorizontalSplit, "# Use Horizontal Split ?", false)
UI_FLOAT(fSplitScreenDivide, "Split Screen Divide", 0.0, 1.0, 0.5)
UI_WHITESPACE(54)
UI_BOOL(bEnableGammaCorrection, "# Use Gamma Correction ?", false)
UI_FLOAT(fSubWindowsScale, "Visualisation Scale", 1.0, 5.0, 1.0)
UI_FLOAT(fSubWindowsScroll, "Visualisation Scroll", 0.0, 10.0, 0.0)
UI_WHITESPACE(55)
UI_FLOAT(fLineWidth, "Graph Line Width", 1.0, 5.0, 2.5)



////////// SHADERS
// Testing
// void VS_TestTool(inout float4 pos : SV_POSITION, inout float2 txcoord0 : TEXCOORD0)
// {
//   pos = float4(
//     pos.x / fPosX + fPosXOffset / fPosX,
//     pos.y / fPosY - fPosYOffset / fPosY,
//     pos.z / fPosZ,
//     1.0
//   );
// }

// float4 PS_TestTool(float4 pos : SV_POSITION, float2 txcoord0 : TEXCOORD0) : SV_TARGET
// {
//   clip(bEnableTestTool ? 1.0 : -1.0);

//   float invWidth = ScreenSize.y;
//   float invHeight = ScreenSize.z / ScreenSize.x;

//   float r = step(txcoord0.x, fPosOutX + invWidth * fScaleX) * step(fPosOutX - invWidth * fScaleX, txcoord0.x);
//   // float r = rtmp * (txcoord0.x);
//   r *= step(txcoord0.y, fPosOutY + invHeight * fScaleY) * step(fPosOutY - invHeight * fScaleY, txcoord0.y);
//   // float g = gtmp * txcoord0.y;

//   return float4(r * txcoord0.x, r * txcoord0.y, r, fAlpha);
// }

// Shared debug VS
void VS_SubRender(
  inout float4 pos : SV_POSITION,
  inout float2 txcoord0 : TEXCOORD0,
  uniform uint column,
  uniform uint order
)
{
  float divider = 10.0 / fSubWindowsScale;
  float scroll = 1.0 + fSubWindowsScroll;

  pos = float4(
    pos.x / divider + (divider - 1.0 - column * 2.0) / divider,
    pos.y / divider + (scroll * (divider - 1.0) - order * 2.0) / divider,
    pos.z,
    1.0
  );
}

// Visualisation
float4 PS_Visualisation(
  float4 pos : SV_POSITION,
  float2 txcoord0 : TEXCOORD0,
  uniform Texture2D TextureInput,
  uniform bool bIsSingleChannel = false,
  uniform bool bIsLinearInput = false
) : SV_TARGET
{
  clip(bEnableVisualisation ? 1.0 : -1.0);

  float3 color = bIsSingleChannel ?
    TextureInput.Sample(PointSampler, txcoord0.xy).rrr :
    TextureInput.Sample(PointSampler, txcoord0.xy).rgb;
  
  return float4(
    bIsLinearInput && bEnableGammaCorrection ?
      linear2srgb(color) :
      color,
    1.0
  );
}

// Boxgraph
float4 PS_BoxGraph(
  float4 pos : SV_POSITION,
  float2 txcoord0 : TEXCOORD0,
  uniform Texture2D TextureInput,
  uniform bool bIsSingleChannel = false,
  uniform bool bIsLinearInput = false,
  uniform bool bIsHorizontal = false
) : SV_TARGET
{
  clip(bEnableCharts ? 1.0 : -1.0);

  float invWidth = ScreenSize.y;
  float invHeight = ScreenSize.z / ScreenSize.x;

  float3 color = bIsSingleChannel ?
    TextureInput.Sample(PointSampler, txcoord0.xy).rrr :
    TextureInput.Sample(PointSampler, txcoord0.xy).rgb;
  if (bIsLinearInput && bEnableGammaCorrection) color = linear2srgb(color);
  float col = max3(color);
  
  float3 res = step(
    bIsHorizontal ? txcoord0.y : txcoord0.x, col + (bIsHorizontal ? invHeight : invWidth) * fLineWidth
  ) * step(
    col - (bIsHorizontal ? invHeight : invWidth) * fLineWidth, bIsHorizontal ? txcoord0.y : txcoord0.x
  );

  return float4(res, 1.0);
}

// Split-screen
float4 PS_SplitScreen(
  float4 pos : SV_POSITION,
  float2 txcoord0 : TEXCOORD0,
  uniform Texture2D TextureInput
) : SV_TARGET
{
  float testcoord = bUseHorizontalSplit ? txcoord0.y : txcoord0.x;
  clip(bEnableSplitScreen && testcoord < fSplitScreenDivide ? 1.0 : -1.0);

  return float4(
    TextureInput.Sample(PointSampler, txcoord0.xy).rgb,
    1.0
  );
}


////////// PASSES
// #define PASS_DEBUG_TEST PASS(p10, VS_TestTool(), PS_TestTool())

#define PASS_SPLITSCREEN(NAME, TEXTURE) \
  PASS(NAME, VS_Basic(), PS_SplitScreen(TEXTURE))
#define PASS_VISUALISATION(NAME, ORDER, TEXTURE, SCHANNEL, LINEAR) \
  PASS(NAME, VS_SubRender(0, ORDER), PS_Visualisation(TEXTURE, SCHANNEL, LINEAR))
#define PASS_BOXGRAPH(NAME, ORDER, TEXTURE, SCHANNEL, LINEAR, HORIZONTAL) \
  PASS(NAME, VS_SubRender(1, ORDER), PS_BoxGraph(TEXTURE, SCHANNEL, LINEAR, HORIZONTAL))
