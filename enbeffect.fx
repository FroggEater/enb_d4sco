//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries TES Skyrim SE hlsl DX11 format, example post process
// visit http://enbdev.com for updates
// Author: Boris Vorontsov
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
#include "/D4SCO/ReforgedUI.fxh"

////////// PARAMETERS
#define UI_SEPARATOR_MODE COLON
#define UI_INDENT_MODE INDENT

#define UI_CATEGORY Credits

UI_SPLITTER(1)
UI_MESSAGE(Credits0, "D4SCO")
UI_MESSAGE(Credits1, "by FroggEater")
UI_SPLITTER(2)

UI_WHITESPACE(1)

UI_SPLITTER(3)
UI_MESSAGE(Credits2, "with the help of...")
UI_MESSAGE(Credits3, "firemanaf")
UI_MESSAGE(Credits4, "The Sandvich Maker")
UI_MESSAGE(Credits5, "boris")
UI_SPLITTER(4)

UI_WHITESPACE(2)

#define UI_CATEGORY Generals
UI_SEPARATOR_CUSTOM("General settings :")

UI_BOOL(PARAM_USE_AGCC, "Use AGCC ?", false)
UI_BOOL(PARAM_USE_TONEMAP, "Use Tonemap ?", false)

UI_WHITESPACE(3)

#define UI_CATEGORY Image
UI_SEPARATOR_CUSTOM("Image settings :")

UI_FLOAT(PARAM_BRIGHTNESS, "Brightness", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_SATURATION, "Saturation", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_CONTRAST, "Contrast", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_ADAPTATION_MIN, "Adaptation (Min)", 0.0, 2.0, 1.0)
UI_FLOAT(PARAM_ADAPTATION_MAX, "Adaptation (Max)", 0.0, 2.0, 1.0)

UI_WHITESPACE(4)

UI_MESSAGE(TonemappingMessage, "Tonemapping settings :")
UI_FLOAT(PARAM_TONEMAP_CURVE, "Tonemapping Curve", 0.1, 10.0, 1.0)
UI_FLOAT(PARAM_TONEMAP_DAMP, "Tonemapping Dampening", 0.0, 100.0, 1.0)

#define UI_CATEGORY Dither
UI_SEPARATOR_CUSTOM("Dither settings :")

UI_BOOL(PARAM_USE_DITHERING, "Use Dithering ?", false)
UI_INT(PARAM_DITHER_BIT_DEPTH, "Bit Depth", 2, 12, 8)

UI_WHITESPACE(5)

//+++++++++++++++++++++++++++++
//internal parameters, modify or add new
//+++++++++++++++++++++++++++++
//modify these values to tweak various color processing
//POSTPROCESS 1
float	EAdaptationMinV1=0.01;
float	EAdaptationMaxV1=0.07;
float	EContrastV1=0.95;
float	EColorSaturationV1=1.0;
float	EToneMappingCurveV1=6.0;

#ifdef E_CC_PROCEDURAL
//parameters for ldr color correction
float	ECCGamma
<
	string UIName="CC: Gamma";
	string UIWidget="Spinner";
	float UIMin=0.2;//not zero!!!
	float UIMax=5.0;
> = {1.0};

float	ECCInBlack
<
	string UIName="CC: In black";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=1.0;
> = {0.0};

float	ECCInWhite
<
	string UIName="CC: In white";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=1.0;
> = {1.0};

float	ECCOutBlack
<
	string UIName="CC: Out black";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=1.0;
> = {0.0};

float	ECCOutWhite
<
	string UIName="CC: Out white";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=1.0;
> = {1.0};

float	ECCBrightness
<
	string UIName="CC: Brightness";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=10.0;
> = {1.0};

float	ECCContrastGrayLevel
<
	string UIName="CC: Contrast gray level";
	string UIWidget="Spinner";
	float UIMin=0.01;
	float UIMax=0.99;
> = {0.5};

float	ECCContrast
<
	string UIName="CC: Contrast";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=10.0;
> = {1.0};

float	ECCSaturation
<
	string UIName="CC: Saturation";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=10.0;
> = {1.0};

float	ECCDesaturateShadows
<
	string UIName="CC: Desaturate shadows";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=1.0;
> = {0.0};

float3	ECCColorBalanceShadows <
	string UIName="CC: Color balance shadows";
	string UIWidget="Color";
> = {0.5, 0.5, 0.5};

float3	ECCColorBalanceHighlights <
	string UIName="CC: Color balance highlights";
	string UIWidget="Color";
> = {0.5, 0.5, 0.5};

float3	ECCChannelMixerR <
	string UIName="CC: Channel mixer R";
	string UIWidget="Color";
> = {1.0, 0.0, 0.0};

float3	ECCChannelMixerG <
	string UIName="CC: Channel mixer G";
	string UIWidget="Color";
> = {0.0, 1.0, 0.0};

float3	ECCChannelMixerB <
	string UIName="CC: Channel mixer B";
	string UIWidget="Color";
> = {0.0, 0.0, 1.0};
#endif //E_CC_PROCEDURAL

