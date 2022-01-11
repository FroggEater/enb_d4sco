// TODO Replace AGCC parameter clamping by color weighting
////////// D4SCO enbeffect.fx - 1.0
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
// x > width
// y > 1 / width
// z > aspect (= width / height)
// w > 1 / aspect
float4 BloomSize;



////////// INCLUDES
#include "D4SCO/ReforgedUI.fxh"
#include "D4SCO/helpers.fxh"



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
UI_FLOAT(PARAM_ADAPTATION_BORDER_MIN, "0.00 | Adaptation (min)", 0.0, 100.0, 0.0)
UI_FLOAT(PARAM_ADAPTATION_BORDER_MAX, "50.0 | Adaptation (max)", 0.0, 100.0, 50.0)
UI_FLOAT(PARAM_ADAPTATION_DIVIDER_MIN, "0.50 | Adaptation Divider (min)", 0.0, 1.0, 0.5)
UI_FLOAT(PARAM_ADAPTATION_DIVIDER_MAX, "1.00 | Adaptation Divider (max)", 0.0, 1.0, 1.0)
UI_WHITESPACE(2)
UI_FLOAT(PARAM_BASE_BRIGHTNESS, "1.00 | Brightness", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_BASE_CONTRAST, "1.00 | Contrast", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_BASE_SATURATION, "1.00 | Saturation", 0.0, 2.0, 1.0)

UI_WHITESPACE(3)

#define UI_CATEGORY AGCC
UI_SEPARATOR_CUSTOM("AGCC Settings :")

UI_SPLITTER(3)
UI_BOOL(PARAM_AGCC_ENABLE, "# Use AGCC ?", false)
UI_FLOAT(PARAM_AGCC_WEIGHT, "1.00 | AGCC Weight", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_TINT_LIMIT, "1.00 | Game Tint (max)", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_FADE_LIMIT, "1.00 | Game Fade (max)", 0.0, 1.0, 1.0)
UI_WHITESPACE(4)
UI_FLOAT(PARAM_AGCC_EXP_MIN, "0.00 | Game Exposure (min)", 0.0, 1.0, 0.0)
UI_FLOAT(PARAM_AGCC_EXP_MAX, "1.00 | Game Exposure (max)", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_CTR_MIN, "0.00 | Game Contrast (min)", 0.0, 1.0, 0.0)
UI_FLOAT(PARAM_AGCC_CTR_MAX, "1.00 | Game Contrast (max)", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_SAT_MIN, "0.00 | Game Saturation (min)", 0.0, 1.0, 0.0)
UI_FLOAT(PARAM_AGCC_SAT_MAX, "1.00 | Game Saturation (max)", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_AGCC_MIDDLE_GREY, "0.50 | Middle Grey", 0.0, 1.0, 0.5)

UI_WHITESPACE(5)

#define UI_CATEGORY Tonemap
UI_SEPARATOR_CUSTOM("Tonemap Settings :")

UI_SPLITTER(4)
UI_BOOL(PARAM_TONEMAP_PROCESS_ENABLE, "# Use Frostbyte Tonemap Processing ?", false)
UI_FLOAT(PARAM_TONEMAP_COMPRESSION_LBOUND, "0.25 | Compression Lower Bound", 0.0, 1.0, 0.25)
UI_FLOAT(PARAM_TONEMAP_DESAT_AMOUNT, "0.70 | Desaturation Amount", 0.0, 1.0, 0.7)
UI_FLOAT(PARAM_TONEMAP_HS_MULTIPLIER, "0.60 | Hue-Shift Multiplier", 0.0, 1.0, 0.6)
UI_FLOAT(PARAM_TONEMAP_SAT_MULTIPLIER, "0.30 | Saturation Multiplier", 0.0, 1.0, 0.3)
UI_WHITESPACE(6)
UI_BOOL(PARAM_TONEMAP_SECONDARY_ENABLE, "# Use Secondary Tonemap ?", false)
UI_FLOAT(PARAM_TONEMAP_SECONDARY_WHITEPOINT, "5.00 | Whitepoint", 0.0, 5.0, 5.0)
UI_WHITESPACE(7)
UI_BOOL(PARAM_TONEMAP_GAMMA_ENABLE, "# Use Gamma Factor ?", false)
UI_FLOAT(PARAM_TONEMAP_GAMMA_FACTOR, "1.00 | Gamma Factor", 0.0, 2.0, 1.0)



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



