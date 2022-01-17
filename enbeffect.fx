////////// D4SCO Effects - 1.0
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
#include "D4SCO/d4sco_debug.fxh"



////////// GAME PARAMETERS
// SSE parameters
// 3 > x, z, w as contrast, saturation, brightness
// 4 > r, g, b as tint color value, w as tint weight
// 5 > x, y, z as fade color value, w as fade weight (only active during some FX)
float4 Params01[7];

// ENB parameters
// x > bloom amount
// y > lens amount
float4 ENBParams01;
// x > width
// y > 1 / width
// z > aspect (= width / height)
// w > 1 / aspect
float4 BloomSize;



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

UI_MESSAGE(Credits0, "D4SCO - Effects")
UI_MESSAGE(Credits1, "by FroggEater")
UI_MESSAGE(Credits2, "ver. 1.0")
UI_SPLITTER(1)

UI_WHITESPACE(1)

#define UI_CATEGORY Base
UI_SEPARATOR_CUSTOM("Base Image Settings :")

UI_SPLITTER(2)
UI_BOOL(PARAM_BASE_GAMMA_TO_LINEAR_ENABLE, "# Use Linear Color Space ?", false)
UI_BOOL(PARAM_BASE_LINEAR_TO_GAMMA_ENABLE, "# Switch Back To Gamma Color Space ?", false)
UI_WHITESPACE(2)
UI_FLOAT(PARAM_BASE_BRIGHTNESS, "1.00 | Brightness", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_BASE_CONTRAST, "1.00 | Contrast", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_BASE_SATURATION, "1.00 | Saturation", 0.0, 2.0, 1.0)

UI_WHITESPACE(3)

#define UI_CATEGORY AGCC
UI_SEPARATOR_CUSTOM("AGCC Settings :")

UI_SPLITTER(3)
UI_BOOL(PARAM_AGCC_ENABLE, "# Use AGCC ?", false)
UI_BOOL(PARAM_AGCC_LIGHTNESS_ENABLE, "# Use Perceptual Lightness ?", false)
UI_FLOAT(PARAM_AGCC_BRIGHTNESS_WEIGHT, "1.00 | AGCC Exposure Weight", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_CONTRAST_WEIGHT, "1.00 | AGCC Contrast Weight", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_SATURATION_WEIGHT, "1.00 | AGCC Saturation Weight", 0.0, 1.0, 1.0)
UI_WHITESPACE(4)
UI_FLOAT(PARAM_AGCC_TINT_WEIGHT, "1.00 | AGCC Tint Weight", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_FADE_WEIGHT, "1.00 | AGCC Fade Weight", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_MIDDLE_GREY_MULTIPLIER, "1.00 | Middle Grey Multiplier", 0.0, 2.0, 1.0)

UI_WHITESPACE(5)



////////// SOURCE TEXTURES
Texture2D TextureColor; // HDR color, in multipass mode it's previous pass 32 bit LDR, except when temporary render targets are used
Texture2D TextureBloom; // Vanilla or ENB bloom
Texture2D TextureLens; // ENB lens FX
Texture2D TextureDepth; // Scene depth
Texture2D TextureAdaptation; // Vanilla or ENB adaptation, R32F HDR red channel only
Texture2D TextureAperture; // This frame aperture 1*1 R32F HDR red channel only, computed in enbdepthoffield.fx
// Texture2D TexturePalette; // enbpalette texture, if loaded and enabled in [colorcorrection].

// Textures of multipass techniques
Texture2D TextureOriginal; // Color R16B16G16A16 64 bit HDR format
// Temporary render targets
// Texture2D RenderTargetRGBA32; // R8G8B8A8 32 bit LDR format
// Texture2D RenderTargetRGBA64; // R16B16G16A16 64 bit LDR format
// Texture2D RenderTargetRGBA64F; // R16B16G16A16F 64 bit HDR format
// Texture2D RenderTargetR16F; // R16F 16 bit HDR format with red channel only
// Texture2D RenderTargetR32F; // R32F 32 bit HDR format with red channel only
// Texture2D RenderTargetRGB32F; // 32 bit HDR format without alpha



