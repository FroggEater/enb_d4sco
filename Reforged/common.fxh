// ----------------------------------------------------------------------------------------------------------
// REFORGED INCLUDE FILE

// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
// OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
// OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ----------------------------------------------------------------------------------------------------------



#ifndef REFORGED_COMMON_H
#define REFORGED_COMMON_H



#ifndef REFORGED_INCLUDE_DITHERS
    #define REFORGED_INCLUDE_DITHERS 0
#endif

#ifndef REFORGED_INCLUDE_TONEMAPPERS
    #define REFORGED_INCLUDE_TONEMAPPERS 0
#endif

#ifndef REFORGED_INCLUDE_FILTERS
    #define REFORGED_INCLUDE_FILTERS 0
#endif



// ----------------------------------------------------------------------------------------------------------
// SHADER MODEL COMPATIBILITY MACROS
// ----------------------------------------------------------------------------------------------------------
#if REFORGED_HLSL_3
    #define rfTexture2D sampler2D
    #define rfSample(samp, co) tex2Dlod(samp, float4((co)##.xy, 0, 0))
#elif REFORGED_HLSL_5
    SamplerState rfSamplerPoint
    {
        Filter = MIN_MAG_MIP_POINT;
        AddressU = Clamp;
        AddressV = Clamp;
    };
    SamplerState rfSamplerLinear
    {
        Filter = MIN_MAG_MIP_LINEAR;
        AddressU = Clamp;
        AddressV = Clamp;
    };

    #define rfTexture2D Texture2D
    #define rfSample(tex, co) tex.SampleLevel(rfSamplerLinear, (co), 0)
#endif



// ----------------------------------------------------------------------------------------------------------
// CONSTANTS
// ----------------------------------------------------------------------------------------------------------
#define M_PI 3.14159263538
#define M_TAU 6.28318530718



// ----------------------------------------------------------------------------------------------------------
// LUMA
// ----------------------------------------------------------------------------------------------------------
#ifndef LUMA_TYPE
    #define LUMA_TYPE 1
#endif

float rec601luma(float3 v) { return dot(v, float3(0.298999995, 0.587000012, 0.114)); }
float rec709luma(float3 v) { return dot(v, float3(0.2125, 0.7154, 0.0721)); }
float rec709_5luma(float3 v) { return dot(v, float3(0.212395, 0.701049, 0.086556)); }
float rec2020(float3 v) { return dot(v, float3(0.2627, 0.6780, 0.0593)); }
float calculateLuma(float3 v)
{
#if LUMA_TYPE == 0
    return rec601luma(v);
#elif LUMA_TYPE == 1
    return rec709luma(v);
#elif LUMA_TYPE == 2
    return rec709_5luma(v);
#elif LUMA_TYPE == 3
    return rec2020luma(v);
#elif LUMA_TYPE == 4
    return dot(v, float3(0.25, 0.5, 0.25));
#elif LUMA_TYPE == 5
    return dot(v, 0.33333);
#endif
}



// ----------------------------------------------------------------------------------------------------------
// COLORSPACES
// ----------------------------------------------------------------------------------------------------------
// http://chilliant.blogspot.nl/2012/08/srgb-approximations-for-hlsl.html
float3 lin2srgb_fast(float3 v) { return sqrt(v); }
float3 srgb2lin_fast(float3 v) { return v * v; }
float3 srgb2lin(float3 v) { return pow(v, 2.233333333); }
float3 lin2srgb(float3 v) { return pow(v, 0.428571429); }
float3 srgb2lin_accurate(float3 v) { return v * (v * (v * 0.305306011 + 0.682171111) + 0.012522878); }
float3 lin2srgb_accurate(float3 v)
{
    float3 s1 = sqrt(v);
    float3 s2 = sqrt(s1);
    float3 s3 = sqrt(s2);
    return 0.662002687 * s1 + 0.684122060 * s2 - 0.323583601 * s3 - 0.0225411470 * v;
}
float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
    float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * normalize(lerp(K.xxx, saturate(p - K.xxx), c.y));
}



