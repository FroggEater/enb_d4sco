// ----------------------------------------------------------------------------------------------------------
// REFORGED BLOOM BY THE SANDVICH MAKER

// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
// OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
// OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ----------------------------------------------------------------------------------------------------------


#define VERSION_NUMBER 1.01


// Turn this off (change the 1 to a 0) once you see this to disable the annoying notice telling you to look
// at this file.
#define ANNOYING_NOTICE 0



// ----------------------------------------------------------------------------------------------------------
// ABOUT AVAILABLE TECHNIQUES:

// GAUSSIAN1:
//  Gaussian1 first fills all the rendertargets with a downsampling filter, then applies gaussian blur to
//  each rendertarget individually. Features additional functionality such as color filters and depth
//  awareness. Layered approach allows for a wide range of control.
//  Wasteful from a performance standpoint (though the performance impact is neglegible on modern hardware in
//  the first place), but allows for more predictable control of individual texture filtering because
//  every filter size is independent of each other.

// GAUSSIAN2:
//  Gaussian2 progressively fills all the rendertargets, taking the previous gaussian blur as input for the
//  next one (the same as DX9 ENB Gaussian blooms and UE4 bloom). Has the same functionality as Gaussian1.
//  Better option from an efficiency standpoint, slightly more unwieldy to control compared to Gaussian1
//  because every filter size is added up to the one that comes after it.

// PROGRESSIVE1024:
//  Approximates a gaussian blur by progressively downsampling the 1024x1024 texture all the way down to the
//  lowest specified mip level (4 = 64x64, 5 = 32x32, 6 = 16x16) and then progressively upsampling from that.
//  Only allows for one level of detail in the bloom, is cheap and smooth but lacking in features, and
//  misses the point of the method used a bit by not using mips of the full screen res (but you can blame
//  ENB for making that so hard).
// ----------------------------------------------------------------------------------------------------------



// ----------------------------------------------------------------------------------------------------------
// PRE-PROCESSOR USER-EDITABLES
// ----------------------------------------------------------------------------------------------------------
// GENERIC EDITABLES
// disable the bloom you don't want to use for a cleaner UI
#define INCLUDE_GAUSSIAN_BLOOM 1
#define INCLUDE_PROGRESSIVE_BLOOM 0
// the max threshold selectable in the UI
#define UI_MAX_THRESHOLD 2.0
// 0: Hide threshold controls (and as a result disable thresholding)
// 1: Threshold Center + Threshold Softness
// 2: Threshold Min + Threshold Max
#define UI_THRESHOLD_STYLE 2


// GAUSSIAN BLOOM EDITABLES
// add depth awareness controls
#define GAUSSIAN_DEPTH_AWARENESS 1
// add blend weight controls for the texture combine
#define GAUSSIAN_TEXTURE_BLEND_WEIGHTS 0
// add per-texture tint controls
#define GAUSSIAN_TEXTURE_TINTS 0
// add filter size controls for each individual texture
#define GAUSSIAN_TEXTURE_FILTER_SIZES 0
// change the min and max selectable filter sizes in the UI
#define GAUSSIAN_MIN_FILTER_SIZE 5
#define GAUSSIAN_MAX_FILTER_SIZE 20


// PROGRESSIVE BLOOM EDITABLES
// whether to show individual filter size controls
#define PROGRESSIVE_INDIVIDUAL_FILTER_SIZE_CONTROLS 0
// the lowest resolution texture to downsample to before upsampling (affects bloom radius and to some extent quality)
#define PROGRESSIVE_LOWEST_MIP 6 // Valid range: [4,6]


// POSTPASS EDITABLES
// whether to include color correction
#define POSTPASS_CC 0
// whether to include lens dirt feature
#define INCLUDE_LENS_DIRT 0
// lens dirt texture
#define LENS_DIRT_TEXTURE "BloomLensMask.png"



// ----------------------------------------------------------------------------------------------------------
// UI MULTIPARAMETER OPTIONS
// These defines represent various UI options available in the ENB menu. Change them to any of the following
// options to have separate parameters for different times of day and/or locations:

// SINGLE (it's just the one parameter)
// EI (Exterior: Single, Interior: Single)
// DNI / DN_I (Exterior: Day/Night, Interior: Single)
// DNE_DNI (Exterior: Day/Night, Interior: Day/Night)
// TODI / TOD_I (Exterior: Dawn/Sunrise/Day/Dusk/Sunset/Night, Interior: Single)
// TODE_DNI (Exterior: Dawn/Sunrise/Day/Dusk/Sunset/Night, Interior: Day/Night)
// TODE_TODI (Exterior: Dawn/Sunrise/Day/Dusk/Sunset/Night, Interior: Dawn/Sunrise/Day/Dusk/Sunset/Night)

// But avoid setting boolean and integer parameters to anything other than SINGLE and EI to avoid jarring
// transitions between states.
// Also note that the overhead for using a lot of complex interpolators that are required for options like
// the TOD ones is not free, so try to hold back using them too much unless you really need them.
// ----------------------------------------------------------------------------------------------------------
// Prepass
#define UI_SKYFADE                    SINGLE
#define UI_USE_THRESHOLD              SINGLE // Boolean parameter
#define UI_THRESHOLD_VALUES           DNI
#define UI_TONEMAP_INPUT              SINGLE // Boolean parameter

// Gaussian
#define UI_FOREGROUND_DOMINANCE       DNI
#define UI_FOREGROUND_DOMINANCE_CLAMP DNI
#define UI_FAR_RADIUS_MULTIPLIER      DNI

#define UI_TEXTURE_BLENDWEIGHT1       SINGLE // 512x512
#define UI_TEXTURE_BLENDWEIGHT2       SINGLE // 256x256
#define UI_TEXTURE_BLENDWEIGHT3       SINGLE // 128x128
#define UI_TEXTURE_BLENDWEIGHT4       SINGLE // 64x64
#define UI_TEXTURE_BLENDWEIGHT5       SINGLE // 32x32
#define UI_TEXTURE_BLENDWEIGHT6       SINGLE // 16x16

#define UI_TEXTURE_TINT1              SINGLE // 512x512
#define UI_TEXTURE_TINT2              SINGLE // 256x256
#define UI_TEXTURE_TINT3              SINGLE // 128x128
#define UI_TEXTURE_TINT4              SINGLE // 64x64
#define UI_TEXTURE_TINT5              SINGLE // 32x32
#define UI_TEXTURE_TINT6              SINGLE // 16x16
#define UI_COUNTERBALANCE_TINT        SINGLE

