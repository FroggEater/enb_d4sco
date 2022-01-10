//========================= V1.6 =============================//
//    ___ _            _             _      _    _            //
//   / __| |_  __ _ __| |___ _ _    /_\  __| |__| |___ _ _    //
//   \__ \ ' \/ _` / _` / -_) '_|  / _ \/ _` / _` / _ \ ' \   //
//   |___/_||_\__,_\__,_\___|_|   /_/ \_\__,_\__,_\___/_||_|  //
//                                                            //
//============================================================//
// Shader Addon by Adyss                                      //
// The Sandvich Maker: For his super neat tools and advice    //
// LonelyKitsune: Helpt me with the sunposition               //
// ArKano22: Original Author of the SSGI shader.              //
// It works more like SSAO here tho...                        //
// https://www.gamedev.net/forums/topic.asp?topic_id=550452   //
// Also this uses code bits from: Kingeric1992 and Luluco250  //
//============================================================//

// I wanted to try something with this but it didnt work. Yet you can enable the AO effect if you like so
// Its kinda noisy since i am not quite done with it. Might be a cool thing for performance enbs since it can run faster than ENB AO
#define UseExperimentalSSAO 0

//==========//
// Textures //
//==========//
Texture2D			TextureOriginal;     // color R16B16G16A16 64 bit hdr format
Texture2D			TextureColor;        // color which is output of previous technique (except when drawed to temporary render target), R16B16G16A16 64 bit hdr format
Texture2D			TextureDepth;        // scene depth R32F 32 bit hdr format
Texture2D			TextureJitter;       // blue noise
Texture2D			TextureMask;         // alpha channel is mask for skinned objects (less than 1) and amount of sss
Texture2D           TextureNormal;       // Normal maps. Alpha seems to only effect a few selected objects (specular map i guess)

Texture2D			RenderTargetRGBA32;  // R8G8B8A8 32 bit ldr format
Texture2D			RenderTargetRGBA64;  // R16B16G16A16 64 bit ldr format
Texture2D			RenderTargetRGBA64F; // R16B16G16A16F 64 bit hdr format
Texture2D			RenderTargetR16F;    // R16F 16 bit hdr format with red channel only
Texture2D			RenderTargetR32F;    // R32F 32 bit hdr format with red channel only
Texture2D			RenderTargetRGB32F;  // 32 bit hdr format without alpha

// Include Needes Values
#include "Include/Shared/Globals.fxh"
#include "Include/Shared/Macros.fxh"
#include "Include/Shared/Conversions.fxh"
#include "Include/Shared/Blendmodes.fxh"

//=====//
// GUI //
//=====//
UI_MSG(1,                       " Color Correction")
UI_FLOAT(ShadowRange,           "   Calibrate Shadow Range",           0.0, 1.0, 0.18)
UI_FLOAT(LiftShadows,           "   Lighten Shadows",                  0.0, 1.0, 0.2)
UI_FLOAT(HDRTone,               "   HDR Tone",                         0.0, 1.0, 0.0)
UI_BLANK(2)
UI_MSG(3,                       " Sunrays")
UI_BOOL(ToggleRays,             "   Enable Rays",                      false)
UI_INT(Samples,                 "   Quality",                          2.0, 10.0, 2.0)
UI_COLOR(SunColor,              "   Ray Tone",                         0.85, 0.73, 0.62)
UI_FLOAT(RayPower,              "   Ray Visibility",                   0.0, 7.0, 3.0)
UI_FLOAT(RayTight,              "   Ray Tightness",                    0.5, 3.0, 1.0)
UI_FLOAT(RayLength,             "   Ray Length",                       0.2, 5.0, 1.0)
UI_FLOAT(BBRadius,              "   Ray Thickness",                    1.0, 10.0, 3.0)
UI_BLANK(3)
UI_MSG(4,                       " Skin")
UI_FLOAT_FINE(SkinTone,         "   Skin Tone",                        1.0, 0.0, 100.0, 50.0)
UI_FLOAT(SkinExposure,          "   Skin Brightness",                 -2.0, 2.0, -0.2)
UI_FLOAT(SkinGamma,             "   Skin Gamma",                       0.0, 2.0, 1.0)
UI_COLOR(SkinTint,              "   Skin Tint",                        0.5, 0.5, 0.5)
UI_FLOAT(SkinCut,               "   Skin effect fade distance",        0.0, 10.0, 1.0)
UI_BLANK(4)
UI_MSG(5,                       " Sky")
UI_FLOAT(SkyBrightness,         "   Sky Brightness",                   0.0, 2.0, 1.0)
UI_FLOAT(SkySaturation,         "   Sky Saturation",                   0.0, 2.0, 1.0)
UI_COLOR(SkyTint,               "   Sky Tint",                         0.5, 0.5, 0.5)
#if UseExperimentalSSAO == 1
UI_BLANK(5)
UI_MSG(6,                       " SSAO")
UI_BOOL(EnableSSAO,             "   Enable SSAO",                      false)
UI_FLOAT(SSAO_SamplingArea,     "   Sampling Area",                    1.0, 3.0, 1.5)
UI_INT(SSAO_Samples,            "   AO Samples",                       4.0, 32.0, 8.0)
UI_FLOAT(SSAO_AOPower,          "   AO Power",                         0.0, 5.0, 1.5)
UI_FLOAT(DownsampleBy,          "   AO Rendering Resolution",          0.1, 1.0, 1.0)
UI_BOOL(ShowSSAO,               "   Show SSAO Texture",                false)
#endif

