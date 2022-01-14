////////// D4SCO Adaptation - 1.0
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
#include "D4SCO/ReforgedUI.fxh"
#include "D4SCO/d4sco_helpers.fxh"



////////// GAME PARAMETERS
// ENB parameters
// x > adaptation minimum
// y > adaptation maximum
// z > adaptation sensitivity
// w > adaptation time multiplied by time elapsed
float4 AdaptationParameters;



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

UI_MESSAGE(Credits0, "D4SCO - Adaptation")
UI_MESSAGE(Credits1, "by FroggEater")
UI_MESSAGE(Credits2, "ver. 1.0")
UI_SPLITTER(1)

UI_WHITESPACE(1)

#define UI_CATEGORY Base
UI_SEPARATOR_CUSTOM("Base Adaptation Settings :")

UI_SPLITTER(2)
UI_BOOL(PARAM_BASE_LINEAR_ENABLE, "# Use Linear Color Space ?", false)

UI_WHITESPACE(2)

#define UI_CATEGORY Luminance
UI_SEPARATOR_CUSTOM("Luminance Calculation Settings :")

UI_SPLITTER(3)
UI_BOOL(PARAM_LUM_COMPLEX_ENABLE, "# Use Complex Luminance ?", false)
UI_FLOAT(PARAM_LUM_NIGHT_WEIGHT, "1.0 | Night Time Weight", 0.0, 1.0, 1.0)
UI_FLOAT(PARAM_LUM_INTERIOR_WEIGHT, "0.5 | Interior Weight", 0.0, 1.0, 0.5)

UI_WHITESPACE(3)



////////// SOURCE TEXTURES
Texture2D TextureCurrent; // 256x256
Texture2D TexturePrevious;

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
// Input
struct VS_INPUT_POST
{
	float3 pos		: POSITION;
	float2 txcoord	: TEXCOORD0;
};

// Output
struct VS_OUTPUT_POST
{
	float4 pos		: SV_POSITION;
	float2 txcoord0	: TEXCOORD0;
};



////////// LUMINANCE CALCULATION
// High ambient luminance
float getPhotoLum(float3 color)
{
	return dot(color.rgb, P_LUM);
}

// Low ambient luminance
float getScotoLum(float3 color)
{
	return dot(color.rgb, S_LUM);
}

float getLuminance(float3 color)
{
	if (!PARAM_LUM_COMPLEX_ENABLE) return dot(color, LUM_709);

	float ENB_NIGHT_DAY_FACTOR = ENightDayFactor;
	float ENB_INTERIOR_FACTOR = EInteriorFactor;

	float3 plum = getPhotoLum(color);
	float3 slum = getScotoLum(color);

	float3 DN_lum = lerp(slum, plum, ENB_NIGHT_DAY_FACTOR * PARAM_LUM_NIGHT_WEIGHT);

	return lerp(DN_lum, slum, ENB_INTERIOR_FACTOR * PARAM_LUM_INTERIOR_WEIGHT);
}

////////// COMPUTE
// offset, so sizeX and sizeY, determines the sampling area (I suppose)
VS_OUTPUT_POST	VS_Quad(VS_INPUT_POST IN, uniform float sizeX, uniform float sizeY)
{
	VS_OUTPUT_POST OUT;
	float4 pos;
	pos.xyz = IN.pos.xyz;
	pos.w = 1.0;
	OUT.pos = pos;

	float2 offset = float2(sizeX, sizeY);
	OUT.txcoord0.xy = IN.txcoord.xy + offset.xy;

	// Return
	return OUT;
}

