// ----------------------------------------------------------------------------------------------------------
// ColorLab by the sandvich maker
//
// permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// the software is provided "as is" and the author disclaims all warranties with regard to this software
// including all implied warranties of merchantability and fitness. in no event shall the author be liable
// for any special, direct, indirect, or consequential damages or any damages whatsoever resulting from loss
// of use, data or profits, whether in an action of contract, negligence or other tortious action, arising
// out of or in connection with the use or performance of this software.
// ----------------------------------------------------------------------------------------------------------



// note:
// this shader has a dither built in for output, however the input into this shader has already been 
// truncated from RGBA16F, to RGB10A2, as is noted by Boris's comment on TextureOriginal. 
// please consider taking the dither function from this shader, and run it at the end of your enbeffect.fx 
// at a bit depth of 10, for maximum image quality.


// step function to use for the split range effect
// possible options:
//   linearstep 
//   smoothstep
#define SPLIT_RANGE_STEP_FUNCTION smoothstep



// ----------------------------------------------------------------------------------------------------------
// time of day parameter settings
// ----------------------------------------------------------------------------------------------------------

// note:
// these defines represent various ui options available in the enb menu. change them to any of the following
// options to have separate parameters for different times of day and/or locations:

// SINGLE (it's just the one parameter)
// EI (exterior: single, interior: single)
// DNI / DN_I (exterior: day/night, interior: single)
// DNE_DNI (exterior: day/night, interior: day/night)
// TODI / TOD_I (exterior: dawn/sunrise/day/dusk/sunset/night, interior: single)
// TODE_DNI (exterior: dawn/sunrise/day/dusk/sunset/night, interior: day/night)
// TODE_TODI (exterior: dawn/sunrise/day/dusk/sunset/night, interior: dawn/sunrise/day/dusk/sunset/night)


#define PARAM_SHADOWS_DEADZONE      SINGLE
#define PARAM_SHADOWS_CUTOFF        SINGLE
#define PARAM_HIGHLIGHTS_DEADZONE   SINGLE
#define PARAM_HIGHLIGHTS_CUTOFF     SINGLE

#define PARAM_SHADOWS_COLOR         EI
#define PARAM_MIDTONES_COLOR        EI
#define PARAM_HIGHLIGHTS_COLOR      EI

#define PARAM_HIGHLIGHTS_ROLLOFF    SINGLE 

#define PARAM_SHADOWS_SATURATION    SINGLE
#define PARAM_MIDTONES_SATURATION   SINGLE
#define PARAM_HIGHLIGHTS_SATURATION SINGLE

#define PARAM_SPLIT_TONE_INTENSITY  SINGLE

#define PARAM_RED_SATURATION        SINGLE
#define PARAM_ORANGE_SATURATION     SINGLE
#define PARAM_YELLOW_SATURATION     SINGLE
#define PARAM_GREEN_SATURATION      SINGLE
#define PARAM_CYAN_SATURATION       SINGLE
#define PARAM_BLUE_SATURATION       SINGLE
#define PARAM_MAGENTA_SATURATION    SINGLE

#define PARAM_RED_HUE               SINGLE
#define PARAM_ORANGE_HUE            SINGLE
#define PARAM_YELLOW_HUE            SINGLE
#define PARAM_GREEN_HUE             SINGLE
#define PARAM_CYAN_HUE              SINGLE
#define PARAM_BLUE_HUE              SINGLE
#define PARAM_MAGENTA_HUE           SINGLE

#define PARAM_SATURATION            EI
#define PARAM_COLOR_TEMPERATURE     EI
#define PARAM_HUE_SHIFT             EI

#define PARAM_BLACK_LEVEL           SINGLE
#define PARAM_WHITE_LEVEL           SINGLE
#define PARAM_CONTRAST              EI
#define PARAM_CONTRAST_MIDPOINT     EI
#define PARAM_GAMMA                 EI

#define PARAM_LIFT_RED              SINGLE
#define PARAM_LIFT_GREEN            SINGLE
#define PARAM_LIFT_BLUE             SINGLE

#define PARAM_GAMMA_RED             SINGLE
#define PARAM_GAMMA_GREEN           SINGLE
#define PARAM_GAMMA_BLUE            SINGLE

#define PARAM_GAIN_RED              SINGLE
#define PARAM_GAIN_GREEN            SINGLE
#define PARAM_GAIN_BLUE             SINGLE

#define PARAM_LGG_INTENSITY         EI



// ----------------------------------------------------------------------------------------------------------
// enb external parameters
// ----------------------------------------------------------------------------------------------------------
float4 Timer, ScreenSize, TimeOfDay1, TimeOfDay2;
float  ENightDayFactor, EInteriorFactor;
float4 tempF1, tempF2, tempF3, tempInfo1, tempInfo2;