//===========//
// Functions //
//===========//

// Get pos of the sun on the screen on an xy axis
float2 getSun()
{
    float3 Sundir       = SunDirection.xyz / SunDirection.w;
    float2 Suncoord     = Sundir.xy / Sundir.z;
           Suncoord     = Suncoord * float2(0.48, ScreenSize.z * 0.48) + 0.5;
           Suncoord.y   = 1.0 - Suncoord.y;
    return Suncoord;
}

// Output is 1 if looking directly at the sun. As soon as you move away from it, it gets lower. If the sun is not on the screen the output is 0;
float getSunvisibility()
{
    return saturate(lerp(1, 0, distance(getSun(), float2(0.5, 0.5)))); // Dunno if saturate is needed but it wont hurt either
}

/* This code was automatically generated by gaussianGenerator.py
   Number of filter taps per pass: 37
   Number of texture samples per pass: 19 */
static const float gaussianWeights[10] = { 0.125370687629, 0.222519402285, 0.137865281851, 0.0576913179436, 0.0160253660954, 0.00287351392056, 0.000318635616192, 2.04472053171e-05, 6.8157351057e-07, 9.69521352162e-09 };
static const float gaussianOffsets[10] = { 0.0, 1.46341463415, 3.41463414634, 5.36585365854, 7.31707317073, 9.26829268293, 11.2195121951, 13.1707317073, 15.1219512195, 17.0731707317 };
static const int   gaussianLoopLength  = 10;

// Not actually box blur lol. But it gets the job done
float3 BoxBlur(Texture2D inputTex, float2 coord, float2 ps)
{
	return (inputTex.Sample(LinearSampler, coord - ps * 0.5).rgb +
		    inputTex.Sample(LinearSampler, coord + ps * 0.5).rgb +
		    inputTex.Sample(LinearSampler, coord + float2(-ps.x, ps.y) * 0.5).rgb +
		    inputTex.Sample(LinearSampler, coord + float2( ps.x,-ps.y) * 0.5).rgb) * 0.25;
}

// Golden Ratio
static const float gr = (1.0 + sqrt(5.0)) * 0.5;

// Originally form the Frostbite engine
float3 simpleShoulderCurve(float3 x)
{
    return 1 - exp(-x);
}

// In ENB... this seemed the best method to me
float3 getSkyMask(float Depth, float2 coord)
{
    return floor(TextureNormal.Sample(PointSampler, coord).w * Depth);
}

float2 scaleCoords(float2 coord, float scalefac)
{
    return (coord - 0.5) * scalefac + 0.5;
}

//===============//
// Pixel Shaders //
//===============//

//Dunno if sutch a thing is needed but to avoid bugs
float4	PS_CleanBuffer(VS_OUTPUT IN) : SV_Target
{
    return float4(0.0, 0.0, 0.0, 1.0);
}

float3	PS_SkyMask(VS_OUTPUT IN) : SV_Target
{
    return TextureOriginal.Sample(PointSampler, IN.txcoord.xy) * getSkyMask(GetLinearizedDepth(IN.txcoord.xy), IN.txcoord.xy);
}

float3	PS_SmallBlur(VS_OUTPUT IN) : SV_Target
{
    return BoxBlur(TextureColor, IN.txcoord.xy, PixelSize);
}

float3	PS_DrawRays(VS_OUTPUT IN, float4 v0 : SV_Position0) : SV_Target
{
    if (!ToggleRays || getSunvisibility() < 0.001) discard;
    float2 coord        = IN.txcoord.xy;
    float3 Rays         = 0;
    float2 Sunpos       = (coord - getSun()) * ((1.0 / Samples) * RayLength);
    float  Jitter       = TextureJitter.Load(int3(v0.xy % 16, 0)); // Thanks Sandvich

    for(int i = 1; i < Samples; i++)
    {
        Jitter = frac(Jitter + gr * i * Timer.x * 10);
        Rays  += TextureColor.Sample(LinearSampler, lerp(coord, coord - Sunpos, Jitter));
    }

    return Rays / Samples;
}

