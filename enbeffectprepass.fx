////////// D4SCO Prepass - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// EXTERNAL PARAMETERS
// x > generic timer between 0 and 1, period of 16777216ms (= 4.6h)
// y > average FPS
// w > elapsed frametime (in seconds)
float4 Timer;
// x > width
// y > 1 / width
// z > aspect (= width / height)
// w > 1 / aspect
float4 ScreenSize;
// Quality from highest to lowest between 0 and 1 (0.33 and 0.66 are valid steps)
float	AdaptiveQuality;
// Index from the weather's INI file (eg. WEATHER002 means 2, 0 is not captured)
// x > current weather index
// y > outgoing weather index
// z > weather transition
// w > time of the day in 24h format Weather index is .
float4 Weather;
// All are interpolators between 0 and 1
// x > dawn
// y > sunrise
// z > day
// w > sunset
float4 TimeOfDay1;
// All are interpolators between 0 and 1
// x > dusk
// y > night
float4 TimeOfDay2;
// 0 if it is night time, 1 if it is day time
float	ENightDayFactor;
// 0 if in exterior space, 1 if in interior space
float	EInteriorFactor;



////////// INCLUDES
// Essentials
#include "D4SCO/ReforgedUI.fxh"
#include "D4SCO/d4sco_helpers.fxh"
#include "D4SCO/d4sco_macros.fxh"

// Utilities
#include "D4SCO/d4sco_colorspaces.fxh"
#include "D4SCO/d4sco_aces.fxh"
#include "D4SCO/d4sco_debug.fxh"



////////// GAME PARAMETERS
// SSE parameters
// 3 > x, z, w as contrast, saturation, brightness
// 4 > r, g, b as tint color value, w as tint weight
// 5 > x, y, z as fade color value, w as fade weight (only active during some FX)
float4 Params01[7];

// ENB parameters
float	FieldOfView;



////////// EXTERNAL ENB DEBUGGING PARAMETERS
// Keyboard controlled temporary variables
// Press and hold one of the number keys together with PgUp or PgDown to modify
// By default all set to 1.0
float4 tempF1; // 0, 1, 2, 3
float4 tempF2; // 4, 5, 6, 7
float4 tempF3; // 8, 9
// Mouse controlled temporary variables
// x, y > cursor position on screen, between 0 and 1
// z > shader editor window active
// w > mouse buttons currently pressed with values between 0 and 7 :
//    0 = none
//    1 = left
//    2 = right
//    3 = left + right
//    4 = middle
//    5 = left + middle
//    6 = right + middle
//    7 = left + right + middle
float4 tempInfo1;
// Mouse controlled temporary variables (past)
// x, y > cursor position on screen, between 0 and 1 (last left click)
// z, w > cursor position on screen, between 0 and 1 (last right click)
float4 tempInfo2;



////////// PARAMETERS
#define UI_SEPARATOR_MODE COLON
#define UI_INDENT_MODE INDENT

#define UI_CATEGORY Credits

UI_MESSAGE(Credits0, "D4SCO - Prepass")
UI_MESSAGE(Credits1, "by FroggEater")
UI_MESSAGE(Credits2, "ver. 1.0")
UI_SPLITTER(1)

UI_WHITESPACE(1)

#define UI_CATEGORY ACESPrepass
UI_SEPARATOR_CUSTOM("Prepass ACES Settings")

UI_SPLITTER(2)
UI_FLOAT(fIDTPreExposure, "Pre-IDT Exposure Multiplier", 0.5, 2.0, 1.0)



////////// SOURCE TEXTURES
Texture2D TextureOriginal; // Color R16B16G16A16 64 bit HDR format
Texture2D TextureColor; // HDR color, in multipass mode it's previous pass 32 bit LDR, except when temporary render targets are used
Texture2D TextureDepth; // Scene depth
Texture2D	TextureJitter; // Blue noise
Texture2D	TextureMask; // Alpha channel is mask for skinned objects (less than 1) and amount of SSS

// Textures of multipass techniques
// Temporary render targets
// Texture2D RenderTargetRGBA32; // R8G8B8A8 32 bit LDR format
// Texture2D RenderTargetRGBA64; // R16B16G16A16 64 bit LDR format
// Texture2D RenderTargetRGBA64F; // R16B16G16A16F 64 bit HDR format
// Texture2D RenderTargetR16F; // R16F 16 bit HDR format with red channel only
// Texture2D RenderTargetR32F; // R32F 32 bit HDR format with red channel only
// Texture2D RenderTargetRGB32F; // 32 bit HDR format without alpha



////////// COMPUTE
VS_OUTPUT_POST VS_Prepass(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;
	float4 pos;
	pos.xyz = IN.pos.xyz;
	pos.w = 1.0;
	OUT.pos = pos;
	OUT.txcoord0.xy = IN.txcoord.xy;

	// Return
	return OUT;
}

float4 PS_Prepass(VS_OUTPUT_POST IN, float4 v0 : SV_POSITION0) : SV_TARGET
{
	float4 color = TextureOriginal.Sample(PointSampler, IN.txcoord0.xy);

	// Return
	return float4(applyIDT(color.rgb, fIDTPreExposure), 1.0);
}



////////// TECHNIQUES
technique11 Prepass <string UIName="D4SCO - Prepass";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Prepass()));
		SetPixelShader(CompileShader(ps_5_0, PS_Prepass()));
	}

	PASS_SPLITSCREEN(p5, TextureOriginal)
}