// ----------------------------------------------------------------------------------------------------------
// constants
// ----------------------------------------------------------------------------------------------------------
// static const float PI = 3.1415926535;
// static const float rPI = 1.0 / PI;
static const float2 PixSize = float2(ScreenSize.y, ScreenSize.y * ScreenSize.z);
static const float2 Resolution = float2(ScreenSize.x, ScreenSize.x * ScreenSize.w);

#define TO_STRING(x) #x
#define MERGE(x, y) x##y



// ----------------------------------------------------------------------------------------------------------
// includes
// ----------------------------------------------------------------------------------------------------------
#include "ColorLab/ReforgedUI.fxh"
#include "D4SCO/colorspaces.fxh"
#include "D4SCO/helpers.fxh"
#include "ColorLab/graphing.fxh"



// ----------------------------------------------------------------------------------------------------------
// ui
// ----------------------------------------------------------------------------------------------------------
#define UI_SEPARATOR_MODE COLON
#define UI_INDENT_MODE INDENT

#define UI_CATEGORY Credits 
UI_SPLITTER(1)
UI_MESSAGE(Credits0, "ColorLab")
UI_MESSAGE(Credits1, "by The Sandvich Maker")
UI_SPLITTER(2)

UI_WHITESPACE(1)

UI_MESSAGE(General, "Other:")
UI_BOOL(InputIsSRGB, "Input is sRGB", true)
UI_BOOL(OutputAsSRGB, "Output as sRGB", true)
UI_INT(LutSize, "LUT Size", 1, 2, 2)

UI_WHITESPACE(2)

#define UI_CATEGORY SplitTone
UI_SEPARATOR_CUSTOM("Split Tone")

UI_FLOAT_MULTI(PARAM_SHADOWS_DEADZONE, ShadowsDeadzone, "Shadows: Deadzone", 0.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_SHADOWS_CUTOFF, ShadowsCutoff, "Shadows: Cutoff", 0.0, 1.0, 0.5)
UI_FLOAT_MULTI(PARAM_HIGHLIGHTS_DEADZONE, HighlightsDeadzone, "Highlights: Deadzone", 0.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_HIGHLIGHTS_CUTOFF, HighlightsCutoff, "Highlights: Cutoff", 0.0, 1.0, 0.5)

UI_WHITESPACE(3)

UI_COLOR_MULTI(PARAM_SHADOWS_COLOR, ShadowsColor, "Shadows: Color", 1.0, 1.0, 1.0)
UI_COLOR_MULTI(PARAM_MIDTONES_COLOR, MidtonesColor, "Midtones: Color", 1.0, 1.0, 1.0)
UI_COLOR_MULTI(PARAM_HIGHLIGHTS_COLOR, HighlightsColor, "Highlights: Color", 1.0, 1.0, 1.0)

UI_WHITESPACE(4)

UI_FLOAT_MULTI(PARAM_HIGHLIGHTS_ROLLOFF, HighlightsRolloff, "Highlights: Rolloff", 0.0, 1.0, 0.75)

UI_WHITESPACE(5)

UI_FLOAT_MULTI(PARAM_SHADOWS_SATURATION, ShadowsSaturation, "Shadows: Saturation", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_MIDTONES_SATURATION, MidtonesSaturation, "Midtones: Saturation", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_HIGHLIGHTS_SATURATION, HighlightsSaturation, "Highlights: Saturation", 0.0, 4.0, 1.0)

UI_WHITESPACE(6)

UI_BOOL(VisualizeSplitTone, "Split Tone Heatmap", false)
UI_FLOAT_MULTI(PARAM_SPLIT_TONE_INTENSITY, SplitToneIntensity, "Split Tone: Effect Intensity", 0.0, 4.0, 0.0)

UI_WHITESPACE(7)

#define UI_CATEGORY HuePalette
UI_SEPARATOR_CUSTOM("Hue Palette")

UI_FLOAT_MULTI(PARAM_RED_SATURATION, RedSaturation, "Red: Saturation", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_ORANGE_SATURATION, OrangeSaturation, "Orange: Saturation", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_YELLOW_SATURATION, YellowSaturation, "Yellow: Saturation", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_GREEN_SATURATION, GreenSaturation, "Green: Saturation", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_CYAN_SATURATION, CyanSaturation, "Cyan: Saturation", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_BLUE_SATURATION, BlueSaturation, "Blue: Saturation", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_MAGENTA_SATURATION, MagentaSaturation, "Magenta: Saturation", 0.0, 4.0, 1.0)

UI_WHITESPACE(8)

UI_FLOAT_MULTI(PARAM_RED_HUE, RedHue, "Red: Hue Shift", -1.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_ORANGE_HUE, OrangeHue, "Orange: Hue Shift", -1.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_YELLOW_HUE, YellowHue, "Yellow: Hue Shift", -1.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_GREEN_HUE, GreenHue, "Green: Hue Shift", -1.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_CYAN_HUE, CyanHue, "Cyan: Hue Shift", -1.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_BLUE_HUE, BlueHue, "Blue: Hue Shift", -1.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_MAGENTA_HUE, MagentaHue, "Magenta: Hue Shift", -1.0, 1.0, 0.0)