////////// SOURCE TEXTURES
Texture2D TextureColor; // HDR color, in multipass mode it's previous pass 32 bit LDR, except when temporary render targets are used
Texture2D TextureBloom; // Vanilla or ENB bloom
Texture2D TextureLens; // ENB lens FX
Texture2D TextureDepth; // Scene depth
Texture2D TextureAdaptation; // Vanilla or ENB adaptation
Texture2D TextureAperture; // This frame aperture 1*1 R32F HDR red channel only. computed in depth of field shader file
// Texture2D TexturePalette; // enbpalette texture, if loaded and enabled in [colorcorrection].

// Textures of multipass techniques
// Texture2D TextureOriginal; // Color R16B16G16A16 64 bit HDR format
// Temporary render targets
// Texture2D RenderTargetRGBA32; // R8G8B8A8 32 bit LDR format
// Texture2D RenderTargetRGBA64; // R16B16G16A16 64 bit LDR format
// Texture2D RenderTargetRGBA64F; // R16B16G16A16F 64 bit HDR format
// Texture2D RenderTargetR16F; // R16F 16 bit HDR format with red channel only
// Texture2D RenderTargetR32F; // R32F 32 bit HDR format with red channel only
// Texture2D RenderTargetRGB32F; // 32 bit HDR format without alpha

SamplerState Sampler0
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Clamp;
	AddressV = Clamp;
};

SamplerState Sampler1
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};



////////// INPUT & OUTPUT STRUCTS
struct VS_INPUT_POST
{
	float3 pos : POSITION;
	float2 txcoord : TEXCOORD0;
};

struct VS_OUTPUT_POST
{
	float4 pos : SV_POSITION;
	float2 txcoord0 : TEXCOORD0;
};



////////// AGCC
float3 applyAGCC(float3 color)
{
	float3 res = color.rgb;
	float grey = dot(color, LUM_709);

	// Game parameters
	float IS_SATURATION = clamp(Params01[3].x, PARAM_AGCC_SAT_MIN, PARAM_AGCC_SAT_MAX);
	float IS_CONTRAST = clamp(Params01[3].z, PARAM_AGCC_CTR_MIN, PARAM_AGCC_CTR_MAX);
	float IS_EXPOSURE = clamp(Params01[3].w, PARAM_AGCC_EXP_MIN, PARAM_AGCC_EXP_MAX);

	float3 GAME_TINT_COLOR = Params01[4].rgb;
	float GAME_TINT_WEIGHT = Params01[4].w;

	float3 GAME_FADE_COLOR = Params01[5].xyz;
	float GAME_FADE_WEIGHT = Params01[5].w;

	// Saturation
	res.rgb = max(lerp(grey, res, IS_SATURATION), 0.0);

	// Logarithmic contrast and exposure
	res.rgb = log2(res.rgb * IS_EXPOSURE + DELTA6);
	res.rgb = max(exp2(lerp(PARAM_AGCC_MIDDLE_GREY, res.rgb, IS_CONTRAST)) - DELTA6, 0.0);

	// Tint and fade
	// Applied after general weighting to better control color settings
	res.rgb = lerp(color.rgb, res.rgb, PARAM_AGCC_WEIGHT);
	res.rgb = lerp(res.rgb, GAME_TINT_COLOR * grey, min(GAME_TINT_WEIGHT, PARAM_AGCC_TINT_LIMIT));
	res.rgb = lerp(res.rgb, GAME_FADE_COLOR, min(GAME_FADE_WEIGHT, PARAM_AGCC_FADE_LIMIT));

	// Return
	return res.rgb;
}



////////// TONEMAPPING
float3 applyTonemap(float3 color, float treshold)
{
	return lcompress(color.rgb, treshold) * rcp(lcompress(PARAM_TONEMAP_SECONDARY_WHITEPOINT, treshold));
}

