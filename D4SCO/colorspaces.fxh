// ----------------------------------------------------------------------------------------------------------
// colorlab include file

// permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// the software is provided "as is" and the author disclaims all warranties with regard to this software
// including all implied warranties of merchantability and fitness. in no event shall the author be liable
// for any special, direct, indirect, or consequential damages or any damages whatsoever resulting from loss
// of use, data or profits, whether in an action of contract, negligence or other tortious action, arising
// out of or in connection with the use or performance of this software.
// ----------------------------------------------------------------------------------------------------------


#ifndef D4SCO_COLORSPACES_H
#define D4SCO_COLORSPACES_H


static const float3 REC_601   = float3(0.299, 0.587, 0.114);
static const float3 REC_709   = float3(0.2125, 0.7154, 0.0721);
static const float3 REC_709_5 = float3(0.212395, 0.701049, 0.086556);
static const float3 REC_2020  = float3(0.2627, 0.6780, 0.0593);
static const float3 UNIFORM   = float3(0.3333, 0.3333, 0.3333);
static const float PQ_Const_N = (2610.0 / 4096.0 / 4.0);
static const float PQ_Const_M = (2523.0 / 4096.0 * 128.0);
static const float PQ_Const_C1 = (3424.0 / 4096.0);
static const float PQ_Const_C2 = (2413.0 / 4096.0 * 32.0);
static const float PQ_Const_C3 = (2392.0 / 4096.0 * 32.0);


// reference 10° whites 
// I copied these over just for testing purposes, but they don't have much purpose in the end
// static const float3 A     = float3(1.11144, 1.00000, 0.35200);  // Incandescent/tungsten
// static const float3 B     = float3(0.99178, 1.00000, 0.84349);  // Old direct sunlight at noon
// static const float3 C     = float3(0.97285, 1.00000, 1.16145);  // Old daylight
// static const float3 D55   = float3(0.95799, 1.00000, 0.90926);  // Mid-morning daylight
// static const float3 D50   = float3(0.96720, 1.00000, 0.81427);  // ICC profile PCS
// static const float3 D65   = float3(0.94811, 1.00000, 1.07304);  // Daylight, sRGB, Adobe-RGB
// static const float3 D65_2 = float3(0.95047, 1.00000, 1.08883);  // Daylight, sRGB, Adobe-RGB, 2°
// static const float3 D75   = float3(0.94416, 1.00000, 1.20641);  // North sky daylight
// static const float3 E     = float3(1.00000, 1.00000, 1.00000);  // Equal energy
// static const float3 F1    = float3(0.94791, 1.00000, 1.03191);  // Daylight Fluorescent
// static const float3 F2    = float3(1.03280, 1.00000, 0.69026);  // Cool fluorescent
// static const float3 F3    = float3(1.08968, 1.00000, 0.51965);  // White Fluorescent
// static const float3 F4    = float3(1.14961, 1.00000, 0.40963);  // Warm White Fluorescent
// static const float3 F5    = float3(0.93369, 1.00000, 0.98636);  // Daylight Fluorescent
// static const float3 F6    = float3(1.02148, 1.00000, 0.62074);  // Lite White Fluorescent
// static const float3 F7    = float3(0.95792, 1.00000, 1.07687);  // Daylight fluorescent, D65 simulator
// static const float3 F8    = float3(0.97115, 1.00000, 0.81135);  // Sylvania F40, D50 simulator
// static const float3 F9    = float3(1.02116, 1.00000, 0.67826);  // Cool White Fluorescent
// static const float3 F10   = float3(0.99001, 1.00000, 0.83134);  // Ultralume 50, Philips TL85
// static const float3 F11   = float3(1.03866, 1.00000, 0.65627);  // Ultralume 40, Philips TL84
// static const float3 F12   = float3(1.11428, 1.00000, 0.40353);  // Ultralume 30, Philips TL83


// #ifndef STANDARD_ILLUMINANT
//     #define STANDARD_ILLUMINANT D65_2
// #endif


#ifndef LUMA_COEFFICIENTS 
    #define LUMA_COEFFICIENTS REC_709
#endif


float calculateLuma(float3 c)
{
    return dot(c, LUMA_COEFFICIENTS);
}


float3 linear2srgb(float3 color)
{
    return (color.xyz < 0.0031308) ? 12.9 * color.xyz : 1.055 * pow(color.xyz, 1.0 / 2.4) - 0.055;
}


float3 srgb2linear(float3 color)
{
    return color.xyz < 0.04045 ? color.xyz / 12.92 : pow((color.xyz + 0.055) / 1.055, 2.4);
}


float3 hue2rgb(in float h)
{
    float r = abs(h * 6 - 3) - 1;
    float g = 2 - abs(h * 6 - 2);
    float b = 2 - abs(h * 6 - 4);
    return saturate(float3(r,g,b));
}


float rgb2hue(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    return abs(q.z + (q.w - q.y) / (6.0 * (q.x - min(q.w, q.y)) + 1e-10));
}


float3 rgb2hcv(in float3 RGB)
{
    float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
    float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6 * C + 1e-10) + Q.z);
    return float3(H, C, Q.x);
}


float3 hsv2rgb(in float3 HSV)
{
    float3 RGB = hue2rgb(HSV.x);
    return ((RGB - 1) * HSV.y + 1) * HSV.z;
}


float3 rgb2hsv(in float3 RGB)
{
    float3 HCV = rgb2hcv(RGB);
    float S = HCV.y / (HCV.z + 1e-10);
    return float3(HCV.x, S, HCV.z);
}


float3 rgb2yuv(float3 rgb)
{
    static const float3x3 mat = float3x3(
         0.2126,   0.7152,   0.0722,
        -0.09991, -0.33609,  0.436,
         0.615,   -0.55861, -0.05639
    );
    return mul(mat, rgb);
}