UI_WHITESPACE(9)

#define UI_CATEGORY ColorCorrection
UI_SEPARATOR_CUSTOM("Color Correction")

UI_FLOAT_MULTI(PARAM_SATURATION, Saturation, "Saturation", 0.0, 4.0, 1.0)
UI_INT_MULTI(PARAM_COLOR_TEMPERATURE, ColorTemperature, "Color Temperature (default: 6504K)", 4000, 25000, 6504)
UI_FLOAT_MULTI(PARAM_HUE_SHIFT, HueShift, "Hue Shift", -1.0, 1.0, 0.0)

UI_WHITESPACE(10)

#define UI_CATEGORY Curves
UI_SEPARATOR

UI_FLOAT_MULTI(PARAM_BLACK_LEVEL, BlackPoint, "Black Level", -1.0, 1.0, 0.0)
UI_FLOAT_MULTI(PARAM_WHITE_LEVEL, WhitePoint, "White Level", 0.0, 2.0, 1.0)
UI_FLOAT_MULTI(PARAM_CONTRAST, Contrast, "Contrast", 0.0, 4.0, 1.0)
UI_FLOAT_MULTI(PARAM_CONTRAST_MIDPOINT, ContrastMidpoint, "Contrast Midpoint", 0.0, 1.0, 0.5)
UI_FLOAT_MULTI(PARAM_GAMMA, Gamma, "Gamma", 0.25, 4.0, 1.0)

UI_WHITESPACE(11)

UI_MESSAGE(LiftGammaGain, "Lift/Gamma/Gain:")
UI_FLOAT_FINE_MULTI(PARAM_LIFT_RED, LiftRed,       "Lift:          Cyan       <> Red", -1.0, 1.0, 0.0, 0.001)
UI_FLOAT_FINE_MULTI(PARAM_LIFT_GREEN, LiftGreen,   "Lift:          Magenta <> Green", -1.0, 1.0, 0.0, 0.001)
UI_FLOAT_FINE_MULTI(PARAM_LIFT_BLUE, LiftBlue,     "Lift:          Yellow    <> Blue", -1.0, 1.0, 0.0, 0.001)

UI_FLOAT_FINE_MULTI(PARAM_GAMMA_RED, GammaRed,     "Gamma:   Cyan       <> Red", -1.0, 1.0, 0.0, 0.001)
UI_FLOAT_FINE_MULTI(PARAM_GAMMA_GREEN, GammaGreen, "Gamma:   Magenta <> Green", -1.0, 1.0, 0.0, 0.001)
UI_FLOAT_FINE_MULTI(PARAM_GAMMA_BLUE, GammaBlue,   "Gamma:   Yellow    <> Blue", -1.0, 1.0, 0.0, 0.001)

UI_FLOAT_FINE_MULTI(PARAM_GAIN_RED, GainRed,       "Gain:        Cyan       <> Red", -1.0, 1.0, 0.0, 0.001)
UI_FLOAT_FINE_MULTI(PARAM_GAIN_GREEN, GainGreen,   "Gain:        Magenta <> Green", -1.0, 1.0, 0.0, 0.001)
UI_FLOAT_FINE_MULTI(PARAM_GAIN_BLUE, GainBlue,     "Gain:        Yellow    <> Blue", -1.0, 1.0, 0.0, 0.001)

UI_WHITESPACE(12)

UI_FLOAT_MULTI(PARAM_LGG_INTENSITY, LiftGammaGainIntensity, "Lift/Gamma/Gain: Effect Intensity", 0.0, 4.0, 1.0)

UI_WHITESPACE(13)

#define UI_CATEGORY Tonemapping
UI_SEPARATOR

UI_BOOL(TonemappingMode, "Use Tonemapping Reprocess", false)

UI_FLOAT(TonemappingDesaturation, "Pre-TM Desaturation", 0.0, 1.0, 0.7)
UI_FLOAT(TonemappingHueShift, "Allowed Hue-Shift", 0.0, 1.0, 0.4)
UI_FLOAT(TonemappingResaturation, "Post-TM Saturation", 0.0, 1.0, 0.3)
UI_FLOAT(TonemappingSaturation, "ICTCP Saturation", 0.0, 2.0, 1.0)

UI_WHITESPACE(14)

#define UI_CATEGORY Grain
UI_SEPARATOR

UI_BOOL(GrainEnable, "Use Grain", false)

UI_FLOAT(GrainStrength, "Strength", 0.0, 0.5, 0.1)
UI_FLOAT(GrainSaturation, "Saturation", 0.0, 0.5, 0.1)
UI_FLOAT(GrainMotion, "Motion", 0.0, 0.5, 0.1)