// Progressive
#define UI_PROGRESSIVE_FILTER_RADIUS  SINGLE

// Postpass
#define UI_INVERSE_TONEMAP            SINGLE // Boolean parameter
#define UI_MULTIPLIER                 SINGLE
#define UI_POST_TINT                  SINGLE
#define UI_SATURATION                 SINGLE
#define UI_DESATURATION               SINGLE
#define UI_DESATURATION_CURVE         SINGLE
#define UI_GAMMA                      SINGLE
#define UI_LENS_DIRT_AMOUNT           SINGLE



// ----------------------------------------------------------------------------------------------------------
// VV SHADER STARTS HERES VV
// ----------------------------------------------------------------------------------------------------------
#define REFORGED_HLSL_5 1
#define REFORGED_INCLUDE_FILTERS 1


#include "Reforged/common.fxh"



// ----------------------------------------------------------------------------------------------------------
// EXTERNAL PARAMETERS¹
// ----------------------------------------------------------------------------------------------------------
// x = generic timer in range 0..1, period of 16777216 ms (4.6 hours), y = average fps, w = frame time elapsed (in seconds)
float4 Timer;
// x = Width, y = 1/Width, z = aspect, w = 1/aspect, aspect is Width/Height
float4 ScreenSize;
// changes in range 0..1, 0 means full quality, 1 lowest dynamic quality (0.33, 0.66 are limits for quality levels)
float AdaptiveQuality;
// x = current weather index, y = outgoing weather index, z = weather transition, w = time of the day in 24 standart hours. Weather index is value from weather ini file, for example WEATHER002 means index==2, but index==0 means that weather not captured.
float4 Weather;
// x = dawn, y = sunrise, z = day, w = sunset. Interpolators range from 0..1
float4 TimeOfDay1;
// x = dusk, y = night. Interpolators range from 0..1
float4 TimeOfDay2;
// changes in range 0..1, 0 means that night time, 1 - day time
float ENightDayFactor;
// changes 0 or 1. 0 means that exterior, 1 - interior
float EInteriorFactor;



// ----------------------------------------------------------------------------------------------------------
// CONSTS
// ----------------------------------------------------------------------------------------------------------
static const float2 PixSize = float2(ScreenSize.y, ScreenSize.y * ScreenSize.z);



// ----------------------------------------------------------------------------------------------------------
// ENB UI
// ----------------------------------------------------------------------------------------------------------
// ¹: macros.fxh has to be included after external parameters have been defined.
#include "Reforged/macros.fxh"


#define UI_VAR_PREFIX_MODE NO_PREFIX


#define UI_CATEGORY Credits
UI_SEPARATOR_CUSTOM(MERGE("Reforged Bloom ", TO_STRING(VERSION_NUMBER)))
UI_MESSAGE(Credits1, "by The Sandvich Maker")
UI_WHITESPACE(12)


#if ANNOYING_NOTICE
    UI_MESSAGE(Annoying1, "\xBB Please configure this shader to your needs")
    UI_MESSAGE(Annoying2, "\xBB by opening enbbloom.fx and editing the")
    UI_MESSAGE(Annoying3, "\xBB available user-editable settings.")
    UI_MESSAGE(Annoying4, "\xBB This notice can be disabled too.")

    UI_WHITESPACE(1)
#endif


#define UI_CATEGORY Prepass
UI_SEPARATOR
UI_BOOL(DiscardBorder, "Discard OOB Samples", true)
UI_FLOAT_MULTI(UI_SKYFADE, SkyFade, "Sky Fade", 0.0, 1.0, 0.0)
#if UI_THRESHOLD_STYLE > 0
    UI_BOOL_MULTI(UI_USE_THRESHOLD, UseThreshold, "Use Threshold", false)
    UI_INT(ThresholdStyle, "Threshold Style", 0, 2, 0)
    UI_INT(ThresholdLuma, "Threshold Luma Style", 0, 2, 1)
    #if UI_THRESHOLD_STYLE == 1
        UI_FLOAT_MULTI(UI_THRESHOLD_VALUES, Threshold, "Threshold", 0.0, UI_MAX_THRESHOLD, 0.5)
        UI_FLOAT_MULTI(UI_THRESHOLD_VALUES, ThresholdSmoothness, "Threshold Softness", 0.0, UI_MAX_THRESHOLD, 0.5)
    #else
        UI_FLOAT_MULTI(UI_THRESHOLD_VALUES, ThresholdMin, "Threshold Min", 0.0, UI_MAX_THRESHOLD, 0.25)
        UI_FLOAT_MULTI(UI_THRESHOLD_VALUES, ThresholdMax, "Threshold Max", 0.0, UI_MAX_THRESHOLD, 0.75)
    #endif
#endif
UI_FLOAT(PreSaturation, "Pre-Saturation", 0.0, 4.0, 1.0)
UI_BOOL_MULTI(UI_TONEMAP_INPUT, TonemapPrepass, "Tonemap Input", false)


