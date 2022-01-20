////////// D4SCO UI - 0.0.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// PRIMERS
#ifndef D4SCO_UI
#define D4SCO_UI



////////// PARAMS
// Chars
#define CH_SPL "-"
#define CH_SEP "="
#define LENGTH 100

// Prefixes
#define PR_B "|-- "
#define PR_N "|   "
#define PR_M "  "
#define PR_C "| "

// Suffixes
#define SF_B " ?"
#define SF_C " :"



/////////// BASIC ELEMENTS
#define UI_BLANK(V, N) \
  int V <string UIName = N; int UIMin = 0; int UIMax = 0;> = {0};

#define UI_SPC(X) UI_BLANK(iSPC##X, REPL(X)(" "))
#define UI_SPL(X) UI_BLANK(iSPL##X, REPL(LENGTH)(CH_SPL)##REPL(X)(" "))
#define UI_SEP(X) UI_BLANK(iSEP##X, REPL(LENGTH)(CH_SEP)##REPL(X)(" "))
#define UI_MSG(X, M) UI_BLANK(iMSG##X, PR_M##M)
#define UI_CAT(X, M) UI_BLANK(iCAT##X, PR_C##M##SF_C)

#define UI_BOOL(V, N, D) \
  bool V <string UIName = PR_B##N##SF_B;> = {D};

#define UI_INT(V, N, MI, MA, D) \
  int V <string UIName = PR_N##N; string UIWidget = "Spinner"; int UIMin = MI; int UIMax = MA;> = {D};

#define UI_FLOAT_STEP(V, N, MI, MA, D, S) \
  float V <string UIName = PR_N##N; string UIWidget = "Spinner"; float UIMin = MI; float UIMax = MA; float UIStep = S;> = {D};
#define UI_FLOAT(V, N, MI, MA, D) UI_FLOAT_STEP(V, N, MI, MA, D, 0.01)



