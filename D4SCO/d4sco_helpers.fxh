////////// D4SCO Helpers - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// PRIMING
#ifndef D4SCO_HELPERS
#define D4SCO_HELPERS



////////// SAMPLERS
SamplerState PointSampler
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Clamp;
	AddressV = Clamp;
};

SamplerState LinearSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};



////////// CONSTANTS
static const float PI = 3.1415926535897932384626433832795;
static const float rPI = 1.0 / PI;

static const float NAN = 0.0 / 0.0;
static const float POSINF = 1.0 / 0.0;
static const float NEGINF = -1.0 / 0.0;

static const float PQ_CONST_N = (2610.0 / 4096.0 / 4.0);
static const float PQ_CONST_M = (2523.0 / 4096.0 * 128.0);
static const float PQ_CONST_C1 = (3424.0 / 4096.0);
static const float PQ_CONST_C2 = (2413.0 / 4096.0 * 32.0);
static const float PQ_CONST_C3 = (2392.0 / 4096.0 * 32.0);

static const float DELTA9 = 1e-9;
static const float DELTA8 = 1e-8;
static const float DELTA7 = 1e-7;
static const float DELTA6 = 1e-6;
static const float DELTA5 = 1e-5;
static const float DELTA4 = 1e-4;
static const float DELTA3 = 1e-3;
static const float DELTA2 = 1e-2;
static const float DELTA1 = 1e-1;
static const float HDR = 16384.0;

// static const float pst32 = 0.03125;
// static const float hst32 = 0.015625;

static const float3 LUM_709 = float3(0.212656, 0.715158, 0.072186);



////////// STRUCTS
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



////////// UTILS
float random(in float2 uv)
{
  float2 noise = (frac(sin(dot(uv , float2(12.9898,78.233) * 2.0)) * 43758.5453));
  return abs(noise.x + noise.y) * 0.5;
}

float max2(float2 v) { return max(v.x, v.y); }
float max3(float3 v) { return max(max2(v.xy), v.z); }
float max4(float4 v) { return max(max3(v.xyz), v.w); }

float min2(float2 v) { return min(v.x, v.y); }
float min3(float3 v) { return min(min2(v.xy), v.z); }
float min4(float4 v) { return min(min3(v.xyz), v.w); }

float sum2(float2 v) { return v.x + v.y; }
float sum3(float3 v) { return sum2(v.xy) + v.z; }
float sum4(float4 v) { return sum3(v.xyz) + v.w; }

float sub2(float2 v) { return v.x - v.y; }
float sub3(float3 v) { return sub2(v.xy) - v.z; }
float sub4(float4 v) { return sub3(v.xyz) - v.w; }

float2 clamp2(float2 v, float a, float b) { return float2(clamp(v.x, a, b), clamp(v.y, a, b)); }
float3 clamp3(float3 v, float a, float b) { return float3(clamp2(v.xy, a, b), clamp(v.z, a, b)); }
float4 clamp4(float4 v, float a, float b) { return float4(clamp3(v.xyz, a, b), clamp(v.w, a, b)); }

float sq(float x) { return pow(x, 2.0); }
float cb(float x) { return pow(x, 3.0); }
float qd(float x) { return pow(x, 4.0); }

bool same2(float2 v) { return v.x == v.y; }
bool same3(float3 v) { return same2(v.xy) && v.y == v.z; }
bool same4(float4 v) { return same3(v.xyz) && v.z == v.w; }

int divideup(int a, int b)
{
  if (b == 0) return 0;
  return int(a + b - 1) / int(b);
}

float2 border(float2 vec, float a, float b)
{
  return float2(
    clamp(vec.x, a, b),
    clamp(vec.y, a, b)
  );
}

float3 border(float3 vec, float a, float b)
{
  return float3(
    border(vec.xy, a, b),
    clamp(vec.z, a, b)
  );
}

float4 border(float4 vec, float a, float b)
{
  return float4(
    border(vec.xy, a, b),
    border(vec.zw, a, b)
  );
}



////////// COLOR OPERATORS
// Perceptual lightness - input color should be in linear RGB
float lightness(float lum)
{
  float L;
  if (lum <= (216.0 / 24389.0)) L = lum * (24389.0 / 27.0);
  else L = pow(lum, 1.0 / 3.0) * 116.0 - 16.0;

  return smoothstep(0.0, 100.0, L);
}