// Gaussian Bloom UI Parameters
#if INCLUDE_GAUSSIAN_BLOOM
    UI_WHITESPACE(3)

    #define UI_CATEGORY Gaussian
    UI_SEPARATOR_CUSTOM("Gaussian Bloom")

    #if GAUSSIAN_DEPTH_AWARENESS
        #define UI_CATEGORY Depth
        UI_FLOAT_MULTI(UI_FOREGROUND_DOMINANCE, GaussianDepthAwareness, "Foreground Dominance", 0.0, 1.0, 0.0)
        UI_FLOAT_MULTI(UI_FOREGROUND_DOMINANCE_CLAMP, GaussianDepthAwarenessClamp, "Foreground Dominance Clamp", 0.0, 1.0, 0.0)
        UI_FLOAT_MULTI(UI_FAR_RADIUS_MULTIPLIER, GaussianFarRadius, "Far Radius Multiplier", 0.0, 1.0, 1.0)

        UI_WHITESPACE(4)
    #endif

    #define UI_CATEGORY Gaussian
    UI_BOOL(UseGaussianTex1, "Use 512x512 Texture", true)
    UI_BOOL(UseGaussianTex2, "Use 256x256 Texture", true)
    UI_BOOL(UseGaussianTex3, "Use 128x128 Texture", true)
    UI_BOOL(UseGaussianTex4, "Use 64x64 Texture", true)
    UI_BOOL(UseGaussianTex5, "Use 32x32 Texture", true)
    UI_BOOL(UseGaussianTex6, "Use 16x16 Texture", true)

    UI_WHITESPACE(5)

    UI_INT(GaussianQuality, "Filter Quality", -2, 2, 0)
    #if GAUSSIAN_TEXTURE_FILTER_SIZES
        UI_INT(GaussianFilterSize1, "Filter Size 512x512", GAUSSIAN_MIN_FILTER_SIZE, GAUSSIAN_MAX_FILTER_SIZE, 6)
        UI_INT(GaussianFilterSize2, "Filter Size 256x256", GAUSSIAN_MIN_FILTER_SIZE, GAUSSIAN_MAX_FILTER_SIZE, 6)
        UI_INT(GaussianFilterSize3, "Filter Size 128x128", GAUSSIAN_MIN_FILTER_SIZE, GAUSSIAN_MAX_FILTER_SIZE, 6)
        UI_INT(GaussianFilterSize4, "Filter Size 64x64", GAUSSIAN_MIN_FILTER_SIZE, GAUSSIAN_MAX_FILTER_SIZE, 6)
        UI_INT(GaussianFilterSize5, "Filter Size 32x32", GAUSSIAN_MIN_FILTER_SIZE, GAUSSIAN_MAX_FILTER_SIZE, 6)
        UI_INT(GaussianFilterSize6, "Filter Size 16x16", GAUSSIAN_MIN_FILTER_SIZE, GAUSSIAN_MAX_FILTER_SIZE, 6)
    #else
        UI_INT(GaussianFilterSize, "Filter Size", GAUSSIAN_MIN_FILTER_SIZE, GAUSSIAN_MAX_FILTER_SIZE, 6)
    #endif

    #if GAUSSIAN_TEXTURE_BLEND_WEIGHTS
        UI_WHITESPACE(6)

        UI_BOOL(GaussianApplyWeights, "Apply Weights", true)
        UI_FLOAT_MULTI(UI_TEXTURE_BLENDWEIGHT1, GaussianTexWeight1, "512x512 Texture Blend Weight", 0.0, 4.0, 1.0)
        UI_FLOAT_MULTI(UI_TEXTURE_BLENDWEIGHT2, GaussianTexWeight2, "256x256 Texture Blend Weight", 0.0, 4.0, 1.0)
        UI_FLOAT_MULTI(UI_TEXTURE_BLENDWEIGHT3, GaussianTexWeight3, "128x128 Texture Blend Weight", 0.0, 4.0, 1.0)
        UI_FLOAT_MULTI(UI_TEXTURE_BLENDWEIGHT4, GaussianTexWeight4, "64x64 Texture Blend Weight", 0.0, 4.0, 1.0)
        UI_FLOAT_MULTI(UI_TEXTURE_BLENDWEIGHT5, GaussianTexWeight5, "32x32 Texture Blend Weight", 0.0, 4.0, 1.0)
        UI_FLOAT_MULTI(UI_TEXTURE_BLENDWEIGHT6, GaussianTexWeight6, "16x16 Texture Blend Weight", 0.0, 4.0, 1.0)
        UI_BOOL(GaussianNormalizeResult, "Normalize Weights", true)
    #endif

    #if GAUSSIAN_TEXTURE_TINTS
        UI_WHITESPACE(7)

        UI_BOOL(GaussianApplyTint, "Apply Tint", false)
        UI_FLOAT3_MULTI(UI_TEXTURE_TINT1, GaussianTint1, "512x512 Texture Tint", 1.0, 1.0, 1.0)
        UI_FLOAT3_MULTI(UI_TEXTURE_TINT2, GaussianTint2, "256x256 Texture Tint", 1.0, 1.0, 1.0)
        UI_FLOAT3_MULTI(UI_TEXTURE_TINT3, GaussianTint3, "128x128 Texture Tint", 1.0, 1.0, 1.0)
        UI_FLOAT3_MULTI(UI_TEXTURE_TINT4, GaussianTint4, "64x64 Texture Tint", 1.0, 1.0, 1.0)
        UI_FLOAT3_MULTI(UI_TEXTURE_TINT5, GaussianTint5, "32x32 Texture Tint", 0.84, 0.0, 0.46)
        UI_FLOAT3_MULTI(UI_TEXTURE_TINT6, GaussianTint6, "16x16 Texture Tint", 1.0, 1.0, 1.0)
        UI_BOOL(GaussianNormalizeTint, "Normalize Tint", true)
        UI_FLOAT3_MULTI(UI_COUNTERBALANCE_TINT, GaussianTintFinal, "Counterbalance Tint", 1.0, 0.968, 0.988)
    #endif

    UI_WHITESPACE(8)

    UI_INT(PostFilter, "Post Filter", 0, 2, 0)
#endif // INCLUDE_GAUSSIAN_BLOOM


// Progressive Bloom UI Parameters
#if INCLUDE_PROGRESSIVE_BLOOM
    UI_WHITESPACE(9)

    #define UI_CATEGORY Progressive
    UI_SEPARATOR_CUSTOM("Progressive Bloom")

    UI_FLOAT_MULTI(UI_PROGRESSIVE_FILTER_RADIUS, ProgressiveFilterRadius, "Filter Radius", 1.0, 8.0, 1.0)

    #if PROGRESSIVE_INDIVIDUAL_FILTER_SIZE_CONTROLS
        UI_FLOAT(ProgressiveUpsampleRadius1, "Upsample Radius 1", 1.0, 8.0, 1.0)
        UI_FLOAT(ProgressiveUpsampleRadius2, "Upsample Radius 2", 1.0, 8.0, 1.0)
        UI_FLOAT(ProgressiveUpsampleRadius3, "Upsample Radius 3", 1.0, 8.0, 1.0)
        UI_FLOAT(ProgressiveUpsampleRadius4, "Upsample Radius 4", 1.0, 8.0, 1.0)
        #if PROGRESSIVE_LOWEST_MIP > 4
            UI_FLOAT(ProgressiveUpsampleRadius5, "Upsample Radius 5", 1.0, 8.0, 1.0)
        #endif
        #if PROGRESSIVE_LOWEST_MIP > 5
            UI_FLOAT(ProgressiveUpsampleRadius6, "Upsample Radius 6", 1.0, 8.0, 1.0)
        #endif
    #endif