float3 applyFrostbyteDisplayMapper(float3 color)
{
	float3 ictcp = rgb2ictcp(color);

	// Desaturation before range compression
	float saturation = pow(smoothstep(1.0, 1.0 - PARAM_TONEMAP_DESAT_AMOUNT, ictcp.x), 1.3);
	color.rgb = ictcp2rgb(ictcp * float3(1.0, saturation.xx));

	// Luminance compression treshold, dimmer inputs are not affected
	float treshold = PARAM_TONEMAP_COMPRESSION_LBOUND;

	// Hue-preserving remapping
	float peak = max(color.r, max(color.g, color.b));
	float mapped = PARAM_TONEMAP_SECONDARY_ENABLE ? applyTonemap(peak, treshold) : lcompress(peak, treshold);
	float3 hpcolor = color * mapped / peak;

	// Non hue-preserving remapping
	float3 nhpcolor = PARAM_TONEMAP_SECONDARY_ENABLE ? applyTonemap(color, treshold) : lcompress(color, treshold);

	// Mixing hue-preserving color with normal compressed one
	color = lerp(nhpcolor, hpcolor, PARAM_TONEMAP_HS_MULTIPLIER);

	float3 mictcp = rgb2ictcp(color);

	// Smooth ramp-up of the saturation at higher brightness
	float boost = PARAM_TONEMAP_SAT_MULTIPLIER * smoothstep(1.0, 0.5, ictcp.x);

	// Re-introduce some hue from the original color, using previous boost
	mictcp.yz = lerp(mictcp.yz, ictcp.yz * mictcp.x / max(DELTA3, ictcp.x), boost);

	color = ictcp2rgb(mictcp);
	return color;
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

	// Respectively :
	//  - color the original 64 bits HDR scene color (rgba)
	//	- lens the ENB lens texture (rgb)
	//	- bloom the ENB bloom texture (rgb)
	//	- adaptation the ENB adaptation coefficient
	float4 color = TextureColor.Sample(Sampler0, coords.xy).rgba; // HDR scene color
	float3 lens = TextureLens.Sample(Sampler1, coords.xy).rgb;
	float3 bloom = TextureBloom.Sample(Sampler1, coords.xy).rgb;
	float adaptation = TextureAdaptation.Sample(Sampler0, coords.xy).x;

	bloom.rgb = bloom.rgb - color.rgb;
	bloom.rgb = max(bloom.rgb, 0.0);

	adaptation = clamp(adaptation, PARAM_ADAPTATION_BORDER_MIN, PARAM_ADAPTATION_BORDER_MAX);

	// Mixing
	color.rgb += bloom * ENB_BLOOM_AMOUNT;
	color.rgb += lens * ENB_LENS_AMOUNT;
	color.rgb += color.rgb / (adaptation * PARAM_ADAPTATION_DIVIDER_MAX + PARAM_ADAPTATION_DIVIDER_MIN);

	// Base adjustments
	color.rgb *= PARAM_BASE_BRIGHTNESS;
	color.rgb += 0.00001;

	float3 ncolor = normalize(color.rgb);
	float3 ncoeff = color.rgb / ncolor.rgb;

	ncoeff.rgb = pow(ncoeff.rgb, PARAM_BASE_CONTRAST);
	ncolor.rgb = pow(ncolor.rgb, PARAM_BASE_SATURATION);

	color.rgb = ncoeff.rgb * ncolor.rgb;

	// AGCC
	if (PARAM_AGCC_ENABLE) color.rgb = applyAGCC(color.rgb);

	// Tonemapping
	if (PARAM_TONEMAP_PROCESS_ENABLE) color.rgb = applyFrostbyteDisplayMapper(color.rgb);
	if (PARAM_TONEMAP_GAMMA_ENABLE) color.rgb = gamma(color.rgb, PARAM_TONEMAP_GAMMA_FACTOR);
	res.rgb = saturate(color).rgb;

	// Return
	res.a = 1.0;
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

	color=TextureColor.Sample(Sampler0, IN.txcoord0.xy); //HDR scene color

	float4	r0, r1, r2, r3;
	r1.xy=scaleduv;
	r0.xyz = color.xyz;
	if (0.5<=Params01[0].x) r1.xy=IN.txcoord0.xy;
	r1.xyz = TextureBloom.Sample(Sampler1, r1.xy).xyz;
	r2.xy = TextureAdaptation.Sample(Sampler1, IN.txcoord0.xy).xy; //in skyrimse it two component

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



// technique11 ORIGINALPOSTPROCESS <string UIName="Vanilla";> //do not modify this technique
// {
// 	pass p0
// 	{
// 		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
// 		SetPixelShader(CompileShader(ps_5_0, PS_DrawOriginal()));
// 	}
// }
