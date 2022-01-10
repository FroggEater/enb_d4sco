static const float PI = 3.1415926535897932384626433832795;
static const float rPI = 1.0 / PI;

float random(in float2 uv)
{
    float2 noise = (frac(sin(dot(uv , float2(12.9898,78.233) * 2.0)) * 43758.5453));
    return abs(noise.x + noise.y) * 0.5;
}