#endif // INCLUDE_PROGRESSIVE_BLOOM

UI_WHITESPACE(10)

#define UI_CATEGORY Postpass
UI_SEPARATOR
UI_BOOL_MULTI(UI_INVERSE_TONEMAP, InverseTonemap, "Inverse Tonemap", false)
UI_FLOAT(HDR_MAX, "HDR Max", 0.0, 100000, 16384.0)
#if POSTPASS_CC
    UI_FLOAT_MULTI(UI_MULTIPLIER, Multiplier, "Multiplier", 0.0, 8.0, 1.0)
    UI_FLOAT3_MULTI(UI_POST_TINT, PostTint, "Tint", 1.0, 1.0, 1.0)
    UI_FLOAT_MULTI(UI_SATURATION, Saturation, "Saturation", 0.0, 8.0, 1.0)
    UI_FLOAT_MULTI(UI_DESATURATION, Desaturation, "Desaturation", 0.0, 4.0, 0.0)
    UI_FLOAT_MULTI(UI_DESATURATION_CURVE, DesaturationCurve, "Desaturation Curve", 0.1, 2.0, 1.0)
    UI_FLOAT_MULTI(UI_GAMMA, Gamma, "Gamma", 0.1, 8.0, 1.0)
#endif

UI_WHITESPACE(11)

#define UI_CATEGORY Dither
UI_SEPARATOR

UI_BOOL(UseDither, "Use Dither", true)
UI_BOOL(LegacyDither, "Legacy Dither", false)
UI_INT(DitherBitDepth, "Target Bit Depth", 1, 12, 8)

#if INCLUDE_LENS_DIRT
    UI_WHITESPACE(12)

    #define UI_CATEGORY LensDirt
    UI_SEPARATOR
    UI_FLOAT_MULTI(UI_LENS_DIRT_AMOUNT, LensDirtAmount, "Amount", 0.0, 1.0, 0.0)
    UI_FLOAT(LensDirtSaturation, "Dirt Texture Saturation", 0.0, 1.0, 0.0)
#endif



// ----------------------------------------------------------------------------------------------------------
// TEMP PARAMETERS
// ----------------------------------------------------------------------------------------------------------
// keyboard controlled temporary variables. Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4 tempF1; //0,1,2,3
float4 tempF2; //5,6,7,8
float4 tempF3; //9,0
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



// ----------------------------------------------------------------------------------------------------------
// TEXTURES
// ----------------------------------------------------------------------------------------------------------
Texture2D TextureDownsampled; // color R16B16G16A16 64 bit or R11G11B10 32 bit hdr format. 1024*1024 size
Texture2D TextureColor; // color which is output of previous technique (except when drawed to temporary render target), R16B16G16A16 64 bit hdr format. 1024*1024 size

Texture2D TextureOriginal; // color R16B16G16A16 64 bit or R11G11B10 32 bit hdr format, screen size. PLEASE AVOID USING IT BECAUSE OF ALIASING ARTIFACTS, UNLESS YOU FIX THEM
Texture2D TextureDepth; // scene depth R32F 32 bit hdr format, screen size. PLEASE AVOID USING IT BECAUSE OF ALIASING ARTIFACTS, UNLESS YOU FIX THEM
Texture2D TextureAperture; // this frame aperture 1*1 R32F hdr red channel only. computed in PS_Aperture of enbdepthoffield.fx

#if INCLUDE_LENS_DIRT
    Texture2D TextureLens
    <
        string ResourceName = LENS_DIRT_TEXTURE;
    >;
#endif

// temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D RenderTarget1024; // R16B16G16A16F 64 bit hdr format, 1024*1024 size
Texture2D RenderTarget512; // R16B16G16A16F 64 bit hdr format, 512*512 size
Texture2D RenderTarget256; // R16B16G16A16F 64 bit hdr format, 256*256 size
Texture2D RenderTarget128; // R16B16G16A16F 64 bit hdr format, 128*128 size
Texture2D RenderTarget64; // R16B16G16A16F 64 bit hdr format, 64*64 size
Texture2D RenderTarget32; // R16B16G16A16F 64 bit hdr format, 32*32 size
Texture2D RenderTarget16; // R16B16G16A16F 64 bit hdr format, 16*16 size
Texture2D RenderTargetRGBA32; // R8G8B8A8 32 bit ldr format, screen size
Texture2D RenderTargetRGBA64F; // R16B16G16A16F 64 bit hdr format, screen size
// Not available in enbbloom.fx:
    // Texture2D RenderTargetRGBA64; // R16B16G16A16 64 bit ldr format
    // Texture2D RenderTargetR16F; // R16F 16 bit hdr format with red channel only
    // Texture2D RenderTargetR32F; // R32F 32 bit hdr format with red channel only
    // Texture2D RenderTargetRGB32F; // 32 bit hdr format without alpha

#define RT(x) RenderTarget##x



// ----------------------------------------------------------------------------------------------------------
// SAMPLERS
// ----------------------------------------------------------------------------------------------------------
SamplerState SamplerPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};
SamplerState SamplerLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
SamplerState SamplerBorder
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Border;
    AddressV = Border;
    BorderColor = float4(0.0, 0.0, 0.0, 1.0);
};



// ----------------------------------------------------------------------------------------------------------
// STRUCTS
// ----------------------------------------------------------------------------------------------------------
struct VS_INPUT
{
    float3 pos : POSITION;
    float2 txcoord : TEXCOORD0;
};
struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
    float2 txcoord : TEXCOORD0;
};



// ----------------------------------------------------------------------------------------------------------
// VERTEX SHADER
// ----------------------------------------------------------------------------------------------------------
VS_OUTPUT VS_Quad(VS_INPUT IN)
{
    VS_OUTPUT OUT;
    OUT.pos = float4(IN.pos.xyz, 1.0);
    OUT.txcoord.xy = IN.txcoord.xy;
    return OUT;
}


VS_OUTPUT VS_Scaled(VS_INPUT IN, uniform float scale)
{
    VS_OUTPUT OUT;
    OUT.pos = float4(IN.pos.xyz, 1.0);
    OUT.txcoord.xy = IN.txcoord.xy * scale;
    return OUT;
}