float3	PS_RayBlurH(VS_OUTPUT IN) : SV_Target
{
    if (!ToggleRays || getSunvisibility() < 0.001) discard;
    float2 coord   = IN.txcoord.xy;
    float3 Blur    = TextureColor.Sample(LinearSampler, coord) * gaussianWeights[0];

    for (int i = 1; i < gaussianLoopLength; i++)
    {
        Blur += TextureColor.Sample(LinearSampler, coord + float2(gaussianOffsets[i], 0.0) * PixelSize) * gaussianWeights[i];
        Blur += TextureColor.Sample(LinearSampler, coord - float2(gaussianOffsets[i], 0.0) * PixelSize) * gaussianWeights[i];
    }

    return Blur;
}

float3	PS_RayBlurV(VS_OUTPUT IN) : SV_Target
{
    if (!ToggleRays || getSunvisibility() < 0.001) discard;
    float2 coord   = IN.txcoord.xy;
    float3 Blur    = TextureColor.Sample(LinearSampler, coord) * gaussianWeights[0];

    for (int i = 1; i < gaussianLoopLength; i++)
    {
        Blur += TextureColor.Sample(LinearSampler, coord + float2(0.0, gaussianOffsets[i]) * PixelSize) * gaussianWeights[i];
        Blur += TextureColor.Sample(LinearSampler, coord - float2(0.0, gaussianOffsets[i]) * PixelSize) * gaussianWeights[i];
    }

    return Blur;
}

float3	PS_Color(VS_OUTPUT IN) : SV_Target
{
    float2 coord        = IN.txcoord.xy;
    float3 Color        = TextureOriginal.Sample(PointSampler, coord);
    float3 Blur         = BoxBlur(TextureOriginal, coord, PixelSize);
    float4 Ambient      = TextureMask.Sample(LinearSampler, coord);
    float3 Rays         = pow(BoxBlur(RenderTargetRGB32F, coord, PixelSize * BBRadius), RayTight) * SunColor;
    float  Sunvisibility = getSunvisibility();
    float  Depth        = GetLinearizedDepth(coord);
    float  SkinMask     = saturate((1 - floor(Ambient.a)) * 1 - smoothstep(0.0, SkinCut * 0.04, Depth));
    float  SkyMask      = getSkyMask(Depth, coord);

    // Calc Shadows and Hightlights and edit them
    float  Lo           = ShadowRange - saturate(min3(Color));
    float  Luma         = GetLuma(Color, Rec709);
    //float  Hi           = saturate(Luma - Lo); // Hightlights
           Color        = lerp(Color, lerp(Color, max(Color, Ambient), Lo), LiftShadows);

#if UseExperimentalSSAO == 1
    float3 AO           = BoxBlur(RenderTargetRGBA64F, coord, PixelSize);

           if(EnableSSAO)
           Color        = (Color * AO);

           if(ShowSSAO)
           return AO;
#endif

    // HDR Tone from Ansel
           Luma         = GetLuma(Color, Rec709); //Refresh luma after editing color
    float  BlurLuma     = GetLuma(Blur, Rec709); // actually needs bigger blur but it kinda works anyways
    float  sqrtLum 	    = sqrt(Color);
    float  HDRToning    = sqrtLum * lerp(sqrtLum * (2 * Luma * BlurLuma - Luma - 2 * Luma + 2.0), (2 * sqrtLum * BlurLuma - 2 * BlurLuma + 1), Luma > 0.5); //modified soft light v1
       	   Color        = Color / (Luma+1e-6) * lerp(Luma, HDRToning, HDRTone);

    // Skinedits start here
    float3 SkinColor    = Color * SkinMask;
           SkinColor    = lerp(pow(SkinColor, float3(1.0, 0.95, 0.9)), pow(SkinColor, float3(0.85, 0.9, 1.0)), SkinTone *  0.01); // Skin Tone Adjustment.
           SkinColor    = ldexp(SkinColor, SkinExposure);
           SkinColor    = SkinColor * (0.5 + SkinTint);
           SkinColor    = pow(SkinColor, SkinGamma);
           Color        = lerp(Color, SkinColor / (1 + Color), SkinMask);

    // Find Sky to Adjust it
    float3 Sky          = Color * SkyMask;
           Sky          = saturate(lerp(dot(Sky, float3(0.3, 0.2, 0.5)), Color, SkySaturation)); // Using custom luma coeff here cuz reasons
           Sky          = Sky * SkyBrightness * (0.5 + SkyTint);
           Color        = lerp(Color, Sky, SkyMask);

    //Mix Sunrays into image
           if (SunDirection.z > 0.0 && Sunvisibility > 0.01 && EInteriorFactor < 1.0 && ToggleRays > 0.99)
           Color        = lerp(Color, lerp(Color, BlendScreenf(Color, saturate(Rays * RayPower)), ENightDayFactor), Sunvisibility);

    return Color;
}