UI_WHITESPACE(15)

#define UI_CATEGORY Oversaturation
UI_SEPARATOR

UI_BOOL(OSEnable, "Clamp Brightness", false)

UI_FLOAT(OSCurve, "Curve", 0.0, 10.0, 5.0)
UI_FLOAT(OSAmount, "Dampening", 0.0, 500.0, 100.0)

UI_WHITESPACE(16)

#define UI_CATEGORY Dither
UI_SEPARATOR

UI_BOOL(UseDither, "Use Dither", true)
UI_BOOL(LegacyDither, "Legacy Dither", false)
UI_INT(DitherBitDepth, "Target Bit Depth", 1, 12, 8)



// ----------------------------------------------------------------------------------------------------------
// textures and samplers
// ----------------------------------------------------------------------------------------------------------
Texture2D TextureOriginal; // color R10B10G10A2 32 bit ldr format
Texture2D TextureColor; // color which is output of previous technique (except when drawed to temporary render target), R10B10G10A2 32 bit ldr format
Texture2D TextureDepth; // scene depth R32F 32 bit hdr format

// temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D RenderTargetRGBA32; // R8G8B8A8 32 bit ldr format
Texture2D RenderTargetRGBA64; // R16B16G16A16 64 bit ldr format
Texture2D RenderTargetRGBA64F; // R16B16G16A16F 64 bit hdr format
Texture2D RenderTargetR16F; // R16F 16 bit hdr format with red channel only
Texture2D RenderTargetR32F; // R32F 32 bit hdr format with red channel only
Texture2D RenderTargetRGB32F; // 32 bit hdr format without alpha
#define RT(x) RenderTarget##x


SamplerState Sampler0
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};


SamplerState  Sampler1
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};



// ----------------------------------------------------------------------------------------------------------
// structs
// ----------------------------------------------------------------------------------------------------------
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



// ----------------------------------------------------------------------------------------------------------
// vertex shader
// ----------------------------------------------------------------------------------------------------------
VS_OUTPUT_POST VS_Quad(VS_INPUT_POST IN)
{
    VS_OUTPUT_POST OUT;
    OUT.pos = float4(IN.pos.xyz, 1.0);
    OUT.txcoord0.xy = IN.txcoord.xy;
    return OUT;
}



// ----------------------------------------------------------------------------------------------------------
// common functions
// ----------------------------------------------------------------------------------------------------------
#define remap(v, a, b) (((v) - (a)) / ((b) - (a)))
#define linearstep(a, b, v) saturate(remap(v, a, b))
#define min2(v) min(v.x, v.y)
#define max2(v) max(v.x, v.y)
#define min3(v) min(v.x, min(v.y, v.z))
#define max3(v) max(v.x, max(v.y, v.z))
#define min4(v) min(min(min(v.x, v.y), v.z), v.w)
#define max4(v) max(max(max(v.x, v.y), v.z), v.w)
float smin(float a, float b, float k)
{
    float h = max(k-abs(a-b), 0.0) / k;
    return min(a,b) - h*h*k*(1.0/4.0);
}
float3 smin(float3 a, float3 b, float k)
{
    return float3(
        smin(a.x, b.x, k),
        smin(a.y, b.y, k),
        smin(a.z, b.z, k)
    );
}



// ----------------------------------------------------------------------------------------------------------
// dither functions
// ----------------------------------------------------------------------------------------------------------
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


float3 whiteNoiseDither(float3 color, float2 co, const uint3 bit_depth = 8)
{
    const float3 lsb = exp2(bit_depth)-1.0;
    float3 uni = integerHash3(uint3(co.xy, Timer.z));
    float3 tri = uni - integerHash3(uint3(co.xy, (Timer.z - 1))); 
    return color + mapTriNoise(color, uni - 0.5, tri, lsb) * rcp(lsb);
}


float floatHash1(float2 uv)
{
    float2 noise = frac(sin(dot(uv, float2(12.9898, 78.233) * 2.0)) * 43758.5453);
    return (noise.x + noise.y) * 0.5;
}

float rand(float x) { return frac(x * 0.024390243); }
float permute(float x) { return ((34.0 * x + 1.0) * x) % 289.0; }
// this dither doesn't use Timer.z, which is only available in the most recent ENBs for Skyrim: SE and FO4
float3 legacyWhiteNoiseDither(float3 color, float2 uv, const uint3 bit_depth = 8)
{
    const float3 lsb = exp2(bit_depth)-1.0;

    float3 m = float3(uv, floatHash1(uv + Timer.x)) + 1.0;
    float h = permute(permute(permute(m.x) + m.y) + m.z);

    float3 noise1, noise2;
    noise1.x = rand(h); h = permute(h);
    noise2.x = rand(h); h = permute(h);
    noise1.y = rand(h); h = permute(h);
    noise2.y = rand(h); h = permute(h);
    noise1.z = rand(h); h = permute(h);
    noise2.z = rand(h);

    return color + mapTriNoise(color, noise1 - 0.5, noise1 - noise2, lsb) * rcp(lsb);
}