// ----------------------------------------------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------------------------------------------
#if UI_THRESHOLD_STYLE > 0
float thresholdLuma(float3 x)
{
    if (ThresholdLuma == 0)
    {
        return dot(x, 0.333);
    }
    else if (ThresholdLuma == 1)
    {
        return max3(x);
    }
    else
    {
        return calculateLuma(x);
    }
}
#endif

float4 bloomSample(Texture2D tex, float2 uv)
{
    if (DiscardBorder)
    {
        return tex.SampleLevel(SamplerBorder, uv, 0);
    }
    else
    {
        return tex.SampleLevel(SamplerLinear, uv, 0);
    }
}


#if INCLUDE_GAUSSIAN_BLOOM
float4 gaussianFilter(rfTexture2D tex, float2 axis, float2 uv, float2 pixsize, float filtersize, float centerdepth)
{
    static const float quality = max(0.66, 1.0 + GaussianQuality / 4.0);

    filtersize *= quality;
    axis *= pixsize;

    filtersize = round(max(4.0, filtersize));
    float o = -rcp(filtersize * filtersize);

    float4 sum = 0.0;

    for (float i = -filtersize; i <= filtersize; i++)
    {
        float offset = i * 2.0 - 0.5;
        float2 sampleUV = float2(uv + axis * offset);
        offset *= quality;

        float weight = exp(offset * offset * o);
        float4 curr = bloomSample(tex, sampleUV);

#if GAUSSIAN_DEPTH_AWARENESS
        if (GaussianDepthAwareness > 0.0)
        {
            float diff = curr.w - centerdepth;
            diff = clamp(1.0 - diff * GaussianDepthAwareness, GaussianDepthAwarenessClamp, 1.0);
            weight *= diff;
        }
#endif

        sum.xyz += curr.xyz * weight;
        sum.w += weight;
    }
    sum.xyz /= sum.w + 0.0001;

    return sum;
}
#endif


float getLinearDepth(float2 uv)
{
    return linearDepth(TextureDepth.Sample(SamplerLinear, uv, 0).x);
}


float4 applyPrepass(float4 res, float2 uv)
{
    float depth = getLinearDepth(uv);

    res.xyz *= 1.0 - SkyFade * (depth >= 1.0);

#if UI_THRESHOLD_STYLE > 0
    if (UseThreshold)
    {
    #if UI_THRESHOLD_STYLE == 1
        static const float lowerThreshold = Threshold - ThresholdSmoothness * 0.5;
        static const float upperThreshold = Threshold + ThresholdSmoothness * 0.5;
    #else
        static const float lowerThreshold = ThresholdMin;
        static const float upperThreshold = ThresholdMax;
    #endif
        if (ThresholdStyle == 0)
        {
            res.xyz *= linearstep(lowerThreshold, upperThreshold, thresholdLuma(res.xyz));
        }
        else if (ThresholdStyle == 1)
        {
            res.xyz *= smoothstep(lowerThreshold, upperThreshold, thresholdLuma(res.xyz));
        }
        else
        {
            res.w = max3(res.xyz);
            res.xyz /= max(res.w, 0.001);
            res.w = max(0.0, res.w - lowerThreshold);
            res.xyz *= res.w;
        }
    }
#endif

    if (TonemapPrepass)
    {
        res.xyz = fastReinhard(res.xyz);
    }

    res.xyz = max(0.0, lerp(calculateLuma(res.xyz), res.xyz, PreSaturation));

    res.w = depth;
    return clamp(res, 0.0, HDR_MAX);
}


float4 encodeHDR(float3 color, float hdrMax)
{
    float peak = max3(color);
    float3 ldr = color / max(peak, 1.0);
    peak = (peak - 1.0) / hdrMax;
    return saturate(float4(ldr, peak));
}


float3 decodeHDR(float4 color, float hdrMax)
{
    return color.xyz * (1.0 + color.w * hdrMax);
}


#if INCLUDE_GAUSSIAN_BLOOM
float4 sampleBloom(Texture2D tex, float2 uv, float pixsize)
{
    if (PostFilter == 0) return tex.SampleLevel(SamplerLinear, uv, 0);
    else if (PostFilter == 1) return filter4x4(tex, uv, pixsize);
    else return filter3x3tent(tex, uv, pixsize);
}
#endif



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
// float permute(float x) { return ((34.0 * x + 1.0) * x) % 289.0; }
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
// PIXEL SHADERS
// ----------------------------------------------------------------------------------------------------------
float4 PS_Passthru(VS_OUTPUT IN, uniform Texture2D tex) : SV_Target
{
    return tex.Sample(SamplerLinear, IN.txcoord.xy);
}


float4 PS_Makepink(VS_OUTPUT IN) : SV_Target
{
    return float4(1.0, 0.0, 1.0, 1.0);
}


float4 PS_ApplyPrepass(VS_OUTPUT IN, uniform Texture2D tex) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    float4 res;

    res = tex.SampleLevel(SamplerLinear, uv, 0);
    res = applyPrepass(res, uv);

    return res;
}


float4 PS_Downsample(VS_OUTPUT IN, uniform Texture2D tex, uniform float texscale, uniform bool prepass) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    float4 res;

    res = filterJimenezOptimized(tex, uv, texscale);
    if (prepass) res = applyPrepass(res, uv);

    return res;
}


#if INCLUDE_PROGRESSIVE_BLOOM
float4 PS_Upsample(VS_OUTPUT IN, uniform Texture2D tex, uniform float texscale, uniform float passnum, uniform float radius) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    float4 res;

    if (ProgressiveFilterRadius > 1.0)
    {
        float t = passnum / clamp(PROGRESSIVE_LOWEST_MIP, 4, 6);
        radius = lerp(radius, radius * ProgressiveFilterRadius, t);
    }

    float2 pixsize = texscale * radius;
    pixsize.y *= ScreenSize.z;
    res = filter3x3tent(tex, uv, pixsize);

    return res;
}
#endif // INCLUDE_PROGRESSIVE_BLOOM