#if UseExperimentalSSAO == 1
float compareDepths(float depth1, float depth2)
{
    float gauss     = 0.0;
    float diff      = (depth1 - depth2) * 100.0; //depth difference (0-100)
    float gdisplace = 0.2; //gauss bell center
    float garea     = 3.0; //gauss bell width

    //reduce left bell width to avoid self-shadowing
    if (diff<gdisplace) garea = 0.2;

    gauss = pow(2.7182, -2 * (diff - gdisplace) * (diff - gdisplace) / (garea * garea));

    return max(0.2, gauss);
}

float4 calAO(float depth, float dw, float dh, float2 oricoord)
{
    float  temp   = 0;
    float3 bleed  = 0;
    float  coordw = oricoord.x + dw;
    float  coordh = oricoord.y + dh;

    if (coordw  < 1.0 && coordw  > 0.0 && coordh < 1.0 && coordh  > 0.0)
    {
        float2 coord = float2(coordw , coordh);
               temp  = compareDepths(depth, TextureColor.Sample(LinearSampler, coord).a);
               bleed = TextureColor.Sample(LinearSampler, coord).rgb;
    }

    return float4(bleed * temp, temp);
}

float3 PS_SSAO(VS_OUTPUT IN, float4 v0 : SV_Position0) : SV_Target
{
    //initialize stuff:
    float2 coord  = IN.txcoord.xy;
    float  depth  = TextureColor.Sample(LinearSampler, coord).a;
    float  Jitter = TextureJitter.Load(int3(v0.xy % 16, 0));
    float4 gi     = 0.0; // I put ao in .a cuz it seems inout isnt working
    float  pw     = PixelSize.x;
    float  ph     = PixelSize.y;

    for(int i = 0; i < SSAO_Samples; ++i)
    {
        //calculate color bleeding and ao:
        gi += calAO(depth, pw,   ph, coord);
        gi += calAO(depth, pw,  -ph, coord);
        gi += calAO(depth, -pw,  ph, coord);
        gi += calAO(depth, -pw, -ph, coord);

        //sample jittering:
        Jitter = frac(Jitter + gr * i);
        pw    += Jitter * 0.0005;
        Jitter = frac(Jitter + i / Samples);
        ph    += Jitter * 0.0005;

        //increase sampling area:
        pw *= i * SSAO_SamplingArea;
        ph *= i * SSAO_SamplingArea;
    }

    return float3((gi.rgb / (SSAO_Samples * 2)) + 1.0 - (gi.a / (SSAO_Samples * 2)) * SSAO_AOPower);
}

float4	PS_Downscale(VS_OUTPUT IN) : SV_Target
{
    float3 Color = BicubicFilter(TextureOriginal, BorderSampler, scaleCoords(IN.txcoord.xy, 1 / DownsampleBy));
    float  Depth = GetLinearizedDepth(scaleCoords(IN.txcoord.xy, 1 / DownsampleBy));
    return float4(Color, Depth);
}

float3	PS_Upscale(VS_OUTPUT IN) : SV_Target
{
    return BoxBlur(TextureColor, scaleCoords(IN.txcoord.xy, DownsampleBy), PixelSize);
}

#endif

// TECHNIQUES

#if UseExperimentalSSAO == 1
technique11 pre <string UIName="Prepass";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_CleanBuffer()));
    }
}

technique11 pre1
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_SkyMask()));
    }
}

technique11 pre2
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_SmallBlur()));
    }
}

technique11 pre3
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawRays()));
    }
}

technique11 pre4
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawRays()));
    }
}

technique11 pre5
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawRays()));
    }
}

technique11 pre6
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_RayBlurH()));
    }
}

technique11 pre7  <string RenderTarget="RenderTargetRGB32F";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_RayBlurV()));
    }
}

technique11 pre8
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_CleanBuffer()));
    }
}

technique11 pre9
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_Downscale()));
    }
}

technique11 pre10
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_SSAO()));
    }
}

technique11 pre11 <string RenderTarget="RenderTargetRGBA64F";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_Upscale()));
    }
}

technique11 pre12
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_Color()));
    }
}

#endif

#if UseExperimentalSSAO == 0

technique11 pre <string UIName="Prepass";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_CleanBuffer()));
    }
}

technique11 pre1
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_SkyMask()));
    }
}

technique11 pre2
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_SmallBlur()));
    }
}

technique11 pre3
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawRays()));
    }
}

technique11 pre4
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawRays()));
    }
}

technique11 pre5
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_DrawRays()));
    }
}

technique11 pre6
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_RayBlurH()));
    }
}

technique11 pre7  <string RenderTarget="RenderTargetRGB32F";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_RayBlurV()));
    }
}

technique11 pre8
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_CleanBuffer()));
    }
}

technique11 pre9
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_Color()));
    }
}
#endif