// ----------------------------------------------------------------------------------------------------------
// GENERAL PURPOSE
// ----------------------------------------------------------------------------------------------------------
#define remap(v, a, b) (((v) - (a)) / ((b) - (a)))
#define remap2(v, a1, b1, a2, b2) ((a2) + ((v) - (a1)) * ((b2) - (a2)) / ((b1) - (a1)))
#define linearstep(a, b, v) saturate(remap(v, a, b))
#define spline1(x) ((x) * (x) * (3.0 - 2.0 * (x)))
#define spline2(x) ((x) * (x) * (x) * ((x) * ((x) * 6.0 - 15.0) + 10.0))
#define flatten(x) max(0.0, x)
#define limit(x) min(1.0, x)
#define min2(v) min(v.x, v.y)
#define max2(v) max(v.x, v.y)
// float min2(float2 v) { return min(v.x, v.y); }
// float max2(float2 v) { return max(v.x, v.y); }
#define min3(v) min(v.x, min(v.y, v.z))
#define max3(v) max(v.x, max(v.y, v.z))
// float min3(float3 v) { return min(min(v.x, v.y), v.z); }
// float min3(float x, float y, float z) { return min(x, min(y, z)); }
// float max3(float3 v) { return max(max(v.x, v.y), v.z); }
// float max3(float x, float y, float z) { return max(x, max(y, z)); }
#define min4(v) min(min(min(v.x, v.y), v.z), v.w)
#define max4(v) max(max(max(v.x, v.y), v.z), v.w)
// float min4(float4 v) { return min(min(min(v.x, v.y), v.z), v.w); }
// float max4(float4 v) { return max(max(max(v.x, v.y), v.z), v.w); }
float linearDepth(float d) { return d * rcp(mad(d, -2999.0, 3000.0)); }
float expStep(float x, float k, float n) { return exp(-k * pow(x, n)); }
float gain(float x, float k)
{
    float a = 0.5 * pow(2.0 * ((k < 0.5) ? x : 1.0 - x), k);
    return (x < 0.5) ? a : 1.0 - a;
}
float parabola(float x, float k) { return pow(4.0 * x * (1.0 - x), k); }
float almostIdentity( float x, float m, float n )
{
    if (x > m) return x;
    const float a = 2.0 * n - m;
    const float b = 2.0 * m - 3.0 * n;
    const float t = x / m;
    return (a * t + b) * t * t + n;
}
float impulse(float k, float x)
{
    const float h = k * x;
    return h * exp(1.0 - h);
}
float cubicPulse(float c, float w, float x)
{
    x = abs(x - c);
    if(x > w) return 0.0;
    x /= w;
    return 1.0 - x * x * (3.0 - 2.0 * x);
}



// ----------------------------------------------------------------------------------------------------------
// RANDOM & NOISE
// ----------------------------------------------------------------------------------------------------------
float rand21(float2 uv)
{
    float2 noise = frac(sin(dot(uv, float2(12.9898, 78.233) * 2.0)) * 43758.5453);
    return (noise.x + noise.y) * 0.5;
}
float rand11(float x) { return frac(x * 0.024390243); }
float permute(float x) { return ((34.0 * x + 1.0) * x) % 289.0; }



// ----------------------------------------------------------------------------------------------------------
// DITHERING
// ----------------------------------------------------------------------------------------------------------
#if REFORGED_INCLUDE_DITHERS
    // http://loopit.dk/banding_in_games.pdf
    float3 monoTriDither(in float3 color, float2 uv)
    {
        static const float lsb = 1.0 / 255.0;
        static const float lobit = 0.5 / 255.0;
        static const float hibit = 249.5 / 255.0;

        float2 dither = rand21(uv);
        dither.y = rand11(dither.x);

        float lo = saturate(remap(min3(color.xyz), 0.0, lobit));
        float hi = saturate(remap(max3(color.xyz), 1.0, hibit));

        return lerp(dither.x - 0.5, dither.x - dither.y, min(lo, hi)) * lsb;
    }


    #define REFORGED_DITHER_QUALITY_LEVEL 1
    #define REFORGED_DITHER_BIT_DEPTH 10
    float3 chromaTriDither(float3 color, float2 uv, float timer)
    {
        static const float bitstep = pow(2.0, REFORGED_DITHER_BIT_DEPTH) - 1.0;
        static const float lsb = 1.0 / 255.0;
        static const float lobit = 0.5 / bitstep;
        static const float hibit = (bitstep - 0.5) / bitstep;

        float3 m = float3(uv, rand21(uv + timer)) + 1.0;
        float h = permute(permute(permute(m.x) + m.y) + m.z);

        float3 noise1, noise2;
        noise1.x = rand11(h); h = permute(h);
        noise2.x = rand11(h); h = permute(h);
        noise1.y = rand11(h); h = permute(h);
        noise2.y = rand11(h); h = permute(h);
        noise1.z = rand11(h); h = permute(h);
        noise2.z = rand11(h);

    #if REFORGED_DITHER_QUALITY_LEVEL == 1
        float lo = saturate(remap(min3(color.xyz), 0.0, lobit));
        float hi = saturate(remap(max3(color.xyz), 1.0, hibit));
        return lerp(noise1 - 0.5, noise1 - noise2, min(lo, hi)) * lsb;
    #elif REFORGED_DITHER_QUALITY_LEVEL == 2
        float3 lo = saturate(remap(color.xyz, 0.0, lobit));
        float3 hi = saturate(remap(color.xyz, 1.0, hibit));
        float3 uni = noise1 - 0.5;
        float3 tri = noise1 - noise2;
        return float3(
            lerp(uni.x, tri.x, min(lo.x, hi.x)),
            lerp(uni.y, tri.y, min(lo.y, hi.y)),
            lerp(uni.z, tri.z, min(lo.z, hi.z))) * lsb;
    #endif
    }