#if INCLUDE_GAUSSIAN_BLOOM
float4 PS_GaussianHori(VS_OUTPUT IN, uniform Texture2D tex, uniform float texscale, uniform float radius) : SV_Target
{
    if (radius < 0.0) return 0.0;

    float2 uv = IN.txcoord.xy;
    float4 res;

    if (min2(1.1 - uv) < 0.0) return 0.0;

    float4 srcbloom = tex.SampleLevel(SamplerLinear, uv, 0);
    if (radius <= 0.0) return srcbloom;
#if GAUSSIAN_DEPTH_AWARENESS
    radius = lerp(radius, radius * GaussianFarRadius, srcbloom.w);
#endif
    float4 bloom = gaussianFilter(tex, float2(1.0, 0.0), uv, texscale, radius, srcbloom.w);

    res = bloom;
    res.w = srcbloom.w;

    return res;
}


float4 PS_GaussianVert(VS_OUTPUT IN, uniform Texture2D tex, uniform float scale, uniform float texscale, uniform float radius) : SV_Target
{
    if (radius < 0.0) return 0.0;

    float2 uv = IN.txcoord.xy;
    float4 res;

    float4 srcbloom = tex.SampleLevel(SamplerLinear, uv * scale, 0);
    if (radius <= 0.0) return srcbloom;
    radius *= ScreenSize.z;
#if GAUSSIAN_DEPTH_AWARENESS
    radius = lerp(radius, radius * GaussianFarRadius, srcbloom.w);
#endif
    float4 bloom = gaussianFilter(tex, float2(0.0, 1.0), uv * scale, texscale, radius, srcbloom.w);

    res = bloom;
    res.w = srcbloom.w;

    return res;
}


float4 PS_GaussianCombine(VS_OUTPUT IN) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    float4 res = 0.0;

    static const float invTex = 1.0 / 512.0;
    float4 tex1 = sampleBloom(RenderTarget512, uv, invTex)        * UseGaussianTex1;
    float4 tex2 = sampleBloom(RenderTarget256, uv, invTex * 2.0)  * UseGaussianTex2;
    float4 tex3 = sampleBloom(RenderTarget128, uv, invTex * 4.0)  * UseGaussianTex3;
    float4 tex4 = sampleBloom(RenderTarget64,  uv, invTex * 8.0)  * UseGaussianTex4;
    float4 tex5 = sampleBloom(RenderTarget32,  uv, invTex * 16.0) * UseGaussianTex5;
    float4 tex6 = sampleBloom(RenderTarget16,  uv, invTex * 32.0) * UseGaussianTex6;

#if !GAUSSIAN_TEXTURE_TINTS && !GAUSSIAN_TEXTURE_BLEND_WEIGHTS
    float weight = UseGaussianTex1 + UseGaussianTex2 + UseGaussianTex3
                 + UseGaussianTex4 + UseGaussianTex5 + UseGaussianTex6;
#else
    #if GAUSSIAN_TEXTURE_TINTS
        #define WEIGHT_TYPE float3
    #else
        #define WEIGHT_TYPE float
    #endif
    WEIGHT_TYPE weight  = 0.0;
    WEIGHT_TYPE weight1 = UseGaussianTex1;
    WEIGHT_TYPE weight2 = UseGaussianTex2;
    WEIGHT_TYPE weight3 = UseGaussianTex3;
    WEIGHT_TYPE weight4 = UseGaussianTex4;
    WEIGHT_TYPE weight5 = UseGaussianTex5;
    WEIGHT_TYPE weight6 = UseGaussianTex6;
    #undef WEIGHT_TYPE
#endif

#if GAUSSIAN_TEXTURE_BLEND_WEIGHTS
    if (GaussianApplyWeights)
    {
        tex1 *= GaussianTexWeight1;
        tex2 *= GaussianTexWeight2;
        tex3 *= GaussianTexWeight3;
        tex4 *= GaussianTexWeight4;
        tex5 *= GaussianTexWeight5;
        tex6 *= GaussianTexWeight6;
        if (GaussianNormalizeResult)
        {
            weight1 *= GaussianTexWeight1;
            weight2 *= GaussianTexWeight2;
            weight3 *= GaussianTexWeight3;
            weight4 *= GaussianTexWeight4;
            weight5 *= GaussianTexWeight5;
            weight6 *= GaussianTexWeight6;
        }
    }
#endif

#if GAUSSIAN_TEXTURE_TINTS
    if (GaussianApplyTint)
    {
        tex1.xyz *= GaussianTint1;
        tex2.xyz *= GaussianTint2;
        tex3.xyz *= GaussianTint3;
        tex4.xyz *= GaussianTint4;
        tex5.xyz *= GaussianTint5;
        tex6.xyz *= GaussianTint6;
        if (GaussianNormalizeTint)
        {
            weight1.xyz *= GaussianTint1;
            weight2.xyz *= GaussianTint2;
            weight3.xyz *= GaussianTint3;
            weight4.xyz *= GaussianTint4;
            weight5.xyz *= GaussianTint5;
            weight6.xyz *= GaussianTint6;
        }
    }
#endif

#if GAUSSIAN_TEXTURE_TINTS || GAUSSIAN_TEXTURE_BLEND_WEIGHTS
    weight = weight1 + weight2 + weight3 + weight4 + weight5 + weight6;
#endif

    res += tex1 + tex2 + tex3 + tex4 + tex5 + tex6;
    res.xyz /= max(weight, 0.0001);

#if GAUSSIAN_TEXTURE_TINTS
    if (GaussianApplyTint)
    {
        res.xyz *= GaussianTintFinal;
    }
#endif

    res.w = 1.0;
    return min(res, HDR_MAX);
}
#endif // INCLUDE_GAUSSIAN_BLOOM


float4 PS_Postpass(VS_OUTPUT IN, float4 v0 : SV_Position0) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    float4 res;

#if INCLUDE_GAUSSIAN_BLOOM
    res = sampleBloom(TextureColor, uv, 1.0 / 1024.0);
#else
    res = TextureColor.SampleLevel(SamplerLinear, uv, 0);
#endif

    if (InverseTonemap)
    {
        res.xyz = min(fastReinhardInverse(saturate(res.xyz)), HDR_MAX);
    }