////////// AGCC
// # - Credits to firemanaf and LonelyKitsune for the basis of my changes
float3 applyAGCC(float3 color)
{
	float grey = PARAM_AGCC_LIGHTNESS_ENABLE ? lightness(color) : dot(color, LUM_709) ;
	grey *= PARAM_AGCC_MIDDLE_GREY_MULTIPLIER;

	// Game parameters
	float IS_EXPOSURE = Params01[3].w;
	float IS_CONTRAST = Params01[3].z;
	float IS_SATURATION = Params01[3].x;

	float3 GAME_TINT_COLOR = Params01[4].rgb;
	float GAME_TINT_WEIGHT = Params01[4].w;

	float3 GAME_FADE_COLOR = Params01[5].xyz;
	float GAME_FADE_WEIGHT = Params01[5].w;

	if (PARAM_BASE_GAMMA_TO_LINEAR_ENABLE)
	{
		GAME_TINT_COLOR = sRGBtosRGBl(GAME_TINT_COLOR);
		GAME_FADE_COLOR = sRGBtosRGBl(GAME_FADE_COLOR);
	}

	// Logarithmic contrast and exposure, and saturation weighting
	color.rgb = log2(lerp(color.rgb, color.rgb * IS_EXPOSURE + DELTA6, PARAM_AGCC_BRIGHTNESS_WEIGHT));
	color.rgb = max(lerp(exp2(color.rgb) - DELTA6, exp2(lerp(grey, color.rgb, IS_CONTRAST)) - DELTA6, PARAM_AGCC_CONTRAST_WEIGHT), 0.0);
	color.rgb = lerp(color.rgb, max(lerp(grey, color, IS_SATURATION), 0.0), PARAM_AGCC_SATURATION_WEIGHT);

	// Tint and fade
	// Applied after other weights to allow for better color control
	color.rgb = lerp(color.rgb, GAME_TINT_COLOR * grey, lerp(0.0, GAME_TINT_WEIGHT, PARAM_AGCC_TINT_WEIGHT));
	color.rgb = lerp(color.rgb, GAME_FADE_COLOR, lerp(0.0, GAME_FADE_WEIGHT, PARAM_AGCC_FADE_WEIGHT));

	// Return
	return color.rgb;
}



////////// COMPUTE
VS_OUTPUT_POST VS_Draw(VS_INPUT_POST IN)
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

float4 PS_Draw(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4 res;

	// Pixel coordinates and ENB parameters
	float2 coords = IN.txcoord0.xy;
	float3 pos = IN.pos.xyz;
	float ENB_BLOOM_AMOUNT = ENBParams01.x;
	float ENB_LENS_AMOUNT = ENBParams01.y;

	float4 color = TextureOriginal.Sample(PointSampler, coords.xy).rgba;
	float3 adaptation = TextureAdaptation.Sample(PointSampler, 0.5).rgb;

	if (PARAM_BASE_GAMMA_TO_LINEAR_ENABLE) color.rgb = sRGBtosRGBl(color.rgb);

	// Adaptation
	// float adapt = max3(adaptation);
	// if (adapt > 0.0)
	// {
	// 	if (PARAM_ADAPTATION_EXPOSURE_ENABLE)
	// 	{
	// 		float EV100 = PARAM_CAMERA_AUTOMATIC_EXP_ENABLE ?
	// 			computeLuminanceEV100(adapt) :
	// 			computeEV100();
	// 		float exposure = computeExposureFromEV100(EV100);

	// 		color.rgb *= exposure;
	// 	}
	// 	else
	// 	{
	// 		float3 lowlight = color.rgb * PARAM_ADAPTATION_EXP_MULTIPLIER;
	// 		float3 highlight = color.rgb / PARAM_ADAPTATION_DRK_MULTIPLIER;
	// 		color.rgb = lerp(lowlight, highlight, adapt);
	// 	}
	// 	// color.rgb /= ((adapt + PARAM_ADAPTATION_MID_CUTOFF) * PARAM_ADAPTATION_MULTIPLIER + DELTA6);
	// }

	// Base adjustments
	color.rgb *= PARAM_BASE_BRIGHTNESS;
	color.rgb += DELTA6;

	float3 ncolor = normalize(color.rgb);
	float3 ncoeff = color.rgb / ncolor.rgb;

	ncoeff.rgb = pow(ncoeff.rgb, PARAM_BASE_CONTRAST);
	ncolor.rgb = pow(ncolor.rgb, PARAM_BASE_SATURATION);

	color.rgb = ncoeff.rgb * ncolor.rgb;

	// AGCC
	if (PARAM_AGCC_ENABLE) color.rgb = applyAGCC(color.rgb);

	// Return to sRGB space
	if (PARAM_BASE_LINEAR_TO_GAMMA_ENABLE) color.rgb = sRGBltosRGB(color.rgb);

	// Return
	res = float4(saturate(color).rgb, 1.0);
	return res;
}