#endif // REFORGED_INCLUDE_DITHERS



// ----------------------------------------------------------------------------------------------------------
// TONEMAPPING
// ----------------------------------------------------------------------------------------------------------
float3 fastReinhard(float3 c) { return c * rcp(max3(c) + 1.0); }
float3 fastReinhardInverse(float3 c) { return c * rcp(1.0 - max3(c)); }
#if REFORGED_INCLUDE_TONEMAPPERS
    float3 reinhard(float3 color) { return color / (1.0 + color); }
    float3 reinhardScaled(float3 color, float white) { return (color.xyz * (1.0 + (color.xyz / (white * white))) / (1.0 + color.xyz)); }
    float3 reinhardPeak(float3 color) { return color / (1.0 + max3(color)); }
    float3 reinhardScaledPeak(float3 color, float white)
    {
        float peak = max3(color);
        return color * (1.0 + (peak / (white * white))) / (1.0 + peak);
    }


    #define uncharted2Tonemap(x, a, b, c, d, e, f) \
       (((x * (a * x + c * b) + d * e) / (x * (a * x + b) + d * f)) - e / f)


    float3 uncharted2Scaled(float3 x, float white)
    {
        #ifndef UNCHARTED2_PARAMETERS
            static const float UNCHARTED2_A = 0.22;
            static const float UNCHARTED2_B = 0.30;
            static const float UNCHARTED2_C = 0.10;
            static const float UNCHARTED2_D = 0.20;
            static const float UNCHARTED2_E = 0.02;
            static const float UNCHARTED2_F = 0.30;
        #endif

        float4 y = float4(x, white);
        y = uncharted2Tonemap(y, UNCHARTED2_A, UNCHARTED2_B, UNCHARTED2_C, UNCHARTED2_D, UNCHARTED2_E, UNCHARTED2_F);

        return y.xyz / y.w;
    }
#endif // REFORGED_INCLUDE_TONEMAPPERS



