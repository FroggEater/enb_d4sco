////////// D4SCO UI - 1.0
////////// by FroggEater
//////////
////////// > visit http://enbdev.com for ENBSeries updates
////////// > visit the Nexus for D4SCO updates



////////// PRIMING
#ifndef D4SCO_UI
#define D4SCO_UI



////////// INCLUDES
#include "d4sco_macros.fxh"



////////// PARAMS
#define CHSPL "-"
#define CHSEP "="

#define PRB "|=  "
#define PRN "|-  "
#define PRM "  "
#define PRC "| "

#define SFB " ?"
#define SFC " :"



/////////// BASIC ELEMENTS
#define UI_BLANK(V, N) \
  int V <string UIName = N; int UIMin = 0; int UIMax = 0;> = {0};

#define UI_SPC(X) UI_BLANK(iSPC##X, REPL(X)(" "))
#define UI_SPL(X) UI_BLANK(iSPL##X, REPL(X)(CHSPL))
#define UI_SEP(X) UI_BLANK(iSEP##X, REPL(X)(CHSEP))
#define UI_MSG(X, M) UI_BLANK(iMSG##X, PRM##M)
#define UI_CAT(X, M) UI_BLANK(iCAT##X, PRC##M##SFC)

#define UI_BOOL(V, N, D) \
  bool V <string UIName = PRB##N##SFB;> = {D};

#define UI_INT(V, N, MI, MA, D) \
  int V <string UIName = PRN##N; string UIWidget = "Spinner"; int UIMin = MI; int UIMax = MA;> = {D};

#define UI_FLOAT_STEP(V, N, MI, MA, D, S) \
  float V <string UIName = PRN##N; string UIWidget = "Spinner"; float UIMin = MI; float UIMax = MA; float UIStep = S;> = {D};
#define UI_FLOAT(V, N, MI, MA, D) UI_FLOAT_STEP(V, N, MI, MA, D, 0.01)



#endif