////////// EXTERNAL ENB DEBUGGING PARAMETERS
//keyboard controlled temporary variables. Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4	tempF1; //0,1,2,3
float4	tempF2; //5,6,7,8
float4	tempF3; //9,0
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
float4	tempInfo1;
// xy = cursor position of previous left mouse button click
// zw = cursor position of previous right mouse button click
float4	tempInfo2;

////////// GAME PARAMETERS
float4				Params01[7]; // SSE Parameters
// x - bloom amount; y - lens amount
float4				ENBParams01; //enb parameters

Texture2D			TextureColor; //hdr color, in multipass mode it's previous pass 32 bit ldr, except when temporary render targets are used
Texture2D			TextureBloom; //vanilla or enb bloom
Texture2D			TextureLens; //enb lens fx
Texture2D			TextureDepth; //scene depth
Texture2D			TextureAdaptation; //vanilla or enb adaptation
Texture2D			TextureAperture; //this frame aperture 1*1 R32F hdr red channel only. computed in depth of field shader file
Texture2D			TexturePalette; //enbpalette texture, if loaded and enabled in [colorcorrection].

// Textures of multipass techniques
// Texture2D			TextureOriginal; //color R16B16G16A16 64 bit hdr format
// Temporary render targets
// Texture2D			RenderTargetRGBA32; //R8G8B8A8 32 bit ldr format
// Texture2D			RenderTargetRGBA64; //R16B16G16A16 64 bit ldr format
// Texture2D			RenderTargetRGBA64F; //R16B16G16A16F 64 bit hdr format
// Texture2D			RenderTargetR16F; //R16F 16 bit hdr format with red channel only
// Texture2D			RenderTargetR32F; //R32F 32 bit hdr format with red channel only
// Texture2D			RenderTargetRGB32F; //32 bit hdr format without alpha

