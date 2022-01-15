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
UI_BOOL(PARAM_BASE_LINEAR_ENABLE, "# Use Linear Color Space ?", true)
UI_BOOL(PARAM_BASE_LIGHTNESS_ENABLE, "# Use Perceptual Lightness ?", true)

UI_WHITESPACE(2)

#define UI_CATEGORY Histogram
UI_SEPARATOR_CUSTOM("Histogram Calculation Settings :")

UI_SPLITTER(4)
UI_FLOAT(PARAM_HIST_BIAS, "0.0000 | Adaptation Bias", -1.0, 1.0, 0.0)
UI_FLOAT(PARAM_HIST_LUM_MIN, "-10.00 | Scene Luminance (min)", -10.0, -5.0, -10.0)
UI_FLOAT(PARAM_HIST_LUM_MAX, "2.5000 | Scene Luminance (max)", 0.0, 5.0, 2.5)
UI_FLOAT(PARAM_HIST_PERCENT_LOW, "0.5000 | Adaptation Low Percent", 0.5, 0.75, 0.5)
UI_FLOAT(PARAM_HIST_PERCENT_HIGH, "0.7500 | Adaptation High Percent", 0.5, 0.75, 0.75)

UI_WHITESPACE(3)



////////// SOURCE TEXTURES
Texture2D TextureCurrent; // 256x256
Texture2D TexturePrevious;



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



////////// COMPUTE
VS_OUTPUT_POST VS_Quad(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;

	OUT.pos = float4(IN.pos.xyz, 1.0);
	OUT.txcoord0.xy = IN.txcoord.xy - 7.0 / 256.0;

	// Return
	return OUT;
}

// Output size is 16x16
// TextureCurrent > 256x256 (internally downscaled)
// Input > R16G16B16A16 or R11G11B10F
// Output > R32F
float4	PS_Downsample(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float ENB_ADAPTATION_SENS = AdaptationParameters.z;

	float res = 0.0;
	float4 coord = float4(IN.txcoord0.xyy, 1.0 / 128.0);

	float lummax = 0.0;

	for (int x = 0; x < 8; x++)
	{
		coord.y = coord.z;

		for (int y = 0; y < 8; y++)
		{
			float4 color = TextureCurrent.Sample(LinearSampler, coord.xy);
			if (PARAM_BASE_LINEAR_ENABLE) color.rgb = srgb2linear(color.rgb);
			float lum = PARAM_BASE_LIGHTNESS_ENABLE ? lightness(color.rgb) : dot(color.rgb, LUM_709);

			lummax = max(lum, lummax);

			res += lerp(lum, lummax, ENB_ADAPTATION_SENS);

			coord.y += coord.w;
		}

		coord.x += coord.w;
	}

	// Return
	return log2(res) - 6.0; // => log2(res / 64.0)
}

// Output size is 1x1
// TextureCurrent > result of current cycle PS_Downsample, so 16x16
// TexturePrevious > result of previous cycle PS_Histogram, so 1x1
// Input and output are both R32F
float4	PS_Histogram(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float ENB_ADAPTATION_TIME = AdaptationParameters.w;

	float4 coord = float4(1.0 / 32.0, 1.0 / 32.0, 1.0 / 32.0, 1.0 / 16.0);

	float4 bin[16];
	for (int k = 0; k < 16; k++)
	{
		bin[k] = float4(0.0, 0.0, 0.0, 0.0);
	}

	[loop]
	for (int i = 0; i < 16; i++)
	{
		coord.y = coord.z;

		[loop]
		for (int j = 0; j < 16; j++)
		{
			float color = TextureCurrent.SampleLevel(PointSampler, coord.xy, 0.0).r;
			float level = saturate((color + (-1.0 * PARAM_HIST_LUM_MIN)) / ((-1.0 * PARAM_HIST_LUM_MIN) + PARAM_HIST_LUM_MAX)) * 63.0; // => [MIN, MAX]

			bin[level * 0.25] += float4(0.0, 1.0, 2.0, 3.0) == float4(trunc(level % 4.0).xxxx);

			coord.y += coord.w;
		}

		coord.x += coord.w;
	}

	// x > high
	// y > low
	float2 anchor = float2(0.5, 0.5);
	float2 accumulate = float2(PARAM_HIST_PERCENT_HIGH - 1.0, PARAM_HIST_PERCENT_LOW - 1.0) * 256.0;

	[loop]
	for (int l = 15; l > 0; l--)
	{
		accumulate += bin[l].w;
		anchor = (accumulate.xy < bin[l].ww) ? l * 4.0 + accumulate.xy / bin[l].ww + 3.0 : anchor;

		accumulate += bin[l].z;
		anchor = (accumulate.xy < bin[l].zz) ? l * 4.0 + accumulate.xy / bin[l].zz + 2.0 : anchor;

		accumulate += bin[l].y;
		anchor = (accumulate.xy < bin[l].yy) ? l * 4.0 + accumulate.xy / bin[l].yy + 1.0 : anchor;

		accumulate += bin[l].x;
		anchor = (accumulate.xy < bin[l].xx) ? l * 4.0 + accumulate.xy / bin[l].xx + 0.0 : anchor;
	}

	float coeff = sum2(anchor.xy) * 0.5 / 63.0 * (-1.0 * PARAM_HIST_LUM_MIN + PARAM_HIST_LUM_MAX) + PARAM_HIST_LUM_MIN;
	coeff = pow(2.0, clamp(coeff, PARAM_HIST_LUM_MIN, PARAM_HIST_LUM_MAX) + PARAM_HIST_BIAS);

	float previous = TexturePrevious.Sample(PointSampler, 0.5).x;
	return lerp(previous, coeff, ENB_ADAPTATION_TIME);
}



////////// TECHNIQUES
// Downscaling and sensitivity computing
technique11 Downsample
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Downsample()));
	}
}

// Mixing everything
technique11 Draw <string UIName="D4SCO - Adaptation";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Histogram()));
	}
}