float3 yuv2rgb(float3 yuv)
{
    static const float3x3 mat = float3x3(
        1.0,  0.0,      1.28033,
        1.0, -0.21482, -0.38059,
        1.0,  2.12798,  0.0
    );
    return mul(mat, yuv);
}


float3 rgb2xyz(float3 color)
{
    static const float3x3 mat = float3x3(
        0.4124564, 0.3575761, 0.1804375,
        0.2126729, 0.7151522, 0.0721750,
        0.0193339, 0.1191920, 0.9503041
    );
    return mul(mat, color);
}


float3 xyz2rgb(float3 color)
{
    static const float3x3 mat = float3x3(
         3.2404542, -1.5371385, -0.4985314,
        -0.9692660,  1.8760108,  0.0415560,
         0.0556434, -0.2040259,  1.0572252
    );
    return mul(mat, color);
}


float3 xyz2lms(float3 color)
{
    static const float3x3 mat = float3x3(
         0.3592, 0.6976, -0.0358,
        -0.1922, 1.1004,  0.0755,
         0.0070, 0.0749,  0.8434
    );
    return mul(mat, color);
}


float3 lms2xyz(float3 color)
{
    static const float3x3 mat = float3x3(
         2.0702, -1.3265,  0.2066,
         0.3650,  0.6805, -0.0454,
        -0.0496, -0.0494,  1.1879
    );
    return mul(mat, color);
}


float3 rgb2lms(float3 rgb)
{
    static const float3x3 mat = float3x3(
        0.29582280029999997,  0.62306443624,      0.08114154322,
        0.15621084853,        0.7272263504600001, 0.11648924205,
        0.035122606269999995, 0.15659446528,      0.80815544794
    );
    return mul(mat, rgb);
}


float3 lms2rgb(float3 lms)
{
    static const float3x3 mat = float3x3(
         6.172012299588382,  -5.319658410674432,   0.14709592537669258,
        -1.3238950004228818,  2.5602005272135897, -0.23610919904326724,
        -0.0117087971603403, -0.26489082671563907, 1.2767432356374429
    );
    return mul(mat, lms);
}


float3 xyz2cielab(float3 xyz)
{
    xyz *= float3(1.05211, 1.0, 0.91842); // reciprocal of °2 D65 reference values
    xyz = xyz > 0.008856 ? pow(xyz, 1.0/3.0) : xyz * 7.787037 + 4.0/29.0;
    float L = (116.0 * xyz.y) - 16.0;
    float a = 500.0 * (xyz.x - xyz.y);
    float b = 200.0 * (xyz.y - xyz.z);
    return float3(L, a, b);
}


float3 cielab2xyz(float3 lab)
{
    float3 xyz;
    xyz.y = (lab.x + 16.0) / 116.0;
    xyz.x = xyz.y + lab.y / 500.0;
    xyz.z = xyz.y - lab.z / 200.0;
    xyz = xyz > 0.206897 ? xyz * xyz * xyz : 0.128418 * (xyz - 4.0/29.0);
    return max(0.0, xyz) * float3(0.95047, 1.0, 1.08883); // °2 D65 reference values
}


float3 cielab2cielchab(float3 lab)
{
    float C = length(lab.yz);
    float h = atan2(lab.z, lab.y);
    return float3(lab.x, C, h);
}


float3 cielchab2cielab(float3 lch)
{
    float a = cos(lch.z) * lch.y;
    float b = sin(lch.z) * lch.y;
    return float3(lch.x, a, b);
}

float3 linear2pq(float3 lin, const float maxPq)
{
    lin /= maxPq;

    float3 colToPow = pow(lin, PQ_Const_N);
    float3 numerator = PQ_Const_C1 + PQ_Const_C2 * colToPow;
    float3 denominator = 1.0 + PQ_Const_C3 * colToPow;
    return pow(numerator / denominator, PQ_Const_M);
}


float3 pq2linear(float3 lin, const float maxPq)
{
    float3 colToPow = pow(lin, 1.0 / PQ_Const_M);
    float3 numerator = max(colToPow - PQ_Const_C1, 0.0);
    float3 denominator = PQ_Const_C2 - PQ_Const_C3 * colToPow;
    lin = pow(numerator / denominator, 1.0 / PQ_Const_N);

    return lin * maxPq;
}

float3 lms2ictcp(float3 lms)
{
    static const float3x3 mat = float3x3(
        // frostbyte values
        0.5000,  0.5000,  0.0000,
        1.6137, -3.3234,  1.7097,
        4.3780, -4.2455, -0.1325
    );
    return mul(mat, lms);
}


float3 ictcp2lms(float3 ictcp)
{
    static const float3x3 mat = float3x3(
        // frostbyte values
        1.0,  0.0086051,  0.1111035,
        1.0, -0.0086051, -0.1111035,
        1.0,  0.5600488, -0.3206370
    );
    return mul(mat, ictcp);
}


float3 rgb2ictcp(float3 col)
{
    col = rgb2lms(col);
    col = linear2pq(max(0.0, col), 100.0);
    col = lms2ictcp(col);

    return col;
}


float3 ictcp2rgb(float3 col)
{
    col = ictcp2lms(col);
    col = pq2linear(col, 100.0);
    col = lms2rgb(col);

    return col;
}


float3 rgb2cielab(float3 rgb) { return xyz2cielab(rgb2xyz(rgb)); }
float3 cielab2rgb(float3 lab) { return xyz2rgb(cielab2xyz(lab)); }
float3 rgb2cielchab(float3 rgb) { return cielab2cielchab(rgb2cielab(rgb)); }
float3 cielchab2rgb(float3 lch) { return cielab2rgb(cielchab2cielab(lch)); }


#endif