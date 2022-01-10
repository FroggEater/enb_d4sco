////////// D4SCO enbeffect.fx - 1.0
////////// Provided as is by FroggEater
////////// with code/help from :
//////////  - firemanaf (AGCC, tonemapping, effects)
//////////  - The Sandvich Maker (UI macros, dithering, general understanding)
//////////  - Boris Vorontsov (of course)
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates

////////// CONSTANTS & HANDLES
#define remap(v, a, b) (((v) - (a)) / ((b) - (a)))
#define LUM_709 float3(0.2125, 0.7154, 0.0721)

////////// EXTERNAL PARAMETERS
//x = generic timer in range 0..1, period of 16777216 ms (4.6 hours), y = average fps, w = frame time elapsed (in seconds)
float4	Timer;
//x = Width, y = 1/Width, z = aspect, w = 1/aspect, aspect is Width/Height
float4	ScreenSize;
//changes in range 0..1, 0 means full quality, 1 lowest dynamic quality (0.33, 0.66 are limits for quality levels)
float	AdaptiveQuality;
//x = current weather index, y = outgoing weather index, z = weather transition, w = time of the day in 24 standart hours. Weather index is value from weather ini file, for example WEATHER002 means index==2, but index==0 means that weather not captured.
float4	Weather;
//x = dawn, y = sunrise, z = day, w = sunset. Interpolators range from 0..1
float4	TimeOfDay1;
//x = dusk, y = night. Interpolators range from 0..1
float4	TimeOfDay2;
//changes in range 0..1, 0 means that night time, 1 - day time
float	ENightDayFactor;
//changes 0 or 1. 0 means that exterior, 1 - interior
float	EInteriorFactor;
//x = Width, y = 1/Width, z = aspect, w = 1/aspect, aspect is Width/Height
float4	BloomSize;

////////// INCLUDES
#include "D4SCO/ReforgedUI.fxh"
#include "D4SCO/helpers.fxh"

////////// PARAMETERS
#define UI_SEPARATOR_MODE COLON
#define UI_INDENT_MODE INDENT

#define UI_CATEGORY Credits

UI_MESSAGE(Credits0, "D4SCO")
UI_MESSAGE(Credits1, "by FroggEater")
UI_SPLITTER(1)
UI_MESSAGE(Credits2, "with the help of...")
UI_MESSAGE(Credits3, "firemanaf")
UI_MESSAGE(Credits4, "The Sandvich Maker")
UI_MESSAGE(Credits5, "boris")

UI_WHITESPACE(1)

#define UI_CATEGORY Base
UI_SEPARATOR_CUSTOM("Base Image Settings :")

UI_SPLITTER(2)
UI_FLOAT(PARAM_ADAPTATION_BORDER_MIN, "Adaptation (min)", 0.0, 100.0, 0.0)
UI_FLOAT(PARAM_ADAPTATION_BORDER_MAX, "Adaptation (max)", 0.0, 100.0, 50.0)
UI_FLOAT(PARAM_ADAPTATION_DIVIDER_MIN, "Adaptation Divider (min)", 0.0, 1.0, 0.5)
UI_FLOAT(PARAM_ADAPTATION_DIVIDER_MAX, "Adaptation Divider (max)", 0.0, 1.0, 1.0)
UI_WHITESPACE(2)
UI_FLOAT(PARAM_BASE_BRIGHTNESS, "Brightness", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_BASE_CONTRAST, "Contrast", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_BASE_SATURATION, "Saturation", 0.0, 2.0, 1.0)

UI_WHITESPACE(3)

#define UI_CATEGORY Tonemap
UI_SEPARATOR_CUSTOM("Tonemap Settings :")

UI_SPLITTER(3)
UI_BOOL(PARAM_TONEMAP_ENABLE, "Use Frostbyte Tonemap ?", false)
UI_FLOAT(PARAM_TONEMAP_DESAT_TRESHOLD, "Desaturation Treshold", 0.0, 1.0, 0.25)
UI_FLOAT(PARAM_TONEMAP_HS_MULTIPLIER, "Hue-Shift Multiplier", 0.0, 1.0, 0.6)
UI_FLOAT(PARAM_TONEMAP_SAT_MULTIPLIER, "Saturation Multiplier", 0.0, 1.0, 0.3)
UI_FLOAT(PARAM_TONEMAP_GAMMA_FACTOR, "Gamma Factor", 1.0, 3.0, 2.2)