SamplerState		Sampler0
{
	Filter = MIN_MAG_MIP_POINT; // MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
SamplerState		Sampler1
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

////////// INPUT & OUTPUT
struct VS_INPUT_POST
{
	float3 pos		: POSITION;
	float2 txcoord	: TEXCOORD0;
};
struct VS_OUTPUT_POST
{
	float4 pos		: SV_POSITION;
	float2 txcoord0	: TEXCOORD0;
};

////////// DITHER FUNCTIONS - credits to Sandvich
float3 mapTriNoise(float3 color, float3 uni, float3 tri, const float3 lsb) {
  const float3 lobit = 0.5 / lsb;
  const float3 hibit = (lsb - 0.5) / lsb;
  float3 lo = saturate(remap(color, 0.0, lobit));
  float3 hi = saturate(remap(color, 1.0, hibit));
  return lerp(uni, tri, min(lo, hi));
}

float3 integerHash3(uint3 x)
{
  static const uint K = 1103515245U;  // GLIB C
  x = ((x >> 8U) ^ x.yzx) * K;
  x = ((x >> 8U) ^ x.yzx) * K;
  x = ((x >> 8U) ^ x.yzx) * K;
  return x * rcp(0xffffffffU);
}

float3 whiteNoiseDither(float3 color, float2 co, const uint3 depth = 8)
{
  const float3 lsb = exp2(depth) - 1.0;
  float3 uni = integerHash3(uint3(co.xy, Timer.z));
  float3 tri = uni - integerHash3(uint3(co.xy, (Timer.z - 1))); 
  return color + mapTriNoise(color, uni - 0.5, tri, lsb) * rcp(lsb);
}

float3 applyDither(float3 color, float2 co)
{
  return whiteNoiseDither(color, co, PARAM_DITHER_BIT_DEPTH);
}

////////// TONEMAP FUNCTIONS - credits to firemanaf
float3 applyFilmicTonemap(float3 color, float W, float A, float B, float C, float D, float E, float F)
{
	float4 res = float4(color.rgb, W);
  res = (res * (A * res + C * B) + D * E) / (res * (A * res + B) + D * F) - (E / F);
  return res.rgb / res.a;
}

float4 applyAGCC(float4 color, float2 coords)
{
	bool scalebloom = (0.5<=Params01[0].x);
  float2 scaleduv = clamp(0.0, Params01[6].zy, Params01[6].xy * coords.xy);
  float4 bloom = TextureBloom.Sample(Sampler1, (scalebloom)? coords.xy: scaleduv); //linear sampler
  float2 middlegray = TextureAdaptation.Sample(Sampler1, coords.xy).xy; //.x == current, .y == previous
  middlegray.y = 1.0; //bypass for enbadaptation format

  float saturation = Params01[3].x;   // 0 == gray scale
  float3 tint = Params01[4].rgb;     	// tint color
	float tint_weight = Params01[4].w;  // 0 == no tint
  float contrast = Params01[3].z;     // 0 == no contrast
  float brightness = Params01[3].w;   // intensity
  float3 fade = Params01[5].xyz;     	// fade current scene to specified color, mostly used in special effects
	float fade_weight = Params01[5].w;  // 0 == no fade

  color.a = dot(color.rgb, LUM_709);                                 // Get luminance
  color.rgb = lerp(color.a, color.rgb, saturation);                  // Saturation
  color.rgb = lerp(color.rgb, color.a * tint.rgb, tint_weight);      // Tint
  color.rgb = lerp(middlegray.x, brightness * color.rgb, contrast);  // Contrast & intensity
  color.rgb = pow(saturate(color.rgb), Params01[6].w);               // Might be unused ?
  color.rgb = lerp(color.rgb, fade, fade_weight);                    // Fade current scene to specified color

	color.a = 1.0;
  color.rgb = saturate(color.rgb);

  return color;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
	float4 color;

	color = TextureColor.Sample(Sampler0, IN.txcoord0.xy); // HDR scene color

	float3 lens;
	lens.xyz = TextureLens.Sample(Sampler1, IN.txcoord0.xy).xyz;
	color.xyz += lens.xyz * ENBParams01.y; // Lens amount

	float3 bloom = TextureBloom.Sample(Sampler1, IN.txcoord0.xy);

	bloom.xyz = bloom-color;
	bloom.xyz = max(bloom, 0.0);
	color.xyz += bloom * ENBParams01.x; // Bloom amount

	float	grayadaptation = TextureAdaptation.Sample(Sampler0, IN.txcoord0.xy).x;

  // Applying AGCC
  if (PARAM_USE_AGCC) color = applyAGCC(color, IN.txcoord0.xy);

  // Mixing
	grayadaptation = max(grayadaptation, 0.0);
	grayadaptation = min(grayadaptation, 50.0);
	color.xyz = color.xyz / (grayadaptation * PARAM_ADAPTATION_MAX + PARAM_ADAPTATION_MIN);

	color.xyz *= (PARAM_BRIGHTNESS);
	color.xyz += 0.000001;
	float3 xncol = normalize(color.xyz);
	float3 scl = color.xyz / xncol.xyz;
	scl = pow(scl, PARAM_CONTRAST);
	xncol.xyz = pow(xncol.xyz, PARAM_SATURATION);
	color.xyz = scl * xncol.xyz;

  // Dampening overall image
	float	lumamax = PARAM_TONEMAP_DAMP;
	color.xyz = (color.xyz * (1.0 + color.xyz / lumamax)) / (color.xyz + PARAM_TONEMAP_CURVE);

#ifdef E_CC_PROCEDURAL
	//activated by UseProceduralCorrection=true
	float	tempgray;
	float4	tempvar;
	float3	tempcolor;

	//+++ levels like in photoshop, including gamma, lightness, additive brightness
	color=max(color-ECCInBlack, 0.0) / max(ECCInWhite-ECCInBlack, 0.0001);
	if (ECCGamma!=1.0) color=pow(color, ECCGamma);
	color=color*(ECCOutWhite-ECCOutBlack) + ECCOutBlack;

	//+++ brightness
	color=color*ECCBrightness;

	//+++ contrast
	color=(color-ECCContrastGrayLevel) * ECCContrast + ECCContrastGrayLevel;

	//+++ saturation
	tempgray=dot(color.xyz, 0.3333);
	color=lerp(tempgray, color, ECCSaturation);

	//+++ desaturate shadows
	tempgray=dot(color.xyz, 0.3333);
	tempvar.x=saturate(1.0-tempgray);
	tempvar.x*=tempvar.x;
	tempvar.x*=tempvar.x;
	color=lerp(color, tempgray, ECCDesaturateShadows*tempvar.x);

	//+++ color balance
	color=saturate(color);
	tempgray=dot(color.xyz, 0.3333);
	float2	shadow_highlight=float2(1.0-tempgray, tempgray);
	shadow_highlight*=shadow_highlight;
	color.rgb+=(ECCColorBalanceHighlights*2.0-1.0)*color * shadow_highlight.x;
	color.rgb+=(ECCColorBalanceShadows*2.0-1.0)*(1.0-color) * shadow_highlight.y;

	//+++ channel mixer
	tempcolor=color;
	color.r=dot(tempcolor, ECCChannelMixerR);
	color.g=dot(tempcolor, ECCChannelMixerG);
	color.b=dot(tempcolor, ECCChannelMixerB);
#endif //E_CC_PROCEDURAL

	if (PARAM_USE_DITHERING) res.xyz = applyDither(color.xyz, v0.xy);
	res.xyz = saturate(color);
	res.w = 1.0;
	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Vanilla post process. Do not modify
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float4	PS_DrawOriginal(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;
	float4	color;

	float2	scaleduv=Params01[6].xy*IN.txcoord0.xy;
	scaleduv=max(scaleduv, 0.0);
	scaleduv=min(scaleduv, Params01[6].zy);

	color=TextureColor.Sample(Sampler0, IN.txcoord0.xy); //hdr scene color

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
	//active only in certain modes, like khajiit vision, otherwise Params01[5].w=0
	r1=Params01[5] - r0;
	res=Params01[5].w * r1 + r0;

//	res.xyz = color.xyz;
//	res.w=1.0;
	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//techniques
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