// Output size is 16x16
// TextureCurrent > 256x256 (internally downscaled)
// Input > R16G16B16A16 or R11G11B10F
// Output > R32F
float4	PS_Downsample(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4 res;

	float ENB_ADAPTATION_SENS = AdaptationParameters.z;

	float target = 16.0;

	// Downsampling 256x256 to 16x16
	// More complex blurring methods will affect the result if sensitivity is uncommented
	float2 pos;
	float2 coord;
	float3 curr;
	float3 currtotal = 0.0;
	float3 currmax = 0.0;
	float3 currmean = 0.0;
	const float	scale = 1.0 / target;
	const float	step = 1.0 / target;
	const float	halfstep = 0.5 / target;

	pos.x = -0.5 + halfstep;
	for (int x=0; x < target; x++)
	{
		pos.y = -0.5 + halfstep;
		for (int y = 0; y < target; y++)
		{
			coord = pos.xy * scale;

			// Corrected into linear space for proper luminance calculation
			curr = TextureCurrent.Sample(Sampler1, IN.txcoord0.xy + coord.xy).rgb;
			if (PARAM_BASE_LINEAR_ENABLE) curr = srgb2linear(curr);
			currmax = max(currmax, curr);
			currtotal += curr;

			pos.y += step;
		}

		pos.x += step;
	}
	// Takes an average of the whole image
	currmean = currtotal / (target * target); 

	res.rgb = lerp(currmean, currmax, ENB_ADAPTATION_SENS).rgb;
	res.rgb = getLuminance(res.rgb);

	// Return
	// Note that res stays in linear space if the conversion is made
	return float4(res.rgb, 1.0);
}

// Output size is 1x1
// TextureCurrent > result of current cycle PS_Downsample, so 16x16
// TexturePrevious > result of previous cycle PS_Adaptation, so 1x1
// Input and output are both R32F
float4	PS_Adaptation(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4 res;

	float ENB_ADAPTATION_SENS = AdaptationParameters.z;
	float ENB_ADAPTATION_TIME = AdaptationParameters.w;
	float ENB_ADAPTATION_MIN = AdaptationParameters.x;
	float ENB_ADAPTATION_MAX = AdaptationParameters.y;

	float	prev = TexturePrevious.Sample(Sampler0, IN.txcoord0.xy).x;
	float target = 16.0;

	// Downsampling 16x16 to 1x1
	float2 pos;
	float curr;
	float currtotal = 0.0;
	float currmax = 0.0;
	float currmean = 0.0;
	const float	step = 1.0 / target;
	const float	halfstep = 0.5 / target;

	pos.x = -0.5 + halfstep;
	for (int x = 0; x < target; x++)
	{
		pos.y = -0.5 + halfstep;
		for (int y = 0; y < target; y++)
		{
			curr = TextureCurrent.Sample(Sampler1, IN.txcoord0.xy + pos.xy).r;
			if (PARAM_BASE_LINEAR_ENABLE) curr = srgb2linear(curr);
			currmax = max(currmax, curr);
			currtotal += curr;

			pos.y += step;
		}

		pos.x += step;
	}
	currmean = currtotal / (target * target);

	// Adjust sensitivity to small areas on the screen
	currmean = lerp(currmean, currmax, ENB_ADAPTATION_SENS);

	// Smoothing by elapsed time
	res = lerp(prev, currmean, ENB_ADAPTATION_TIME);

	// Clamping to avoid bugs in PPFX, which has a much lower floating point precision
	// res = max(res, 0.001);
	// res = min(res, 16384.0);

	// Limit value (if ForceMinMaxValues is true)
	float	valmax = max3(res.rgb);
	float valcut = min(max(valmax, ENB_ADAPTATION_MIN), ENB_ADAPTATION_MAX);
	res *= valcut / (valmax + DELTA9);

	// Return
	// Note that res should still be in linear space if the conversion is made
	return float4(clamp(res.rgb, DELTA3, HDR), 1.0);
}



////////// TECHNIQUES
// Downscaling and sensitivity computing
technique11 Downsample
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad(0.0, 0.0)));
		SetPixelShader(CompileShader(ps_5_0, PS_Downsample()));
	}
}

// Mixing everything
technique11 Draw <string UIName="D4SCO - Adaptation";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad(0.0, 0.0)));
		SetPixelShader(CompileShader(ps_5_0, PS_Adaptation()));
	}
}