float3 quantise(float3 color, const uint3 bit_depth = 8)
{
    const float3 lsb = exp2(bit_depth) - 1.0;
    return round(color * lsb) / lsb;
}


float3 applyDither(float3 color, float2 co, float2 uv)
{
    if (LegacyDither) return legacyWhiteNoiseDither(color, uv, DitherBitDepth);
    else return whiteNoiseDither(color, co, DitherBitDepth);
}



// ----------------------------------------------------------------------------------------------------------
// Other functions
// ----------------------------------------------------------------------------------------------------------
float3 applyGrain(float3 color, float2 coords)
{
    float  GrainTimerSeed    = Timer.x * GrainMotion;
    float2 GrainTexCoordSeed = coords.xy * 1.0f;

    float2 GrainSeed1 = GrainTexCoordSeed + float2(0.0f, GrainTimerSeed);
    float2 GrainSeed2 = GrainTexCoordSeed + float2(GrainTimerSeed, 0.0f);
    float2 GrainSeed3 = GrainTexCoordSeed + float2(GrainTimerSeed, GrainTimerSeed);
    float GrainNoise1 = random(GrainSeed1);
    float GrainNoise2 = random(GrainSeed2);
    float GrainNoise3 = random(GrainSeed3);
    float GrainNoise4 = (GrainNoise1 + GrainNoise2 + GrainNoise3) * 0.333333333f;
    float3 GrainNoise = float3(GrainNoise4, GrainNoise4, GrainNoise4);
    float3 GrainColor = float3(GrainNoise1, GrainNoise2, GrainNoise3);

    color += (lerp(GrainNoise, GrainColor, GrainSaturation) * GrainStrength) - (GrainStrength * 0.5f);
    return color;
}



// ----------------------------------------------------------------------------------------------------------
// ColorLab functions
// ----------------------------------------------------------------------------------------------------------
float3 neutralLut(float2 uv, float2 size)
{
    // based on code by Marty McFly
    float3 lut;
    lut.rgb  = uv.xyx / size.y;
    lut.rg   = frac(lut.rg) - 0.5 / size.y;
    lut.rg  /= 1.0 - 1.0 / size.y;
    lut.b    = floor(lut.b) / (size.y - 1);
    return lut;
}


float3 splitRanges(float luma, float lo1, float lo2, float hi1, float hi2)
{
    float3 res;

    float2 lo = float2(lo1, lo2);
    float2 hi = float2(hi1, hi2);

    hi.x = 1.0 - hi.x;

    hi.y = clamp(hi.y, lo.x, hi.x-1e-6);
    lo.y = clamp(lo.y, lo.x+1e-6, hi.x);

    res.x = SPLIT_RANGE_STEP_FUNCTION(lo.y, lo.x, luma);
    res.y = SPLIT_RANGE_STEP_FUNCTION(lo.x, lo.y, luma) - SPLIT_RANGE_STEP_FUNCTION(hi.y, hi.x, luma);
    res.z = SPLIT_RANGE_STEP_FUNCTION(hi.y, hi.x, luma);

    return saturate(res);
}


float2 huePalette(float hue)
{
    hue *= 6.0;

    float2 weights[7] = {
        float2(RedHue, RedSaturation),
        float2(OrangeHue, OrangeSaturation),
        float2(YellowHue, YellowSaturation),
        float2(GreenHue, GreenSaturation),
        float2(CyanHue, CyanSaturation),
        float2(BlueHue, BlueSaturation),
        float2(MagentaHue, MagentaSaturation)
    };

    float dist[7];
    dist[0] = min(hue * 2.0, abs(6.0-hue));
    dist[1] = abs(0.5-hue) * 2.0;
    dist[2] = abs(1.0-hue) * 2.0;
    dist[3] = max(0.0, 1.5-hue) * 2.0 + max(0.0, hue-2.0); 
    dist[4] = abs(3.0-hue);
    dist[5] = abs(4.0-hue);
    dist[6] = abs(5.0-hue);

    float2 palette = 0.0;
    for (uint i = 0; i < 7; i++)
    {
        float x = saturate(1.0 - dist[i]);
        palette += weights[i] * x*x*(3.0 - 2.0*x);
    }

    palette.x /= 6.0;

    return palette;
}


float3 liftGammaGain(float3 color)
{
    float3 lift = float3(LiftRed, LiftGreen, LiftBlue) * LiftGammaGainIntensity - BlackPoint;
    float3 gamma = Gamma - float3(GammaRed, GammaGreen, GammaBlue) * LiftGammaGainIntensity;
    float3 gain = float3(GainRed, GainGreen, GainBlue) * LiftGammaGainIntensity + (1.0-WhitePoint);

    color.xyz = pow(color.xyz, gamma);
    color.xyz = (color.xyz + lift) / (1.0-gain + lift);

    return color;
}