////////// VANILLA POST-PROCESS - DO NOT MODIFY
// Identical to the original one
float4 PS_DrawOriginal(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;
	float4	color;

	float2	scaleduv=Params01[6].xy*IN.txcoord0.xy;
	scaleduv=max(scaleduv, 0.0);
	scaleduv=min(scaleduv, Params01[6].zy);

	color=TextureColor.Sample(PointSampler, IN.txcoord0.xy); //HDR scene color

	float4	r0, r1, r2, r3;
	r1.xy=scaleduv;
	r0.xyz = color.xyz;
	if (0.5<=Params01[0].x) r1.xy=IN.txcoord0.xy;
	r1.xyz = TextureBloom.Sample(LinearSampler, r1.xy).xyz;
	r2.xy = TextureAdaptation.Sample(LinearSampler, IN.txcoord0.xy).xy; //in skyrimse it two component

	r0.w=dot(float3(2.125000e-001, 7.154000e-001, 7.210000e-002), r0.xyz);
	r0.w=max(r0.w, 1.000000e-005);
	r1.w=r2.y/r2.x;
	r2.y=r0.w * r1.w;
	if (0.5<Params01[2].z) r2.z=0xffffffff; else r2.z=0;
	r3.xy=r1.w * r0.w + float2(-4.000000e-003, 1.000000e+000);
	r1.w=max(r3.x, 0.0);
	r3.xz=r1.w * 6.2 + float2(5.000000e-001, 1.700000e+000);
	r2.w=r1.w * r3.x;
	r1.w=r1.w * r3.z + 6.000000e-002;
	r1.w=r2.w / r1.w;
	r1.w=pow(r1.w, 2.2);
	r1.w=r1.w * Params01[2].y;
	r2.w=r2.y * Params01[2].y + 1.0;
	r2.y=r2.w * r2.y;
	r2.y=r2.y / r3.y;
	if (r2.z==0) r1.w=r2.y; else r1.w=r1.w;
	r0.w=r1.w / r0.w;
	r1.w=saturate(Params01[2].x - r1.w);
	r1.xyz=r1 * r1.w;
	r0.xyz=r0 * r0.w + r1;
	r1.x=dot(r0.xyz, float3(2.125000e-001, 7.154000e-001, 7.210000e-002));
	r0.w=1.0;
	r0=r0 - r1.x;
	r0=Params01[3].x * r0 + r1.x;
	r1=Params01[4] * r1.x - r0;
	r0=Params01[4].w * r1 + r0;
	r0=Params01[3].w * r0 - r2.x;
	r0=Params01[3].z * r0 + r2.x;
	r0.xyz=saturate(r0);
	r1.xyz=pow(r1.xyz, Params01[6].w);
	// active only in certain modes, like khajiit vision, otherwise Params01[5].w=0
	r1=Params01[5] - r0;
	res=Params01[5].w * r1 + r0;

	// res.xyz = color.xyz;
	// res.w=1.0;
	return res;
}



////////// TECHNIQUES
technique11 Draw <string UIName="D4SCO - Effects";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader(CompileShader(ps_5_0, PS_Draw()));
	}
}

technique11 DrawDebug <string UIName="D4SCO - Debug";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader(CompileShader(ps_5_0, PS_Draw()));
	}

	PASS_SPLITSCREEN(p5, TextureOriginal)

	PASS_VISUALISATION(p11, 0, TextureColor, false, false)
	PASS_VISUALISATION(p12, 1, TextureBloom, false, false)
	PASS_VISUALISATION(p13, 2, TextureAdaptation, true, true)

	PASS_BOXGRAPH(p21, 2, TextureAdaptation, true, true, false)
}

// Do not modify
technique11 ORIGINALPOSTPROCESS <string UIName="D4SCO - Vanilla";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
		SetPixelShader(CompileShader(ps_5_0, PS_DrawOriginal()));
	}
}
