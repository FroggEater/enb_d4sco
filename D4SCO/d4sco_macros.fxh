////////// D4SCO Macros - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// PRIMING
#ifndef D4SCO_MACROS
#define D4SCO_MACROS



////////// CONCATENATORS
#define STR(X) #X
#define MRG(A, B) A##B



////////// RT CLEARING
void VS_Basic(inout float4 pos : SV_POSITION, inout float4 txcoord : TEXCOORD0) { pos.w = 1.0; }
float4 PS_Blank(float4 pos : SV_POSITION, float4 txcoord : TEXCOORD0) : SV_Target { return 0.0; }



////////// TECHNIQUES
#define TECH(NAME, VS, PS) \
  technique11 NAME \
  { \
    pass p0 \
    { \
      SetVertexShader(CompileShader(vs_5_0, VS)); \
      SetPixelShader(CompileShader(ps_5_0, PS)); \
    } \
  }

#define TECH2(NAME, VS1, PS1, VS2, PS2) \
  technique11 NAME \
  { \
    pass p0 \
    { \
      SetVertexShader(CompileShader(vs_5_0, VS1)); \
      SetPixelShader(CompileShader(ps_5_0, PS1)); \
    } \
    \
    pass p1 \
    { \
      SetVertexShader(CompileShader(vs_5_0, VS2)); \
      SetPixelShader(CompileShader(ps_5_0, PS2)); \
    } \
  }

#define PASS(NAME, VS, PS) \
  pass NAME \
  { \
    SetVertexShader(CompileShader(vs_5_0, VS)); \
    SetPixelShader(CompileShader(ps_5_0, PS)); \
  }



#endif