float3 sigmoidContrast(float3 color, float contrast, float mid)
{
    color = saturate(color);
    contrast = 1.0 + (contrast-1.0) * 2.0;
    return color < mid ?
        mid * pow(rcp(mid) * color, contrast) :
        1.0 - (1.0-mid) * pow(rcp(1.0-mid) - rcp(1.0-mid) * color, contrast);
}


float3 linContrast(float3 color, float contrast, float mid)
{
    return max(0.0, mid + (color-mid) * contrast);
}


float3 applyContrast(float3 color)
{
    return Contrast < 1.0 ? 
        linContrast(color, Contrast, ContrastMidpoint) : 
        sigmoidContrast(color, Contrast, ContrastMidpoint);
}


// https://www.shadertoy.com/view/MtdBz7
float3 calculateWhiteXYZ(float x, float y)
{
    return float3(x, y, 1.0-x-y) / y;
}


float3 temperatureToXYZ(float temp)
{
    float x = dot(lerp(
        float4(0.244063, 99.11, 2967800.0, -4607000000.0),
        float4(0.23704, 247.48, 1901800.0, -2006400000.0),
        temp > 7000.0
    ) / float4(1.0, temp, temp*temp, temp*temp*temp), 1.0);
    return calculateWhiteXYZ(x, -3.0*x*x + 2.87*x - 0.275);
}


// linear in --> sRGB out
float3 applyColorLab(float3 color)
{
    float luma = calculateLuma(color.xyz);
    float L = rgb2cielab(color.xyz).x;

    float3 split_weights = splitRanges(sqrt(luma), ShadowsDeadzone, ShadowsCutoff, HighlightsDeadzone, HighlightsCutoff);
    float saturation = Saturation * dot(split_weights, float3(ShadowsSaturation, MidtonesSaturation, HighlightsSaturation));

    if (SplitToneIntensity > 0.0)
    {
        float3 tone = mul(split_weights, float3x3(ShadowsColor, MidtonesColor, HighlightsColor));
        float intensity = SplitToneIntensity * SPLIT_RANGE_STEP_FUNCTION(1.0, HighlightsRolloff, luma);
        color.xyz = lerp(color.xyz, color.xyz * tone, intensity);
    }

    color.xyz = rgb2hsv(color.xyz);

    float2 palette = huePalette(color.x);
    color.x = frac(color.x + HueShift * 0.5 + palette.x);

    color.xyz = rgb2cielab(hsv2rgb(color.xyz));

    color.x = L;
    color.yz *= saturation * palette.y;

    if (ColorTemperature == 6504)
    {
        color.xyz = cielab2rgb(color.xyz);
    }
    else 
    {
        color.xyz  = xyz2lms(cielab2xyz(color.xyz));
        color.xyz *= xyz2lms(temperatureToXYZ(ColorTemperature));
        color.xyz  = lms2rgb(color.xyz);
    }

    color.xyz = linear2srgb(color.xyz);

    color.xyz = liftGammaGain(color.xyz);
    color.xyz = applyContrast(color.xyz);

    if (VisualizeSplitTone)
    {
        color.zyx = sqrt(split_weights);
    }

    return color;
}


float3 applyColorLabWithTM(float3 color) 
{
    float3 ictcp = rgb2ictcp(color.xyz);
    float saturation = pow(smoothstep(1.0, 1.0 - TonemappingDesaturation, ictcp.x), 1.3);
    color.xyz = ictcp2rgb(ictcp * float3(1.0, saturation.xx));
    float3 perChannel = applyColorLab(color.xyz);
    float peak = max(color.x, max(color.y, color.z));
    color.xyz *= rcp(peak + 1e-6); color.xyz *= applyColorLab(peak);
    color.xyz = lerp(color.xyz, perChannel, TonemappingHueShift);
    color.xyz = rgb2ictcp(color.xyz);
    float saturationBoost = TonemappingResaturation * smoothstep(1.0, 0.5, ictcp.x);
    color.yz = lerp(color.yz, ictcp.yz * color.x / max(1e-3, ictcp.x), saturationBoost);
    color.yz *= TonemappingSaturation;
    color.xyz = ictcp2rgb(color.xyz);
    return color; 
}