#if POSTPASS_CC
    // CC
    res.xyz *= Multiplier;
    res.xyz *= (PostTint / (max3(PostTint) + 0.0001));
    res.xyz = lerp(calculateLuma(res.xyz), res.xyz, Saturation);
    res.w = max3(res.xyz);
    res.xyz = res.xyz / (res.w + 0.0001);
    if (Desaturation > 0.0) res.xyz = lerp(res.xyz, dot(res.xyz, 0.333), min(res.w, (res.w * rcp(DesaturationCurve + res.w)) * Desaturation));
    if (Gamma != 1.0) res.w = pow(res.w, Gamma);
    res.xyz = res.w * res.xyz;
#endif

#if INCLUDE_LENS_DIRT
    float3 dirt = TextureLens.SampleLevel(SamplerLinear, uv, 0).xyz;
    dirt = lerp(calculateLuma(dirt), dirt, LensDirtSaturation);
    res.xyz = lerp(res.xyz, res.xyz * dirt.xyz, LensDirtAmount);
#endif

    res.w = 1.0;
    if (UseDither) res.xyz = applyDither(res.xyz, v0.xy, uv);
    return clamp(res, 0.0, HDR_MAX);
}



// ----------------------------------------------------------------------------------------------------------
// TECHNIQUES
// ----------------------------------------------------------------------------------------------------------
#if INCLUDE_GAUSSIAN_BLOOM
// ----------------------------------------------------------------------------------------------------------
// GAUSSIAN BLOOM STYLE 1
// ----------------------------------------------------------------------------------------------------------
#if GAUSSIAN_TEXTURE_FILTER_SIZES
    #define FILTER_SIZE(x) (UseGaussianTex##x ? GaussianFilterSize##x : -1)
#else
    #define FILTER_SIZE(x) (UseGaussianTex##x ? GaussianFilterSize : -1)
#endif
TECHNIQUE_NAMED_TARGETED(Gaussian, "Gaussian1", RT(512), VS_Quad(), PS_Downsample(TextureDownsampled, 1.0/1024.0, true))
TECHNIQUE_TARGETED(Gaussian1,  RT(256), VS_Quad(), PS_Downsample(RT(512), 1.0/512.0, false))
TECHNIQUE_TARGETED(Gaussian2,  RT(128), VS_Quad(), PS_Downsample(RT(256), 1.0/256.0, false))
TECHNIQUE_TARGETED(Gaussian3,  RT(64),  VS_Quad(), PS_Downsample(RT(128), 1.0/128.0, false))
TECHNIQUE_TARGETED(Gaussian4,  RT(32),  VS_Quad(), PS_Downsample(RT(64),  1.0/64.0,  false))
TECHNIQUE_TARGETED(Gaussian5,  RT(16),  VS_Quad(), PS_Downsample(RT(32),  1.0/32.0,  false))
TECHNIQUE         (Gaussian6,           VS_Scaled(2),  PS_GaussianHori(RT(512),                1.0/512.0,  FILTER_SIZE(1)))
TECHNIQUE_TARGETED(Gaussian7,  RT(512), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/2.0,  1.0/1024.0, FILTER_SIZE(1)))
TECHNIQUE         (Gaussian8,           VS_Scaled(4),  PS_GaussianHori(RT(256),                1.0/256.0,  FILTER_SIZE(2)))
TECHNIQUE_TARGETED(Gaussian9,  RT(256), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/4.0,  1.0/1024.0, FILTER_SIZE(2)))
TECHNIQUE         (Gaussian10,          VS_Scaled(8),  PS_GaussianHori(RT(128),                1.0/128.0,  FILTER_SIZE(3)))
TECHNIQUE_TARGETED(Gaussian11, RT(128), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/8.0,  1.0/1024.0, FILTER_SIZE(3)))
TECHNIQUE         (Gaussian12,          VS_Scaled(16), PS_GaussianHori(RT(64),                 1.0/64.0,   FILTER_SIZE(4)))
TECHNIQUE_TARGETED(Gaussian13, RT(64),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/16.0, 1.0/1024.0, FILTER_SIZE(4)))
TECHNIQUE         (Gaussian14,          VS_Scaled(32), PS_GaussianHori(RT(32),                 1.0/32.0,   FILTER_SIZE(5)))
TECHNIQUE_TARGETED(Gaussian15, RT(32),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/32.0, 1.0/1024.0, FILTER_SIZE(5)))
TECHNIQUE         (Gaussian16,          VS_Scaled(64), PS_GaussianHori(RT(16),                 1.0/16.0,   FILTER_SIZE(6)))
TECHNIQUE_TARGETED(Gaussian17, RT(16),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/64.0, 1.0/1024.0, FILTER_SIZE(6)))
TECHNIQUE(Gaussian18, VS_Quad(), PS_GaussianCombine())
TECHNIQUE(Gaussian19, VS_Quad(), PS_Postpass())


// ----------------------------------------------------------------------------------------------------------
// GAUSSIAN BLOOM STYLE 2
// ----------------------------------------------------------------------------------------------------------
static const int MaxTex =
    UseGaussianTex6 ? 6
  : UseGaussianTex5 ? 5
  : UseGaussianTex4 ? 4
  : UseGaussianTex3 ? 3
  : UseGaussianTex2 ? 2
  : UseGaussianTex1 ? 1
  : -1;
#if GAUSSIAN_TEXTURE_FILTER_SIZES
    #define FILTER_SIZE_2(x) (x <= MaxTex ? GaussianFilterSize##x : -1)
#else
    #define FILTER_SIZE_2(x) (x <= MaxTex ? GaussianFilterSize : -1)
