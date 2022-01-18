////////// D4SCO Macros - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



#ifndef D4SCO_MACROS
#define D4SCO_MACROS



////////// CONCATENATORS
#define STR(x) #x
#define MRG(a, b) a##b
#define CMB(a, b) a##_##b



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



////////// REPLICATORS
#define RPL(X) RPL_##X
#define RPL_1(X) X
#define RPL_2(X) RPL_1(X)##X
#define RPL_3(X) RPL_2(X)##X
#define RPL_4(X) RPL_3(X)##X
#define RPL_5(X) RPL_4(X)##X
#define RPL_6(X) RPL_5(X)##X
#define RPL_7(X) RPL_6(X)##X
#define RPL_8(X) RPL_7(X)##X
#define RPL_9(X) RPL_8(X)##X
#define RPL_10(X) RPL_9(X)##X
#define RPL_11(X) RPL_10(X)##X
#define RPL_12(X) RPL_11(X)##X
#define RPL_13(X) RPL_12(X)##X
#define RPL_14(X) RPL_13(X)##X
#define RPL_15(X) RPL_14(X)##X
#define RPL_16(X) RPL_15(X)##X
#define RPL_17(X) RPL_16(X)##X
#define RPL_18(X) RPL_17(X)##X
#define RPL_19(X) RPL_18(X)##X
#define RPL_20(X) RPL_19(X)##X
#define RPL_21(X) RPL_20(X)##X
#define RPL_22(X) RPL_21(X)##X
#define RPL_23(X) RPL_22(X)##X
#define RPL_24(X) RPL_23(X)##X
#define RPL_25(X) RPL_24(X)##X
#define RPL_26(X) RPL_25(X)##X
#define RPL_27(X) RPL_26(X)##X
#define RPL_28(X) RPL_27(X)##X
#define RPL_29(X) RPL_28(X)##X
#define RPL_30(X) RPL_29(X)##X
#define RPL_31(X) RPL_30(X)##X
#define RPL_32(X) RPL_31(X)##X
#define RPL_33(X) RPL_32(X)##X
#define RPL_34(X) RPL_33(X)##X
#define RPL_35(X) RPL_34(X)##X
#define RPL_36(X) RPL_35(X)##X
#define RPL_37(X) RPL_36(X)##X
#define RPL_38(X) RPL_37(X)##X
#define RPL_39(X) RPL_38(X)##X
#define RPL_40(X) RPL_39(X)##X
#define RPL_41(X) RPL_40(X)##X
#define RPL_42(X) RPL_41(X)##X
#define RPL_43(X) RPL_42(X)##X
#define RPL_44(X) RPL_43(X)##X
#define RPL_45(X) RPL_44(X)##X
#define RPL_46(X) RPL_45(X)##X
#define RPL_47(X) RPL_46(X)##X
#define RPL_48(X) RPL_47(X)##X
#define RPL_49(X) RPL_48(X)##X
#define RPL_50(X) RPL_49(X)##X
#define RPL_51(X) RPL_50(X)##X
#define RPL_52(X) RPL_51(X)##X
#define RPL_53(X) RPL_52(X)##X
#define RPL_54(X) RPL_53(X)##X
#define RPL_55(X) RPL_54(X)##X
#define RPL_56(X) RPL_55(X)##X
#define RPL_57(X) RPL_56(X)##X
#define RPL_58(X) RPL_57(X)##X
#define RPL_59(X) RPL_58(X)##X
#define RPL_60(X) RPL_59(X)##X
#define RPL_61(X) RPL_60(X)##X
#define RPL_62(X) RPL_61(X)##X
#define RPL_63(X) RPL_62(X)##X
#define RPL_64(X) RPL_63(X)##X
#define RPL_65(X) RPL_64(X)##X
#define RPL_66(X) RPL_65(X)##X
#define RPL_67(X) RPL_66(X)##X
#define RPL_68(X) RPL_67(X)##X
#define RPL_69(X) RPL_68(X)##X
#define RPL_70(X) RPL_69(X)##X
#define RPL_71(X) RPL_70(X)##X
#define RPL_72(X) RPL_71(X)##X
#define RPL_73(X) RPL_72(X)##X
#define RPL_74(X) RPL_73(X)##X
#define RPL_75(X) RPL_74(X)##X
#define RPL_76(X) RPL_75(X)##X
#define RPL_77(X) RPL_76(X)##X
#define RPL_78(X) RPL_77(X)##X
#define RPL_79(X) RPL_78(X)##X
#define RPL_80(X) RPL_79(X)##X
#define RPL_81(X) RPL_80(X)##X
#define RPL_82(X) RPL_81(X)##X
#define RPL_83(X) RPL_82(X)##X
#define RPL_84(X) RPL_83(X)##X
#define RPL_85(X) RPL_84(X)##X
#define RPL_86(X) RPL_85(X)##X
#define RPL_87(X) RPL_86(X)##X
#define RPL_88(X) RPL_87(X)##X
#define RPL_89(X) RPL_88(X)##X
#define RPL_90(X) RPL_89(X)##X
#define RPL_91(X) RPL_90(X)##X
#define RPL_92(X) RPL_91(X)##X
#define RPL_93(X) RPL_92(X)##X
#define RPL_94(X) RPL_93(X)##X
#define RPL_95(X) RPL_94(X)##X
#define RPL_96(X) RPL_95(X)##X
#define RPL_97(X) RPL_96(X)##X
#define RPL_98(X) RPL_97(X)##X
#define RPL_99(X) RPL_98(X)##X
#define RPL_100(X) RPL_99(X)##X
#define RPL_101(X) RPL_100(X)##X
#define RPL_102(X) RPL_101(X)##X
#define RPL_103(X) RPL_102(X)##X
#define RPL_104(X) RPL_103(X)##X
#define RPL_105(X) RPL_104(X)##X
#define RPL_106(X) RPL_105(X)##X
#define RPL_107(X) RPL_106(X)##X
#define RPL_108(X) RPL_107(X)##X
#define RPL_109(X) RPL_108(X)##X
#define RPL_110(X) RPL_109(X)##X
#define RPL_111(X) RPL_110(X)##X
#define RPL_112(X) RPL_111(X)##X
#define RPL_113(X) RPL_112(X)##X
#define RPL_114(X) RPL_113(X)##X
#define RPL_115(X) RPL_114(X)##X
#define RPL_116(X) RPL_115(X)##X
#define RPL_117(X) RPL_116(X)##X
#define RPL_118(X) RPL_117(X)##X
#define RPL_119(X) RPL_118(X)##X
#define RPL_120(X) RPL_119(X)##X
#define RPL_121(X) RPL_120(X)##X
#define RPL_122(X) RPL_121(X)##X
#define RPL_123(X) RPL_122(X)##X
#define RPL_124(X) RPL_123(X)##X
#define RPL_125(X) RPL_124(X)##X
#define RPL_126(X) RPL_125(X)##X
#define RPL_127(X) RPL_126(X)##X
#define RPL_128(X) RPL_127(X)##X



#endif