// ----------------------------------------------------------------------------------------------------------
// pixel shaders
// ----------------------------------------------------------------------------------------------------------
float4 PS_ColorLab(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
    float2 uv = IN.txcoord0.xy;
    float4 color = TextureColor.Load(int3(v0.xy, 0));

    if (InputIsSRGB) color.xyz = srgb2linear(color.xyz);

    if (TonemappingMode) color.xyz = applyColorLabWithTM(color.xyz);
    else color.xyz = applyColorLab(color.xyz);

    if (OSEnable) color.xyz = (color.xyz * (1.0 + color.xyz / OSAmount)) / (color.xyz + OSCurve);

    if (UseDither) color.xyz = applyDither(color.xyz, v0.xy, uv);
    if (DitherBitDepth < 8) color.xyz = quantise(color.xyz, DitherBitDepth);

    if (!OutputAsSRGB) color.xyz = srgb2linear(color.xyz);

    if (GrainEnable) color.xyz = applyGrain(color.xyz, IN.txcoord0.xy);

    color.w = 1.0;
    return saturate(color);
}


static const float2 LutRes = float2(256*LutSize*LutSize, 16*LutSize);
float4 PS_ColorLab_GenerateLUT(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target 
{
    clip(LutRes - v0.xy);

    float3 lut = srgb2linear(neutralLut(v0.xy, LutRes));
    if (TonemappingMode) lut = applyColorLabWithTM(lut);
    else lut = applyColorLab(lut);

    return float4(lut, 1.0);
}


float4 PS_ColorLab_ApplyLUT(VS_OUTPUT_POST IN, float4 v0 : SV_Position0, uniform Texture2D lutTex) : SV_Target 
{
    float2 uv = IN.txcoord0.xy;
    float4 color = TextureOriginal.Load(int3(v0.xy, 0));

    if (!InputIsSRGB) color.rgb = linear2srgb(color.rgb);

    float2 lut_pixsize = 1.0/LutRes;
    float4 lut_uv;

    // based on code by kingeric1992
    color.rgb   = saturate(color.rgb) * (LutRes.y-1.0);
    lut_uv.w    = floor(color.b);
    lut_uv.xy   = (color.rg + 0.5) * lut_pixsize;
    lut_uv.x   += lut_uv.w * lut_pixsize.y;
    lut_uv.z    = lut_uv.x + lut_pixsize.y;
    lut_uv.xyz *= (LutRes.xyx / Resolution.xyx);

    float3 lut = lerp(
        lutTex.Sample(Sampler1, lut_uv.xy).rgb,
        lutTex.Sample(Sampler1, lut_uv.zy).rgb,
        color.b - lut_uv.w
    );

    color.xyz = lut;

    if (OSEnable) color.xyz = (color.xyz * (1.0 + color.xyz / OSAmount)) / (color.xyz + OSCurve);

    if (UseDither) color.rgb = applyDither(color.rgb, v0.xy, uv);
    if (DitherBitDepth < 8) color.xyz = quantise(color.xyz, DitherBitDepth);

    if (!OutputAsSRGB) color.xyz = srgb2linear(color.xyz);

    if (GrainEnable) color.xyz = applyGrain(color.xyz, IN.txcoord0.xy);

    return color;
}


float4 PS_ColorLabGraphs(VS_OUTPUT_POST IN, float4 v0 : SV_Position0, uniform bool showLut, uniform Texture2D lutTex) : SV_Target 
{
    float2 uv = IN.txcoord0.xy;
    float4 color = TextureColor.Load(int3(v0.xy, 0));

    color.xyz = srgb2linear(color.xyz);
    color.w = 1.0;

    float shadow = 0.75;
    float offset = 8.0;
    float2 graphSize = float2(0.3, 0.2) * Resolution;
    float2 graphPos = float2(Resolution.x - graphSize.x - offset, offset);

    // split tone graph
    {
        GraphStruct g = graphNew(graphPos, graphSize, v0.xy, float2(8, 4));
        float3 split_weights = splitRanges(g.uv.x, ShadowsDeadzone, ShadowsCutoff, HighlightsDeadzone, HighlightsCutoff);

        float3 c1, c2, c3;
        if (VisualizeSplitTone)
        {
            c1 = float3(0.0, 0.0, 1.0);
            c2 = float3(0.0, 1.0, 0.0);
            c3 = float3(1.0, 0.0, 0.0);
        }
        else 
        {
            c1 = ShadowsColor;
            c2 = MidtonesColor;
            c3 = HighlightsColor;
        }

        float3 tone = mul(split_weights, float3x3(c1, c2, c3));
        float saturation = dot(split_weights, float3(ShadowsSaturation, MidtonesSaturation, HighlightsSaturation));
        float rolloff = SPLIT_RANGE_STEP_FUNCTION(1.0, HighlightsRolloff, g.uv.x);

        split_weights = split_weights * 0.75 + 0.25;

        float3 m = (g.uv.y < split_weights);
        g.background_color.xyz = any(m) ? mul(m, float3x3(c1, c2, c3)) * 0.5 : tone * 0.25;

        tone = lerp(1.0, tone, rolloff * SplitToneIntensity);
        float3 gradient = g.uv.x * g.uv.x * tone;

        g.background_color = g.uv.y < 0.25 ? float4(gradient, 1.0) : float4(g.background_color.rgb, 0.9);
        g.background_color.rgb = lerp(calculateLuma(g.background_color.rgb), g.background_color.rgb, saturation);
        g.drop_shadow = shadow;

        graphAddPlot(g, split_weights.x, c1);
        graphAddPlot(g, split_weights.y, c2);
        graphAddPlot(g, split_weights.z, c3);

        graphDraw(g, color);

        graphPos.y += graphSize.y + offset;
    }

    // hue palette graph
    {
        graphSize.y *= 0.5;

        GraphStruct g = graphNew(graphPos, graphSize, v0.xy, 0);
        float2 palette = huePalette(g.uv.x);
        float3 rainbow = hue2rgb(frac(g.uv.x + palette.x + HueShift * 0.5));
        float sat = Saturation * palette.y;
        rainbow = rgb2cielchab(rainbow);
        rainbow.y *= sat * 0.5;
        rainbow = cielchab2rgb(rainbow);

        g.background_color.rgb = rainbow;
        g.drop_shadow = shadow;

        rainbow = 1.0-rainbow;
        float f = (palette.y > 1.0 ? (palette.y-1.0)*0.33+1.0 : palette.y)*0.5;
        graphAddPlot(g, f, lerp(calculateLuma(rainbow), rainbow, f));

        graphDraw(g, color);

        graphPos.y += graphSize.y + offset;
        graphSize.y *= 2.0;
    }

    // lift/gamma/gain graph
    {
        GraphStruct g = graphNew(graphPos, graphSize, v0.xy, float2(8, 4));

        float3 f = g.uv.x;

        f = liftGammaGain(f);
        f = applyContrast(f);

        g.drop_shadow = shadow;
        g.background_color.rgb = 0.05;
        g.lines_x_color = 0.05;
        g.lines_y_color = 0.05;

        graphAddPlot(g, f.x, float3(1.0, 0.0, 0.0));
        graphAddPlot(g, f.y, float3(0.0, 1.0, 0.0));
        graphAddPlot(g, f.z, float3(0.0, 0.0, 1.0));

        graphDraw(g, color);

        graphPos.y += graphSize.y + offset;
    }

    // dither graph
    if (UseDither)
    {
        GraphStruct g = graphNew(graphPos, graphSize * float2(1.0, 0.5), v0.xy, 0);

        float lsb = exp2(DitherBitDepth) - 1.0;
        float3 grad = g.uv.x;
        if (g.uv.y < 0.5) grad = applyDither(grad, v0.xy, uv);
        grad = quantise(grad, DitherBitDepth);
        grad = srgb2linear(grad);

        g.drop_shadow = shadow;
        g.background_color.rgb = grad;

        graphDraw(g, color);

        graphPos.y += graphSize.y + offset;
    }

    color.xyz = linear2srgb(color.xyz);

    // lut display
    v0.xy -= Resolution - LutRes;
    if (all(v0.xy > 0.0) && showLut)
    {
        color.rgb = lutTex.Load(int3(v0.xy, 0)).rgb;
    }

    return color;
}



// ----------------------------------------------------------------------------------------------------------
// techniques
// ----------------------------------------------------------------------------------------------------------
#define TECHNIQUE(name, vs, ps) \
    technique11 name \
    { \
        pass p0 \
        { \
            SetVertexShader(CompileShader(vs_5_0, vs)); \
            SetPixelShader(CompileShader(ps_5_0, ps)); \
        } \
    }
#define TECH_NAME(name) string UIName = name
#define TECH_RT(rt) string RenderTarget = TO_STRING(RT(rt))


TECHNIQUE(ColorLab < TECH_NAME("ColorLab"); >, VS_Quad(), PS_ColorLab())

TECHNIQUE(ColorLabGraphs < TECH_NAME("ColorLab w/ Graphs"); >, VS_Quad(), PS_ColorLab())
TECHNIQUE(ColorLabGraphs1, VS_Quad(), PS_ColorLabGraphs(false, RT(RGBA64F)))

TECHNIQUE(ColorLabLUT < TECH_NAME("ColorLab as LUT"); TECH_RT(RGBA64F); >, VS_Quad(), PS_ColorLab_GenerateLUT())
TECHNIQUE(ColorLabLUT1, VS_Quad(), PS_ColorLab_ApplyLUT(RT(RGBA64F)))

TECHNIQUE(ColorLabLUTGraphs < TECH_NAME("ColorLab as LUT w/ Graphs"); TECH_RT(RGBA64F); >, VS_Quad(), PS_ColorLab_GenerateLUT())
TECHNIQUE(ColorLabLUTGraphs1, VS_Quad(), PS_ColorLab_ApplyLUT(RT(RGBA64F)))
TECHNIQUE(ColorLabLUTGraphs2, VS_Quad(), PS_ColorLabGraphs(true, RT(RGBA64F)))