////////// REPLICATORS
#define REPL(X) REPL_##X
#define REPL_1(X) X
#define REPL_2(X) REPL_1(X)##X
#define REPL_3(X) REPL_2(X)##X
#define REPL_4(X) REPL_3(X)##X
#define REPL_5(X) REPL_4(X)##X
#define REPL_6(X) REPL_5(X)##X
#define REPL_7(X) REPL_6(X)##X
#define REPL_8(X) REPL_7(X)##X
#define REPL_9(X) REPL_8(X)##X
#define REPL_10(X) REPL_9(X)##X
#define REPL_11(X) REPL_10(X)##X
#define REPL_12(X) REPL_11(X)##X
#define REPL_13(X) REPL_12(X)##X
#define REPL_14(X) REPL_13(X)##X
#define REPL_15(X) REPL_14(X)##X
#define REPL_16(X) REPL_15(X)##X
#define REPL_17(X) REPL_16(X)##X
#define REPL_18(X) REPL_17(X)##X
#define REPL_19(X) REPL_18(X)##X
#define REPL_20(X) REPL_19(X)##X
#define REPL_21(X) REPL_20(X)##X
#define REPL_22(X) REPL_21(X)##X
#define REPL_23(X) REPL_22(X)##X
#define REPL_24(X) REPL_23(X)##X
#define REPL_25(X) REPL_24(X)##X
#define REPL_26(X) REPL_25(X)##X
#define REPL_27(X) REPL_26(X)##X
#define REPL_28(X) REPL_27(X)##X
#define REPL_29(X) REPL_28(X)##X
#define REPL_30(X) REPL_29(X)##X
#define REPL_31(X) REPL_30(X)##X
#define REPL_32(X) REPL_31(X)##X
#define REPL_33(X) REPL_32(X)##X
#define REPL_34(X) REPL_33(X)##X
#define REPL_35(X) REPL_34(X)##X
#define REPL_36(X) REPL_35(X)##X
#define REPL_37(X) REPL_36(X)##X
#define REPL_38(X) REPL_37(X)##X
#define REPL_39(X) REPL_38(X)##X
#define REPL_40(X) REPL_39(X)##X
#define REPL_41(X) REPL_40(X)##X
#define REPL_42(X) REPL_41(X)##X
#define REPL_43(X) REPL_42(X)##X
#define REPL_44(X) REPL_43(X)##X
#define REPL_45(X) REPL_44(X)##X
#define REPL_46(X) REPL_45(X)##X
#define REPL_47(X) REPL_46(X)##X
#define REPL_48(X) REPL_47(X)##X
#define REPL_49(X) REPL_48(X)##X
#define REPL_50(X) REPL_49(X)##X
#define REPL_51(X) REPL_50(X)##X
#define REPL_52(X) REPL_51(X)##X
#define REPL_53(X) REPL_52(X)##X
#define REPL_54(X) REPL_53(X)##X
#define REPL_55(X) REPL_54(X)##X
#define REPL_56(X) REPL_55(X)##X
#define REPL_57(X) REPL_56(X)##X
#define REPL_58(X) REPL_57(X)##X
#define REPL_59(X) REPL_58(X)##X
#define REPL_60(X) REPL_59(X)##X
#define REPL_61(X) REPL_60(X)##X
#define REPL_62(X) REPL_61(X)##X
#define REPL_63(X) REPL_62(X)##X
#define REPL_64(X) REPL_63(X)##X
#define REPL_65(X) REPL_64(X)##X
#define REPL_66(X) REPL_65(X)##X
#define REPL_67(X) REPL_66(X)##X
#define REPL_68(X) REPL_67(X)##X
#define REPL_69(X) REPL_68(X)##X
#define REPL_70(X) REPL_69(X)##X
#define REPL_71(X) REPL_70(X)##X
#define REPL_72(X) REPL_71(X)##X
#define REPL_73(X) REPL_72(X)##X
#define REPL_74(X) REPL_73(X)##X
#define REPL_75(X) REPL_74(X)##X
#define REPL_76(X) REPL_75(X)##X
#define REPL_77(X) REPL_76(X)##X
#define REPL_78(X) REPL_77(X)##X
#define REPL_79(X) REPL_78(X)##X
#define REPL_80(X) REPL_79(X)##X
#define REPL_81(X) REPL_80(X)##X
#define REPL_82(X) REPL_81(X)##X
#define REPL_83(X) REPL_82(X)##X
#define REPL_84(X) REPL_83(X)##X
#define REPL_85(X) REPL_84(X)##X
#define REPL_86(X) REPL_85(X)##X
#define REPL_87(X) REPL_86(X)##X
#define REPL_88(X) REPL_87(X)##X
#define REPL_89(X) REPL_88(X)##X
#define REPL_90(X) REPL_89(X)##X
#define REPL_91(X) REPL_90(X)##X
#define REPL_92(X) REPL_91(X)##X
#define REPL_93(X) REPL_92(X)##X
#define REPL_94(X) REPL_93(X)##X
#define REPL_95(X) REPL_94(X)##X
#define REPL_96(X) REPL_95(X)##X
#define REPL_97(X) REPL_96(X)##X
#define REPL_98(X) REPL_97(X)##X
#define REPL_99(X) REPL_98(X)##X
#define REPL_100(X) REPL_99(X)##X
#define REPL_101(X) REPL_100(X)##X
#define REPL_102(X) REPL_101(X)##X
#define REPL_103(X) REPL_102(X)##X
#define REPL_104(X) REPL_103(X)##X
#define REPL_105(X) REPL_104(X)##X
#define REPL_106(X) REPL_105(X)##X
#define REPL_107(X) REPL_106(X)##X
#define REPL_108(X) REPL_107(X)##X
#define REPL_109(X) REPL_108(X)##X
#define REPL_110(X) REPL_109(X)##X
#define REPL_111(X) REPL_110(X)##X
#define REPL_112(X) REPL_111(X)##X
#define REPL_113(X) REPL_112(X)##X
#define REPL_114(X) REPL_113(X)##X
#define REPL_115(X) REPL_114(X)##X
#define REPL_116(X) REPL_115(X)##X
#define REPL_117(X) REPL_116(X)##X
#define REPL_118(X) REPL_117(X)##X
#define REPL_119(X) REPL_118(X)##X
#define REPL_120(X) REPL_119(X)##X
#define REPL_121(X) REPL_120(X)##X
#define REPL_122(X) REPL_121(X)##X
#define REPL_123(X) REPL_122(X)##X
#define REPL_124(X) REPL_123(X)##X
#define REPL_125(X) REPL_124(X)##X
#define REPL_126(X) REPL_125(X)##X
#define REPL_127(X) REPL_126(X)##X
#define REPL_128(X) REPL_127(X)##X



#endif
