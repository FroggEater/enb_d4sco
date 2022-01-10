#ifndef ICTCP_COLORSPACES_H
#define ICTCP_COLORSPACES_H


// float3 rgb2xyz(float3 color)
// {
//     static const float3x3 mat = float3x3(
//         // frostbyte values
//         0.4124564, 0.3575761, 0.1804375,
//         0.2126729, 0.7151522, 0.0721750,
//         0.0193339, 0.1191920, 0.9503041
//     );
//     return mul(mat, color);
// }


// float3 xyz2rgb(float3 color)
// {
//     static const float3x3 mat = float3x3(
//         // frostbyte values
//          3.2404542, -1.5371385, -0.4985314,
//         -0.9692660,  1.8760108,  0.0415560,
//          0.0556434, -0.2040259,  1.0572252
//     );
//     return mul(mat, color);
// }


// float3 xyz2lms(float3 color)
// {
//     static const float3x3 mat = float3x3(
//         // frostbyte values
//          0.3592, 0.6976, -0.0358,
//         -0.1922, 1.1004,  0.0755,
//          0.0070, 0.0749,  0.8434
//     );
//     return mul(mat, color);
// }


// float3 lms2xyz(float3 color)
// {
//     static const float3x3 mat = float3x3(
//         // frostbyte values
//          2.0702, -1.3265,  0.2066,
//          0.3650,  0.6805, -0.0454,
//         -0.0496, -0.0494,  1.1879
//     );
//     return mul(mat, color);
// }


static const float PQ_Const_N = (2610.0 / 4096.0 / 4.0);
static const float PQ_Const_M = (2523.0 / 4096.0 * 128.0);
static const float PQ_Const_C1 = (3424.0 / 4096.0);
static const float PQ_Const_C2 = (2413.0 / 4096.0 * 32.0);
static const float PQ_Const_C3 = (2392.0 / 4096.0 * 32.0);


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


// float3 rgb2lms(float3 rgb)
// {
//     static const float3x3 mat = float3x3(
//         // wikipedia values
//         // 0.412109375,    0.52392578125,  0.06396484375,
//         // 0.166748046875, 0.720458984375, 0.1103515625,
//         // 0.024169921875, 0.075439453125, 0.900390625

//         // frostbyte values
//         0.29582280029999997,  0.62306443624,      0.08114154322,
//         0.15621084853,        0.7272263504600001, 0.11648924205,
//         0.035122606269999995, 0.15659446528,      0.80815544794
//     );
//     return mul(mat, rgb);
// }


// float3 lms2rgb(float3 lms)
// {
//     static const float3x3 mat = float3x3(
//         // wikipedia values
//         //  3.4367654503826586,  -2.5058469852729397,  0.06296374439889145,
//         // -0.7914551947720561,   1.9831215506221327, -0.18682475050187772,
//         // -0.02594363459959811, -0.09888983394799836, 1.1245920382889343

//         // frostbyte values
//          6.172012299588382,  -5.319658410674432,   0.14709592537669258,
//         -1.3238950004228818,  2.5602005272135897, -0.23610919904326724,
//         -0.0117087971603403, -0.26489082671563907, 1.2767432356374429
//     );
//     return mul(mat, lms);
// }


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


#endif