float lightness(float3 color)
{
  float lum = dot(color.rgb, LUM_709);
  return lightness(lum);
}

// Exponential luma compression
float lcompress(float x)
{
  return 1.0 - exp(-x);
}

float lcompress(float value, float treshold)
{
  float computed = treshold + (1 - treshold) * lcompress((value - treshold) / (1.0 - treshold));
  return value < treshold ? value : computed;
}

float3 lcompress(float3 color, float treshold)
{
  return float3(
    lcompress(color.r, treshold),
    lcompress(color.g, treshold),
    lcompress(color.b, treshold)
  );
}

// RGB <> XYZ
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
    3.24045483602140870, -1.53713885010257510, -0.49853154686848090,
    -0.96926638987565370, 1.87601092884249100, 0.04155608234667354,
    0.05564341960421366, -0.20402585426769815, 1.05722516245792870
  );
  return mul(mat, color);
}

// XYZ <> LMS (iCtCp Spec.)
float3 xyz2lms(float3 color)
{
  static const float3x3 mat = float3x3(
    0.3592, 0.6976, -0.0358,
    -0.1922, 1.1004, 0.0755,
    0.0070, 0.0749, 0.8434
  ); 
  return mul(mat, color);
}

float3 lms2xyz(float3 color)
{
  static const float3x3 mat = float3x3(
    2.07018005669561320, -1.32645687610302100, 0.206616006847855170,
    0.36498825003265756, 0.68046736285223520, -0.045421753075853236,
    -0.04959554223893212, -0.04942116118675749, 1.187995941732803400
  );
  return mul(mat, color);
}

// Linear <> sRGB
float3 linear2srgb(float3 color)
{
  float a = 0.055;
  float b = 0.0031308;
  return float3(
    color.r < b ? (12.92 * color.r) : ((1.0 + a) * pow(color.r, 1.0 / 2.4) - a),
    color.g < b ? (12.92 * color.g) : ((1.0 + a) * pow(color.g, 1.0 / 2.4) - a),
    color.b < b ? (12.92 * color.b) : ((1.0 + a) * pow(color.b, 1.0 / 2.4) - a)
  );
}

float3 srgb2linear(float3 color)
{
  float a = 0.055;
  float b = 0.04045;
  return float3(
    color.r < b ? (color.r / 12.92) : pow((color.r + a) / (1.0 + a), 2.4),
    color.g < b ? (color.g / 12.92) : pow((color.g + a) / (1.0 + a), 2.4),
    color.b < b ? (color.b / 12.92) : pow((color.b + a) / (1.0 + a), 2.4)
  );
}

// Linear <> PQ (ST.2084)
float3 linear2pq(float3 color, const float maxpq)
{
  color /= maxpq;

  float3 col2pow = pow(color, PQ_CONST_N);
  float3 numerator = PQ_CONST_C1 + PQ_CONST_C2 * col2pow;
  float3 denominator = 1.0 + PQ_CONST_C3 * col2pow;
  float3 pq = pow(numerator / denominator, PQ_CONST_M);

  return pq;
}

float3 pq2linear(float3 color, const float maxpq)
{
  float3 col2pow = pow(color, 1.0 / PQ_CONST_M);
  float3 numerator = max(col2pow - PQ_CONST_C1, 0.0);
  float3 denominator = PQ_CONST_C2 - (PQ_CONST_C3 * col2pow);
  float3 lcolor = pow(numerator / denominator, 1.0 / PQ_CONST_N);

  lcolor *= maxpq;

  return lcolor;
}

// RGB <> iCtCp
float3 rgb2ictcp(float3 color)
{
  color = rgb2xyz(color);
  color = xyz2lms(color);
  color = linear2pq(max(0.0, color), 100.0);

  static const float3x3 mat = float3x3(
    0.5000, 0.5000, 0.0000,
    1.6137, -3.3234, 1.7097,
    4.3780, -4.2455, -0.1325
  );
  return mul(mat, color);
}

float3 ictcp2rgb(float3 color)
{
  static const float3x3 mat = float3x3(
    1.0, 0.00860514569398152, 0.11103560447547328,
    1.0, -0.00860514569398152, -0.11103560447547328,
    1.0, 0.56004885956263900, -0.32063747023212210
  );
  color = mul(mat, color);

  color = pq2linear(color, 100.0);
  color = lms2xyz(color);
  return xyz2rgb(color);
}



#endif