#endif
TECHNIQUE_NAMED_TARGETED(GaussianII, "Gaussian2", RT(512), VS_Quad(), PS_Downsample(TextureDownsampled, 1.0/1024.0, true))
TECHNIQUE         (GaussianII1,           VS_Scaled(2),  PS_GaussianHori(RT(512),                1.0/512.0,  FILTER_SIZE_2(1)))
TECHNIQUE_TARGETED(GaussianII2,  RT(512), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/2.0,  1.0/1024.0, FILTER_SIZE_2(1)))
TECHNIQUE         (GaussianII3,           VS_Scaled(4),  PS_GaussianHori(RT(512),                1.0/256.0,  FILTER_SIZE_2(2)))
TECHNIQUE_TARGETED(GaussianII4,  RT(256), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/4.0,  1.0/1024.0, FILTER_SIZE_2(2)))
TECHNIQUE         (GaussianII5,           VS_Scaled(8),  PS_GaussianHori(RT(256),                1.0/128.0,  FILTER_SIZE_2(3)))
TECHNIQUE_TARGETED(GaussianII6,  RT(128), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/8.0,  1.0/1024.0, FILTER_SIZE_2(3)))
TECHNIQUE         (GaussianII7,           VS_Scaled(16), PS_GaussianHori(RT(128),                1.0/64.0,   FILTER_SIZE_2(4)))
TECHNIQUE_TARGETED(GaussianII8,  RT(64),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/16.0, 1.0/1024.0, FILTER_SIZE_2(4)))
TECHNIQUE         (GaussianII9,           VS_Scaled(32), PS_GaussianHori(RT(64),                 1.0/32.0,   FILTER_SIZE_2(5)))
TECHNIQUE_TARGETED(GaussianII10, RT(32),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/32.0, 1.0/1024.0, FILTER_SIZE_2(5)))
TECHNIQUE         (GaussianII11,          VS_Scaled(64), PS_GaussianHori(RT(32),                 1.0/16.0,   FILTER_SIZE_2(6)))
TECHNIQUE_TARGETED(GaussianII12, RT(16),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/64.0, 1.0/1024.0, FILTER_SIZE_2(6)))
TECHNIQUE(GaussianII13, VS_Quad(), PS_GaussianCombine())
TECHNIQUE(GaussianII14, VS_Quad(), PS_Postpass())
#endif // INCLUDE_GAUSSIAN_BLOOM


#if INCLUDE_PROGRESSIVE_BLOOM
// ----------------------------------------------------------------------------------------------------------
// PROGRESSIVE BLOOM
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------
// 1024x1024 STYLE
// ----------------------------------------------------------------------------------------------------------
#if PROGRESSIVE_INDIVIDUAL_FILTER_SIZE_CONTROLS
    #define UPSAMPLE_RADIUS(x) ProgressiveUpsampleRadius##x
#else
    #define UPSAMPLE_RADIUS(x) 1.0
#endif
TECHNIQUE_NAMED_TARGETED(Progressive, "Progressive1024", RT(512), VS_Quad(), PS_Downsample(TextureDownsampled, 1.0/1024.0, true))
TECHNIQUE_TARGETED(Progressive1,  RT(256), VS_Quad(), PS_Downsample(RT(512), 1.0/512.0, false))
TECHNIQUE_TARGETED(Progressive2,  RT(128), VS_Quad(), PS_Downsample(RT(256), 1.0/256.0, false))
TECHNIQUE_TARGETED(Progressive3,  RT(64),  VS_Quad(), PS_Downsample(RT(128), 1.0/128.0, false))
#if PROGRESSIVE_LOWEST_MIP > 5
TECHNIQUE_TARGETED(Progressive4,  RT(32),  VS_Quad(), PS_Downsample(RT(64), 1.0/64.0, false))
TECHNIQUE_TARGETED(Progressive5,  RT(16),  VS_Quad(), PS_Downsample(RT(32), 1.0/32.0, false))
TECHNIQUE_TARGETED(Progressive6,  RT(32),  VS_Quad(), PS_Upsample(RT(16),  1.0/16.0,  1, UPSAMPLE_RADIUS(1)))
TECHNIQUE_TARGETED(Progressive7,  RT(64),  VS_Quad(), PS_Upsample(RT(32),  1.0/32.0,  2, UPSAMPLE_RADIUS(2)))
TECHNIQUE_TARGETED(Progressive8,  RT(128), VS_Quad(), PS_Upsample(RT(64),  1.0/64.0,  3, UPSAMPLE_RADIUS(3)))
TECHNIQUE_TARGETED(Progressive9,  RT(256), VS_Quad(), PS_Upsample(RT(128), 1.0/128.0, 4, UPSAMPLE_RADIUS(4)))
TECHNIQUE_TARGETED(Progressive10, RT(512), VS_Quad(), PS_Upsample(RT(256), 1.0/256.0, 5, UPSAMPLE_RADIUS(5)))
TECHNIQUE         (Progressive11,          VS_Quad(), PS_Upsample(RT(512), 1.0/512.0, 6, UPSAMPLE_RADIUS(6)))
TECHNIQUE(Progressive12, VS_Quad(), PS_Postpass())
#elif PROGRESSIVE_LOWEST_MIP > 4
TECHNIQUE_TARGETED(Progressive4,  RT(32),  VS_Quad(), PS_Downsample(RT(64), 1.0/64.0, false))
TECHNIQUE_TARGETED(Progressive5,  RT(64),  VS_Quad(), PS_Upsample(RT(32),  1.0/32.0,  1, UPSAMPLE_RADIUS(1)))
TECHNIQUE_TARGETED(Progressive6,  RT(128), VS_Quad(), PS_Upsample(RT(64),  1.0/64.0,  2, UPSAMPLE_RADIUS(2)))
TECHNIQUE_TARGETED(Progressive7,  RT(256), VS_Quad(), PS_Upsample(RT(128), 1.0/128.0, 3, UPSAMPLE_RADIUS(3)))
TECHNIQUE_TARGETED(Progressive8,  RT(512), VS_Quad(), PS_Upsample(RT(256), 1.0/256.0, 4, UPSAMPLE_RADIUS(4)))
TECHNIQUE         (Progressive9,           VS_Quad(), PS_Upsample(RT(512), 1.0/512.0, 5, UPSAMPLE_RADIUS(5)))
TECHNIQUE(Progressive10, VS_Quad(), PS_Postpass())
#else
TECHNIQUE_TARGETED(Progressive4,  RT(128), VS_Quad(), PS_Upsample(RT(64),  1.0/64.0,  1, UPSAMPLE_RADIUS(1)))
TECHNIQUE_TARGETED(Progressive5,  RT(256), VS_Quad(), PS_Upsample(RT(128), 1.0/128.0, 2, UPSAMPLE_RADIUS(2)))
TECHNIQUE_TARGETED(Progressive6,  RT(512), VS_Quad(), PS_Upsample(RT(256), 1.0/256.0, 3, UPSAMPLE_RADIUS(3)))
TECHNIQUE         (Progressive7,           VS_Quad(), PS_Upsample(RT(512), 1.0/512.0, 4, UPSAMPLE_RADIUS(4)))
TECHNIQUE(Progressive9, VS_Quad(), PS_Postpass())
#endif
#endif // INCLUDE_PROGRESSIVE_BLOOM