////////// EXTERNAL ENB DEBUGGING PARAMETERS
// Keyboard controlled temporary variables
// Press and hold key 1,2,3...8 together with PageUp or PageDown to modify
// By default all set to 1.0
float4 tempF1; // 0,1,2,3
float4 tempF2; // 5,6,7,8
float4 tempF3; // 9,0
// xy = cursor position in range 0..1 of screen;
// z = is shader editor window active;
// w = mouse buttons with values 0..7 as follows:
//    0 = none
//    1 = left
//    2 = right
//    3 = left+right
//    4 = middle
//    5 = left+middle
//    6 = right+middle
//    7 = left+right+middle (or rather cat is sitting on your mouse)
float4 tempInfo1;
// xy = cursor position of previous left mouse button click
// zw = cursor position of previous right mouse button click
float4 tempInfo2;

////////// GAME PARAMETERS
float4 Params01[7]; // SSE parameters
// x - bloom amount; y - lens amount
float4 ENBParams01; // ENB parameters

////////// SOURCE TEXTURES
Texture2D TextureColor; // HDR color, in multipass mode it's previous pass 32 bit LDR, except when temporary render targets are used
Texture2D TextureBloom; // Vanilla or ENB bloom
Texture2D TextureLens; // ENB lens FX
Texture2D TextureDepth; // Scene depth
Texture2D TextureAdaptation; // Vanilla or ENB adaptation
Texture2D TextureAperture; // This frame aperture 1*1 R32F HDR red channel only. computed in depth of field shader file
// Texture2D TexturePalette; // enbpalette texture, if loaded and enabled in [colorcorrection].

// Textures of multipass techniques
Texture2D TextureOriginal; // Color R16B16G16A16 64 bit HDR format
// Temporary render targets
Texture2D RenderTargetRGBA32; // R8G8B8A8 32 bit LDR format
Texture2D RenderTargetRGBA64; // R16B16G16A16 64 bit LDR format
Texture2D RenderTargetRGBA64F; // R16B16G16A16F 64 bit HDR format
Texture2D RenderTargetR16F; // R16F 16 bit HDR format with red channel only
Texture2D RenderTargetR32F; // R32F 32 bit HDR format with red channel only
Texture2D RenderTargetRGB32F; // 32 bit HDR format without alpha

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

////////// INPUT & OUTPUT
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

////////// TONEMAPPING
float3 applyFrostbyteDisplayMapper(float3 color)
{
	float3 ictcp = rgb2ictcp(color);

	// Desaturation before range compression
	float saturation = pow(smoothstep(1.0, 0.3, ictcp.x), 1.3);
	color = ictcp2rgb(ictcp * float3(1, saturation.xx));

	// Luminance compression treshold, dimmer inputs are not affected
	float treshold = PARAM_TONEMAP_DESAT_TRESHOLD;

	// Hue-preserving remapping
	float mcolor = max(color.r, max(color.g, color.b));
	float mapped = lcompress(mcolor, treshold);
	float3 hpcolor = color * mapped / mcolor;

	// Non hue-preserving remapping
	float3 nhpcolor = lcompress(color, treshold);

	// Mixing hue-preserving color with normal compressed one
	color = lerp(nhpcolor, hpcolor, PARAM_TONEMAP_HS_MULTIPLIER);

	float3 mictcp = rgb2ictcp(color);

	// Smooth ramp-up of the saturation at higher brightness
	float boost = PARAM_TONEMAP_SAT_MULTIPLIER * smoothstep(1.0, 0.5, ictcp.x);

	// Re-introduce some hue from the original color, using previous boost
	mictcp.yz = lerp(mictcp.yz, ictcp.yz * mictcp.x / max(0.001, ictcp.x), boost);

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
	float ENB_BLOOM_AMOUNT = ENBParams01.x;
	float ENB_LENS_AMOUNT = ENBParams01.y;

	// Respectively :
	//  - color the original 64 bits HDR scene color (rgba)
	//	- lens the ENB lens texture (rgb)
	//	- bloom the ENB bloom texture (rgb)
	//	- adaptation the ENB adaptation coefficient
	float4 color = TextureOriginal.Sample(Sampler0, coords.xy).rgba; // HDR scene color
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
	if (PARAM_TONEMAP_ENABLE) color.rgb = applyFrostbyteDisplayMapper(color.rgb);
	color.rgb = gamma(color.rgb, PARAM_TONEMAP_GAMMA_FACTOR);
	res.rgb = saturate(color).rgb;
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