// ----------------------------------------------------------------------------------------------------------
// COMMON FILTERS
// ----------------------------------------------------------------------------------------------------------
#if REFORGED_INCLUDE_FILTERS
    float4 filter4x4(rfTexture2D tex, float2 uv, float2 pixelsize)
    {
        float4 res = 0.0;

        static const float2 offsets[4] =
        {
            float2(-0.5, -0.5),
            float2(0.5, -0.5),
            float2(-0.5, 0.5),
            float2(0.5, 0.5),
        };

        for (int i = 0; i < 4; i++)
        {
            res += rfSample(tex, uv + offsets[i] * pixelsize);
        }

        return res * 0.25;
    }


    float4 filter3x3tent(rfTexture2D tex, float2 uv, float2 pixsize)
    {
        float4 res = 0.0;

        static const float2 offsets[9] =
        {
            float2(-1.0, 1.0),
            float2(0.0, 1.0),
            float2(1.0, 1.0),
            float2(-1.0, 0.0),
            float2(0.0, 0.0),
            float2(1.0, 0.0),
            float2(-1.0, -1.0),
            float2(0.0, -1.0),
            float2(1.0, -1.0)
        };

        static const float weights[9] =
        {
            0.0625, 0.125, 0.0625,
            0.125, 0.25, 0.125,
            0.0625, 0.125, 0.0625
        };

        for (int i = 0; i < 9; i++)
        {
            res += rfSample(tex, uv + offsets[i] * pixsize) * weights[i];
        }

        return res;
    }


    float4 filterJimenez(rfTexture2D tex, float2 uv, float2 pixsize)
    {
        // http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
        float4 res = rfSample(tex, uv) * 0.125;

        static const float2 offsets[12] =
        {
            float2(-1.0, 1.0),
            float2(1.0, 1.0),
            float2(-1.0, -1.0),
            float2(1.0, -1.0),

            float2(0.0, 1.0),
            float2(-1.0, 0.0),
            float2(0.0, -1.0),
            float2(1.0, 0.0),

            float2(-0.5, 0.5),
            float2(0.5, 0.5),
            float2(-0.5, -0.5),
            float2(0.5, -0.5)
        };

        static const float weights[12] =
        {
            0.03125, 0.03125, 0.03125, 0.03125,
            0.0625, 0.0625, 0.0625, 0.0625,
            0.125, 0.125, 0.125, 0.125
        };

        for (int i = 0; i < 12; i++)
        {
            res += rfSample(tex, uv + offsets[i] * pixsize) * weights[i];
        }

        return res;
    }


    float4 filterJimenezOptimized(rfTexture2D tex, float2 uv, float2 pixsize)
    {
        // http://loopit.dk/rendering_inside.pdf
        float4 res = 0.0;

        static const float2 offsets[9] =
        {
            float2(-0.79477726, 0.79477726),
            float2(0.75, 0.0),
            float2(0.79477726, 0.79477726),
            float2(-0.75, 0.0),
            float2(0.0, 0.0),
            float2(0.0, 0.75),
            float2(-0.79477726, -0.79477726),
            float2(0.0, -0.75),
            float2(0.79477726, -0.79477726)
        };

        static const float weights[9] =
        {
            0.0625, 0.125, 0.0625,
            0.125, 0.25, 0.125,
            0.0625, 0.125, 0.0625
        };

        for (int i = 0; i < 9; i++)
        {
            res += rfSample(tex, uv + offsets[i] * pixsize) * weights[i];
        }

        return res;
    }


    float4 cubic(float x)
    {
        float x2 = x * x;
        float x3 = x2 * x;
        float4 w;
        w.x =   -x3 + 3*x2 - 3*x + 1;
        w.y =  3*x3 - 6*x2       + 4;
        w.z = -3*x3 + 3*x2 + 3*x + 1;
        w.w =  x3;
        return w / 6.f;
    }


    float4 bicubic(rfTexture2D tex, float2 uv, float2 res)
    {
        float2 invres = 1.0 / res;
        uv *= res;
        float2 fuv = frac(uv);
        uv -= fuv;

        float4 xcubic = cubic(fuv.x);
        float4 ycubic = cubic(fuv.y);

        float4 c = float4(uv.x - 1.0, uv.x + 1.0, uv.y - 1.0, uv.y + 1.0);
        float4 s = float4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
        float4 offset = c + float4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) * rcp(s);
        float4 s0 = rfSample(tex, float2(offset.x * invres.x, offset.z * invres.y));
        float4 s1 = rfSample(tex, float2(offset.y * invres.x, offset.z * invres.y));
        float4 s2 = rfSample(tex, float2(offset.x * invres.x, offset.w * invres.y));
        float4 s3 = rfSample(tex, float2(offset.y * invres.x, offset.w * invres.y));

        float sx = s.x * rcp(s.x + s.y);
        float sy = s.z * rcp(s.z + s.w);

        return lerp(
            lerp(s3, s2, sx),
            lerp(s1, s0, sx), sy);
    }


    float4 sampleSmooth(rfTexture2D s, float2 uv, float2 res)
    {
        // http://www.iquilezles.org/www/articles/texture/texture.htm
        uv = uv * res + 0.5;
        float2 uvi = floor(uv);
        float2 uvf = frac(uv);
        uv = uvi + uvf * uvf * (3.0 - 2.0 * uvf);
        uv = (uv - 0.5) / res;
        return rfSample(s, uv);
    }
#endif // REFORGED_INCLUDE_FILTERS



// END
#endif