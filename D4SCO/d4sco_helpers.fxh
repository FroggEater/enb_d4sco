////////// D4SCO Helpers - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// SAMPLERS
SamplerState Sampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};



////////// CONSTANTS
static const float PI = 3.1415926535897932384626433832795;
static const float rPI = 1.0 / PI;

static const float PQ_CONST_N = (2610.0 / 4096.0 / 4.0);
static const float PQ_CONST_M = (2523.0 / 4096.0 * 128.0);
static const float PQ_CONST_C1 = (3424.0 / 4096.0);
static const float PQ_CONST_C2 = (2413.0 / 4096.0 * 32.0);
static const float PQ_CONST_C3 = (2392.0 / 4096.0 * 32.0);

static const float DELTA9 = 1e-9;
static const float DELTA6 = 1e-6;
static const float DELTA3 = 1e-3;
static const float HDR = 16384.0;

static const float pst32 = 0.03125;
static const float hst32 = 0.015625;

static const float3 LUM_709 = float3(0.212656, 0.715158, 0.072186);
static const float3 P_LUM = float3(0.256, 0.67, 0.065); // Photopic luminance
static const float3 S_LUM = float3(-0.702, 1.039, 0.433); // Stocopic luminance

static const float GAMMA = 2.2;



////////// UTILS
float random(in float2 uv)
{
  float2 noise = (frac(sin(dot(uv , float2(12.9898,78.233) * 2.0)) * 43758.5453));
  return abs(noise.x + noise.y) * 0.5;
}

float max2(float2 v) { return max(v.x, v.y); }
float max3(float3 v) { return max(max2(v.xy), v.z); }
float max4(float4 v) { return max(max3(v.xyz), v.w); }

float sq(float x) { return pow(x, 2.0); }
float cb(float x) { return pow(x, 3.0); }
float qd(float x) { return pow(x, 4.0); }

float sum(float2 v)
{
  return v.x + v.y;
}

float sum(float3 v)
{
  return sum(v.xy) + v.z;
}

float sum(float4 v)
{
  return sum(v.xyz) + v.w;
}

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

float3 blur(Texture2D TextureInput, float2 coordsrc, float inputSize,
  float outputSize, float scale, float ratio)
{
  // Get inverted target size and correct by aspect ratio
  float2 invsize = scale / inputSize;
  invsize.y *= ratio;

  float2 stepcnt = inputSize;
  stepcnt *= invsize;
  stepcnt = border(stepcnt, 2.0, 16.0);

  int stepcntx = (int)(stepcnt.x + 0.4999);
  int stepcnty = (int)(stepcnt.y + 0.4999);

  stepcnt = 1.0 / stepcnt;

  float4 curr = float4(0.0, 0.0, 0.0, DELTA6);
  float2 pos;
  float2 halfstep = 0.5 * stepcnt.xy;
  invsize *= 2.0;

  // Iterating over the input texture
  pos.x = -0.5 + halfstep.x;
  for (int x = 0; x < stepcntx; x++)
  {
    pos.y = -0.5 + halfstep.y;
    for (int y = 0; y < stepcnty; y++)
    {
      float2 coord = pos.xy * invsize + coordsrc.xy;
      float3 tmpcurr = TextureInput.Sample(Sampler, coord.xy).xyz;
      float tmpweight;
      float2 dpos = pos.xy * 2.0;
      float rng = dot(dpos.xy, dpos.xy);

      // A lot of pixel loss here, according to Boris
      tmpweight = saturate(1001.0 - 1000.0 * rng); // Cutting a citcle
      tmpweight *= saturate(1.0 - rng); // Softening

      curr.xyz += tmpcurr.xyz * tmpweight;
      curr.w += tmpweight;

      pos.y += stepcnt.y;
    }

    pos.x += stepcnt.x;
  }

  curr.xyz *= 1.0 / curr.w;
  return curr.xyz;
}


////////// COLOR OPERATORS


// Miscellaneous operators
float3 lin(float3 color) { return pow(color.rgb, GAMMA); }
float3 gamma(float3 color) { return pow(color.rgb, 1.0 / GAMMA); }


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