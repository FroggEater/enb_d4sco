///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//   ooooooooo.   ooooo ooooo          .oooooo.    ooooooooo.   ooooo ooo        ooooo   //
//   `888   `Y88. `888' `888'         d8P'  `Y8b   `888   `Y88. `888' `88.       .888'   //
//    888   .d88'  888   888         888            888   .d88'  888   888b     d'888    //
//    888ooo88P'   888   888         888            888ooo88P'   888   8 Y88. .P  888    //
//    888          888   888         888     ooooo  888`88b.     888   8  `888'   888    //
//    888          888   888       o `88.    .88'   888  `88b.   888   8    Y     888    //
//   o888o        o888o o888ooooood8  `Y8bood8P'   o888o  o888o o888o o8o        o888o   //
//                                                                                       //
//                               FEAR THE COMMONWEALTH                                   //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////
// Created by: TreyM, Adyss, Dr_Mabuse1981, --JawZ--, and kingeric1992                   //
///////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////
// ENB KITCHEN UI MACROS                        //
//                                              //
// INSPIRED BY THESANDVICHMAKER'S REFORGED UI   //
// AUTHOR: TREYM                                //
//////////////////////////////////////////////////

// CUSTOMIZABLE VARIBLES /////////////////////////
    // Specify Divider Character
    #define DIVIDER                  "\x97"  // —

// SPECIAL CHARACTERS ////////////////////////////
// UI_MSG(1, "This ENB is" COPYRIGHT "2018")    //
// This reads as: "This ENB is © 2018"          //
//////////////////////////////////////////////////
    #define ARROWQ                   "\x7F"  // ^?
    #define BULLET                   "\x95"  // •
    #define CENT                     "\xA2"  // ¢
    #define DEGREE                   "\xB0"  // °
    #define LONGDASH                 "\x97"  // —
    #define MICRO                    "\xB5"  // µ
    #define PERTHOUSAND              "\x89"  // ‰
    #define PLUSMINUS                "\xB1"  // ±
    #define SPLITBAR                 "\xA6"  // ¦
    #define MULTIPLY                 "\xD7"  // ×

    #define COPYRIGHT               " \xA9 " // ©
    #define RESTRICTED              " \xAE " // ®
    #define TRADEMARK                "\x99"  // ™

// STATIC CONSTANT MACROS ////////////////////////
    #define SC_BOOL(name, value) \
    static const bool   name = value;

    #define SC_INT(name, value) \
    static const int    name = value;

    #define SC_INT2(name, value) \
    static const int2   name = value;

    #define SC_INT3(name, value) \
    static const int3   name = value;

    #define SC_INT4(name, value) \
     static const int4   name = value;

    #define SC_FLOAT(name, value) \
    static const float  name = value;

    #define SC_FLOAT2(name, value) \
    static const float2 name = value;

    #define SC_FLOAT3(name, value) \
    static const float3 name = value;

    #define SC_FLOAT4(name, value) \
    static const float4 name = value;

// DNI LERP MACRO ////////////////////////////////

// Hack value used in Interior specific factor functions
float InteriorFactor(float4 Params012) {
/// Similar to EInteriorFactor

/// Implementation example;
///   float fBrightness = lerp(Exterior, Interior, InteriorFactor(Params01[2]))
///   color.xyz *= fBrightness;

  float valIntHack=0;
    if (Params012.w>=1.000190 && Params012.w<=1.000210) valIntHack=1;  /// Interior, Params01[2].w - Brightness

  return valIntHack;
}

// Hack value used in Dungeon specific factor functions
float DungeonFactor(float4 Params012) {
/// Similar to EInteriorFactor

/// Implementation example;
///   float fBrightness = lerp(Exterior, Dungeon, DungeonFactor(Params01[2]))
///   color.xyz *= fBrightness;

  float valDunHack=0;
    if (Params012.w>=1.000090 && Params012.w<=1.000110) valDunHack=1;  /// Dungeon, Params01[2].w - Brightness

  return valDunHack;
}

    #define DNI(day, night, interior) \
    lerp(lerp(night, day, ENightDayFactor), interior, InteriorFactor(Params01[3]))

    #define DNID(ext_day, ext_night, interior, dungeon) \
    lerp(lerp(lerp(ext_night, ext_day, ENightDayFactor), interior, InteriorFactor(Params01[2])), dungeon, DungeonFactor(Params01[2]))

//    #define DNI3(ext_day, ext_night, int_day, int_night, dun_day, dun_night) \
//    lerp(lerp(lerp(ext_night, ext_day, Exterior NightDayFactor), lerp(int_night, int_day, Exterior NightDayFactor), InteriorFactor(Params01[2])), lerp(dun_night, dun_day, Exterior NightDayFactor), DungeonFactor(Params01[2]))


// BOOLEAN MACRO /////////////////////////////////
    #define UI_BOOL(var, label, defval) \
    bool var < \
        string UIName   =  label; \
    >                   = {defval};

// INTEGER MACROS ////////////////////////////////
    #define UI_INT(var, label, minval, maxval, defval) \
    int	var             < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
        int UIMin       =  minval; \
        int UIMax       =  maxval; \
    >                   = {defval};
        // DNI
        #define DNI_INT(var, label, minval, maxval, defval) \
        UI_INT(var##_DAY, label " Day", minval, maxval, defval) \
        UI_INT(var##_NIGHT, label " Night", minval, maxval, defval) \
        UI_INT(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        SC_INT(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_INT(var, label, minval, maxval, defval) \
        UI_INT(var##_DAY, label " Day", minval, maxval, defval) \
        UI_INT(var##_NIGHT, label " Night", minval, maxval, defval) \
        UI_INT(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        UI_INT(var##_DUNGEON, label " Dungeon", minval, maxval, defval) \
        SC_FLOAT(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_INT(var, label, minval, maxval, defval) \
        UI_INT(var##_EXT_DAY, label " Exterior Day", minval, maxval, defval) \
        UI_INT(var##_EXT_NIGHT, label " Exterior Night", minval, maxval, defval) \
        UI_INT(var##_INT_DAY, label " Interior Day", minval, maxval, defval) \
        UI_INT(var##_INT_NIGHT, label " Interior Night", minval, maxval, defval) \
        UI_INT(var##_DUN_DAY, label " Dungeon Day", minval, maxval, defval) \
        UI_INT(var##_DUN_NIGHT, label " Dungeon Night", minval, maxval, defval) \
        SC_INT(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

    #define UI_INT2(var, label, minval, maxval, val1, val2) \
    int2 var            < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
        int UIMin       =  minval; \
        int UIMax       =  maxval; \
    >                   = {val1, val2};
        // DNI
        #define DNI_INT2(var, label, minval, maxval, val1, val2) \
        UI_INT2(var##_DAY, label " Day", minval, maxval, val1, val2) \
        UI_INT2(var##_NIGHT, label " Night", minval, maxval, val1, val2) \
        UI_INT2(var##_INTERIOR, label " Interior", minval, maxval, val1, val2) \
        SC_INT2(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_INT2(var, label, minval, maxval, defval) \
        UI_INT2(var##_DAY, label " Day", minval, maxval, defval) \
        UI_INT2(var##_NIGHT, label " Night", minval, maxval, defval) \
        UI_INT2(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        UI_INT2(var##_DUNGEON, label " Dungeon", minval, maxval, defval) \
        SC_INT2(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_INT2(var, label, minval, maxval, defval) \
        UI_INT2(var##_EXT_DAY, label " Exterior Day", minval, maxval, defval) \
        UI_INT2(var##_EXT_NIGHT, label " Exterior Night", minval, maxval, defval) \
        UI_INT2(var##_INT_DAY, label " Interior Day", minval, maxval, defval) \
        UI_INT2(var##_INT_NIGHT, label " Interior Night", minval, maxval, defval) \
        UI_INT2(var##_DUN_DAY, label " Dungeon Day", minval, maxval, defval) \
        UI_INT2(var##_DUN_NIGHT, label " Dungeon Night", minval, maxval, defval) \
        SC_INT2(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

    #define UI_INT3(var, label, minval, maxval, val1, val2, val3) \
    int3 var            < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
        int UIMin       =  minval; \
        int UIMax       =  maxval; \
    >                   = {val1, val2, val3};
        // DNI
        #define DNI_INT3(var, label, minval, maxval, val1, val2, val3) \
        UI_INT3(var##_DAY, label " Day", minval, maxval, val1, val2, val3) \
        UI_INT3(var##_NIGHT, label " Night", minval, maxval, val1, val2, val3) \
        UI_INT3(var##_INTERIOR, label " Interior", minval, maxval, val1, val2, val3) \
        SC_INT3(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_INT3(var, label, minval, maxval, defval) \
        UI_INT3(var##_DAY, label " Day", minval, maxval, defval) \
        UI_INT3(var##_NIGHT, label " Night", minval, maxval, defval) \
        UI_INT3(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        UI_INT3(var##_DUNGEON, label " Dungeon", minval, maxval, defval) \
        SC_INT3(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_INT3(var, label, minval, maxval, defval) \
        UI_INT3(var##_EXT_DAY, label " Exterior Day", minval, maxval, defval) \
        UI_INT3(var##_EXT_NIGHT, label " Exterior Night", minval, maxval, defval) \
        UI_INT3(var##_INT_DAY, label " Interior Day", minval, maxval, defval) \
        UI_INT3(var##_INT_NIGHT, label " Interior Night", minval, maxval, defval) \
        UI_INT3(var##_DUN_DAY, label " Dungeon Day", minval, maxval, defval) \
        UI_INT3(var##_DUN_NIGHT, label " Dungeon Night", minval, maxval, defval) \
        SC_INT3(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

    #define UI_INT4(var, label, minval, maxval, val1, val2, val3, val4) \
    int4 var            < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
        int UIMin       =  minval; \
        int UIMax       =  maxval; \
    >                   = {val1, val2, val3, val4};
        // DNI
        #define DNI_INT4(var, label, minval, maxval, val1, val2, val3, val4) \
        UI_INT4(var##_DAY, label " Day", minval, maxval, val1, val2, val3, val4) \
        UI_INT4(var##_NIGHT, label " Night", minval, maxval, val1, val2, val3, val4) \
        UI_INT4(var##_INTERIOR, label " Interior", minval, maxval, val1, val2, val3, val4) \
        SC_INT4(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_INT4(var, label, minval, maxval, defval) \
        UI_INT4(var##_DAY, label " Day", minval, maxval, defval) \
        UI_INT4(var##_NIGHT, label " Night", minval, maxval, defval) \
        UI_INT4(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        UI_INT4(var##_DUNGEON, label " Dungeon", minval, maxval, defval) \
        SC_INT4(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_INT4(var, label, minval, maxval, defval) \
        UI_INT4(var##_EXT_DAY, label " Exterior Day", minval, maxval, defval) \
        UI_INT4(var##_EXT_NIGHT, label " Exterior Night", minval, maxval, defval) \
        UI_INT4(var##_INT_DAY, label " Interior Day", minval, maxval, defval) \
        UI_INT4(var##_INT_NIGHT, label " Interior Night", minval, maxval, defval) \
        UI_INT4(var##_DUN_DAY, label " Dungeon Day", minval, maxval, defval) \
        UI_INT4(var##_DUN_NIGHT, label " Dungeon Night", minval, maxval, defval) \
        SC_INT4(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

    #define UI_QUALITY(var, label, minval, maxval, defval) \
    int var             < \
        string UIName   = label; \
        string UIWidget = "Quality"; \
        int UIMin       = minval; \
        int UIMax       = maxval; \
    >                   = {defval};

        // DNI (A bit silly, but why not?)
        #define DNI_QUALITY(var, label, minval, maxval) \
        UI_QUALITY(var##_DAY, label " Day", minval, maxval, defval) \
        UI_QUALITY(var##_NIGHT, label " Night", minval, maxval, defval) \
        UI_QUALITY(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        SC_INT(var, DNI(var##_DAY * 1.0, var##_NIGHT * 1.0, var##_INTERIOR * 1.0))

        // DNID (A bit silly, but why not?)
        #define DNID_QUALITY(var, label, minval, maxval) \
        UI_QUALITY(var##_DAY, label " Day", minval, maxval, defval) \
        UI_QUALITY(var##_NIGHT, label " Night", minval, maxval, defval) \
        UI_QUALITY(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        UI_QUALITY(var##_DUNGEON, label " Dungeon", minval, maxval, defval) \
        SC_INT(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3 (A bit silly, but why not?)
        #define DNI3_QUALITY(var, label, minval, maxval, defval) \
        UI_QUALITY(var##_EXT_DAY, label " Exterior Day", minval, maxval, defval) \
        UI_QUALITY(var##_EXT_NIGHT, label " Exterior Night", minval, maxval, defval) \
        UI_QUALITY(var##_INT_DAY, label " Interior Day", minval, maxval, defval) \
        UI_QUALITY(var##_INT_NIGHT, label " Interior Night", minval, maxval, defval) \
        UI_QUALITY(var##_DUN_DAY, label " Dungeon Day", minval, maxval, defval) \
        UI_QUALITY(var##_DUN_NIGHT, label " Dungeon Night", minval, maxval, defval) \
        SC_INT(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

// FLOAT MACROS //////////////////////////////////
    #define UI_FLOAT(var, label, minval, maxval, defval) \
    float var           < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
        float UIMin     =  minval; \
        float UIMax     =  maxval; \
    >                   = {defval};
        // DNI
        #define DNI_FLOAT(var, label, minval, maxval, defval) \
        UI_FLOAT(var##_DAY, label " Day", minval, maxval, defval) \
        UI_FLOAT(var##_NIGHT, label " Night", minval, maxval, defval) \
        UI_FLOAT(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        SC_FLOAT(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_FLOAT(var, label, minval, maxval, defval) \
        UI_FLOAT(var##_DAY, label " Exterior Day", minval, maxval, defval) \
        UI_FLOAT(var##_NIGHT, label " Exterior Night", minval, maxval, defval) \
        UI_FLOAT(var##_INTERIOR, label " Interior", minval, maxval, defval) \
        UI_FLOAT(var##_DUNGEON, label " Dungeon", minval, maxval, defval) \
        SC_FLOAT(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_FLOAT(var, label, minval, maxval, defval) \
        UI_FLOAT(var##_EXT_DAY, label " Exterior Day", minval, maxval, defval) \
        UI_FLOAT(var##_EXT_NIGHT, label " Exterior Night", minval, maxval, defval) \
        UI_FLOAT(var##_INT_DAY, label " Interior Day", minval, maxval, defval) \
        UI_FLOAT(var##_INT_NIGHT, label " Interior Night", minval, maxval, defval) \
        UI_FLOAT(var##_DUN_DAY, label " Dungeon Day", minval, maxval, defval) \
        UI_FLOAT(var##_DUN_NIGHT, label " Dungeon Night", minval, maxval, defval) \
        SC_FLOAT(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

    #define UI_FLOAT_FINE(var, label, precision, minval, maxval, defval) \
    float var           < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
        float UIMin     =  minval; \
        float UIMax     =  maxval; \
        float UIStep    =  precision; \
    >                   = {defval};
        // DNI
        #define DNI_FLOAT_FINE(var, label, precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_DAY, label " Day", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_NIGHT, label " Night", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_INTERIOR, label " Interior", precision, minval, maxval, defval) \
        SC_FLOAT(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_FLOAT_FINE(var, label, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_DAY, label " Exterior Day", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_NIGHT, label " Exterior Night", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_INTERIOR, label " Interior", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_DUNGEON, label " Dungeon", precision, minval, maxval, defval) \
        SC_FLOAT(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_FLOAT_FINE(var, label, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_EXT_DAY, label " Exterior Day", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_EXT_NIGHT, label " Exterior Night", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_INT_DAY, label " Interior Day", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_INT_NIGHT, label " Interior Night", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_DUN_DAY, label " Dungeon Day", precision, minval, maxval, defval) \
        UI_FLOAT_FINE(var##_DUN_NIGHT, label " Dungeon Night", precision, minval, maxval, defval) \
        SC_FLOAT(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

// FLOAT2 MACRO //////////////////////////////////
    #define UI_FLOAT2(var, label, val1, val2) \
    float2 var          < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
    >                   = {val1, val2};
        // DNI
        #define DNI_FLOAT2(var, label, val1, val2) \
        UI_FLOAT2(var##_DAY, label " Day", val1, val2) \
        UI_FLOAT2(var##_NIGHT, label " Night", val1, val2) \
        UI_FLOAT2(var##_INTERIOR, label " Interior", val1, val2) \
        SC_FLOAT2(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_FLOAT2(var, label, val1, val2) \
        UI_FLOAT2(var##_DAY, label " Day", val1, val2) \
        UI_FLOAT2(var##_NIGHT, label " Night", val1, val2) \
        UI_FLOAT2(var##_INTERIOR, label " Interior", val1, val2) \
        UI_FLOAT2(var##_DUNGEON, label " Dungeon", val1, val2) \
        SC_FLOAT2(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_FLOAT2(var, label, val1, val2) \
        UI_FLOAT2(var##_EXT_DAY, label " Exterior Day", val1, val2) \
        UI_FLOAT2(var##_EXT_NIGHT, label " Exterior Night", val1, val2) \
        UI_FLOAT2(var##_INT_DAY, label " Interior Day", val1, val2) \
        UI_FLOAT2(var##_INT_NIGHT, label " Interior Night", val1, val2) \
        UI_FLOAT2(var##_DUN_DAY, label " Dungeon Day", val1, val2) \
        UI_FLOAT2(var##_DUN_NIGHT, label " Dungeon Night", val1, val2) \
        SC_FLOAT2(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

// FLOAT3 MACRO //////////////////////////////////
    #define UI_FLOAT3(var, label, val1, val2, val3) \
    float3 var          < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
    >                   = {val1, val2, val3};
        // DNI
        #define DNI_FLOAT3(var, label, val1, val2, val3) \
        UI_FLOAT3(var##_DAY, label " Day", val1, val2, val3) \
        UI_FLOAT3(var##_NIGHT, label " Night", val1, val2, val3) \
        UI_FLOAT3(var##_INTERIOR, label " Interior", val1, val2, val3) \
        SC_FLOAT3(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_FLOAT3(var, label, val1, val2, val3) \
        UI_FLOAT3(var##_DAY, label " Exterior Day", val1, val2, val3) \
        UI_FLOAT3(var##_NIGHT, label " Exterior Night", val1, val2, val3) \
        UI_FLOAT3(var##_INTERIOR, label " Interior", val1, val2, val3) \
        UI_FLOAT3(var##_DUNGEON, label " Dungeon", val1, val2, val3) \
        SC_FLOAT3(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_FLOAT3(var, label, val1, val2, val3) \
        UI_FLOAT3(var##_EXT_DAY, label " Exterior Day", val1, val2, val3) \
        UI_FLOAT3(var##_EXT_NIGHT, label " Exterior Night", val1, val2, val3) \
        UI_FLOAT3(var##_INT_DAY, label " Interior Day", val1, val2, val3) \
        UI_FLOAT3(var##_INT_NIGHT, label " Interior Night", val1, val2, val3) \
        UI_FLOAT3(var##_DUN_DAY, label " Dungeon Day", val1, val2, val3) \
        UI_FLOAT3(var##_DUN_NIGHT, label " Dungeon Night", val1, val2, val3) \
        SC_FLOAT3(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

// COLOR MACROS //////////////////////////////////
    #define UI_COLOR(var, label, val1, val2, val3) \
    float3	var         < \
        string UIName   =  label; \
        string UIWidget = "color"; \
    >                   = {val1, val2, val3};
        // DNI
        #define DNI_COLOR(var, label, val1, val2, val3) \
        UI_COLOR(var##_DAY, label " Day", val1, val2, val3) \
        UI_COLOR(var##_NIGHT, label " Night", val1, val2, val3) \
        UI_COLOR(var##_INTERIOR, label " Interior", val1, val2, val3) \
        SC_FLOAT3(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_COLOR(var, label, val1, val2, val3) \
        UI_COLOR(var##_DAY, label " Exterior Day", val1, val2, val3) \
        UI_COLOR(var##_NIGHT, label " Exterior Night", val1, val2, val3) \
        UI_COLOR(var##_INTERIOR, label " Interior", val1, val2, val3) \
        UI_COLOR(var##_DUNGEON, label " Dungeon", val1, val2, val3) \
        SC_FLOAT3(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_COLOR(var, label, val1, val2, val3) \
        UI_COLOR(var##_EXT_DAY, label " Exterior Day", val1, val2, val3) \
        UI_COLOR(var##_EXT_NIGHT, label " Exterior Night", val1, val2, val3) \
        UI_COLOR(var##_INT_DAY, label " Interior Day", val1, val2, val3) \
        UI_COLOR(var##_INT_NIGHT, label " Interior Night", val1, val2, val3) \
        UI_COLOR(var##_DUN_DAY, label " Dungeon Day", val1, val2, val3) \
        UI_COLOR(var##_DUN_NIGHT, label " Dungeon Night", val1, val2, val3) \
        SC_FLOAT3(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

    #define UI_RGBA(var, label, val1, val2, val3, val4) \
    float4 var          < \
        string UIName   =  label; \
        string UIWidget = "color"; \
    >                   = {val1, val2, val3, val4};
        // DNI
        #define DNI_RGBA(var, label, val1, val2, val3, val4) \
        UI_RGBA(var##_DAY, label " Day", val1, val2, val3, val4) \
        UI_RGBA(var##_NIGHT, label " Night", val1, val2, val3, val4) \
        UI_RGBA(var##_INTERIOR, label " Interior", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_RGBA(var, label, val1, val2, val3, val4) \
        UI_RGBA(var##_DAY, label " Exterior Day", val1, val2, val3, val4) \
        UI_RGBA(var##_NIGHT, label " Exterior Night", val1, val2, val3, val4) \
        UI_RGBA(var##_INTERIOR, label " Interior", val1, val2, val3, val4) \
        UI_RGBA(var##_DUNGEON, label " Dungeon", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_RGBA(var, label, val1, val2, val3, val4) \
        UI_RGBA(var##_EXT_DAY, label " Exterior Day", val1, val2, val3, val4) \
        UI_RGBA(var##_EXT_NIGHT, label " Exterior Night", val1, val2, val3, val4) \
        UI_RGBA(var##_INT_DAY, label " Interior Day", val1, val2, val3, val4) \
        UI_RGBA(var##_INT_NIGHT, label " Interior Night", val1, val2, val3, val4) \
        UI_RGBA(var##_DUN_DAY, label " Dungeon Day", val1, val2, val3, val4) \
        UI_RGBA(var##_DUN_NIGHT, label " Dungeon Night", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

// FLOAT4 MACRO //////////////////////////////////
    #define UI_FLOAT4(var, label, val1, val2, val3, val4) \
    float4 var          < \
        string UIName   =  label; \
        string UIWidget = "spinner"; \
    >                   = {val1, val2, val3, val4};
        // DNI
        #define DNI_FLOAT4(var, label, val1, val2, val3, val4) \
        UI_FLOAT4(var##_DAY, label " Day", val1, val2, val3, val4) \
        UI_FLOAT4(var##_NIGHT, label " Night", val1, val2, val3, val4) \
        UI_FLOAT4(var##_INTERIOR, label " Interior", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_FLOAT4(var, label, val1, val2, val3, val4) \
        UI_FLOAT4(var##_DAY, label " Exterior Day", val1, val2, val3, val4) \
        UI_FLOAT4(var##_NIGHT, label " Exterior Night", val1, val2, val3, val4) \
        UI_FLOAT4(var##_INTERIOR, label " Interior", val1, val2, val3, val4) \
        UI_FLOAT4(var##_DUNGEON, label " Dungeon", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_FLOAT4(var, label, val1, val2, val3, val4) \
        UI_FLOAT4(var##_EXT_DAY, label " Exterior Day", val1, val2, val3, val4) \
        UI_FLOAT4(var##_EXT_NIGHT, label " Exterior Night", val1, val2, val3, val4) \
        UI_FLOAT4(var##_INT_DAY, label " Interior Day", val1, val2, val3, val4) \
        UI_FLOAT4(var##_INT_NIGHT, label " Interior Night", val1, val2, val3, val4) \
        UI_FLOAT4(var##_DUN_DAY, label " Dungeon Day", val1, val2, val3, val4) \
        UI_FLOAT4(var##_DUN_NIGHT, label " Dungeon Night", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

// VECTOR MACRO //////////////////////////////////
    #define UI_VECTOR(var, label, val1, val2, val3, val4) \
    float4 var          < \
        string UIName   =  label; \
        string UIWidget = "vector"; \
    >                   = {val1, val2, val3, val4};
        // DNI
        #define DNI_VECTOR(var, label, val1, val2, val3, val4) \
        UI_VECTOR(var##_DAY, label " Day", val1, val2, val3, val4) \
        UI_VECTOR(var##_NIGHT, label " Night", val1, val2, val3, val4) \
        UI_VECTOR(var##_INTERIOR, label " Interior", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNI(var##_DAY, var##_NIGHT, var##_INTERIOR))

        // DNID
        #define DNID_VECTOR(var, label, val1, val2, val3, val4) \
        UI_VECTOR(var##_DAY, label " Exterior Day", val1, val2, val3, val4) \
        UI_VECTOR(var##_NIGHT, label " Exterior Night", val1, val2, val3, val4) \
        UI_VECTOR(var##_INTERIOR, label " Interior", val1, val2, val3, val4) \
        UI_VECTOR(var##_DUNGEON, label " Dungeon", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNID(var##_DAY, var##_NIGHT, var##_INTERIOR, var##_DUNGEON))
/*
        // DNI3
        #define DNI3_VECTOR(var, label, val1, val2, val3, val4) \
        UI_VECTOR(var##_EXT_DAY, label " Exterior Day", val1, val2, val3, val4) \
        UI_VECTOR(var##_EXT_NIGHT, label " Exterior Night", val1, val2, val3, val4) \
        UI_VECTOR(var##_INT_DAY, label " Interior Day", val1, val2, val3, val4) \
        UI_VECTOR(var##_INT_NIGHT, label " Interior Night", val1, val2, val3, val4) \
        UI_VECTOR(var##_DUN_DAY, label " Dungeon Day", val1, val2, val3, val4) \
        UI_VECTOR(var##_DUN_NIGHT, label " Dungeon Night", val1, val2, val3, val4) \
        SC_FLOAT4(var, DNI3(var##_EXT_DAY, var##_EXT_NIGHT, var##_INT_DAY, var##_INT_NIGHT, var##_DUN_DAY, var##_DUN_NIGHT))
*/

// SAMPLER MACROS ////////////////////////////////
    #define SAMPLER(name, filter, uv) \
    SamplerState name   { \
        Filter          =  MIN_MAG_MIP_##filter; \
        AddressU        =  uv; \
        AddressV        =  uv; \
    };

// TEXTURE MACRO /////////////////////////////////
    #define TEXTURE(name, path) \
    Texture2D name      < string ResourceName = path; >;

// MESSAGE MACRO /////////////////////////////////
    #define UI_MSG(x, label) \
    int MSG_##x          < \
        string UIName   =  label; \
        int UIMin       =  0; \
        int UIMax       =  0; \
    >                   = {0};

// STRING MACRO //////////////////////////////////
    #define UI_STRING(x, label) \
    string STRING_##x = label;
    // Always goes to bottom of UI list in DX11 ENB

// TECHNIQUE MACRO ///////////////////////////////
    #define TECHNIQUE( a0, a1 ) technique11 CONCATE(TECHNIQUE_NAME, a0)  { a1 }
    #define RT(a0) string RenderTarget = STRING(RenderTarget##a0)
    #define ID(a0) string UIName = #a0

// FULL PASS MACRO ///////////////////////////////
    #define PASS_FULL( a0, a1, a2 ) pass a0 \
    { SetVertexShader( CompileShader(vs_5_0, a1)); \
      SetPixelShader( CompileShader(ps_5_0, a2)); }

// SIMPLIFIED PASS MACRO /////////////////////////
    #define PASS( a0) pass p0 \
    { SetPixelShader( CompileShader(ps_5_0, a0)); }


// DIVIDER ///////////////////////////////////////
    #define UI_DIVIDER(x) \
    int divider##x < \
        string UIName   =  DIVIDER_##x; \
        int UIMin       =  0; \
        int UIMax       =  0; \
    >                   = {0};

    // Multiplies the DIVIDER character
    #define x6(x)      x##x##x##x##x##x
    #define x24(x)     x6(x)##x6(x)##x6(x)##x6(x)
    #define EXPAND(x)  x24(x)##x24(x)//##x24(x)

    // Here we goooooooo
    #define DIVIDER_1  EXPAND    (DIVIDER)
    #define DIVIDER_2  DIVIDER_1  DIVIDER
    #define DIVIDER_3  DIVIDER_2  DIVIDER
    #define DIVIDER_4  DIVIDER_3  DIVIDER
    #define DIVIDER_5  DIVIDER_4  DIVIDER
    #define DIVIDER_6  DIVIDER_5  DIVIDER
    #define DIVIDER_7  DIVIDER_6  DIVIDER
    #define DIVIDER_8  DIVIDER_7  DIVIDER
    #define DIVIDER_9  DIVIDER_8  DIVIDER
    #define DIVIDER_10 DIVIDER_9  DIVIDER
    #define DIVIDER_20 DIVIDER_10 DIVIDER
    #define DIVIDER_21 DIVIDER_20 DIVIDER
    #define DIVIDER_22 DIVIDER_21 DIVIDER
    #define DIVIDER_23 DIVIDER_22 DIVIDER
    #define DIVIDER_24 DIVIDER_23 DIVIDER
    #define DIVIDER_25 DIVIDER_24 DIVIDER
    #define DIVIDER_26 DIVIDER_25 DIVIDER
    #define DIVIDER_27 DIVIDER_26 DIVIDER
    #define DIVIDER_28 DIVIDER_27 DIVIDER
    #define DIVIDER_29 DIVIDER_28 DIVIDER
    #define DIVIDER_30 DIVIDER_29 DIVIDER
    #define DIVIDER_31 DIVIDER_30 DIVIDER
    #define DIVIDER_32 DIVIDER_31 DIVIDER
    #define DIVIDER_33 DIVIDER_32 DIVIDER
    #define DIVIDER_34 DIVIDER_33 DIVIDER
    #define DIVIDER_35 DIVIDER_34 DIVIDER
    #define DIVIDER_36 DIVIDER_35 DIVIDER
    #define DIVIDER_37 DIVIDER_36 DIVIDER
    #define DIVIDER_38 DIVIDER_37 DIVIDER
    #define DIVIDER_39 DIVIDER_38 DIVIDER
    #define DIVIDER_40 DIVIDER_39 DIVIDER
    #define DIVIDER_41 DIVIDER_40 DIVIDER
    #define DIVIDER_42 DIVIDER_41 DIVIDER
    #define DIVIDER_43 DIVIDER_42 DIVIDER
    #define DIVIDER_44 DIVIDER_43 DIVIDER
    #define DIVIDER_45 DIVIDER_44 DIVIDER
    #define DIVIDER_46 DIVIDER_45 DIVIDER
    #define DIVIDER_47 DIVIDER_46 DIVIDER
    #define DIVIDER_48 DIVIDER_47 DIVIDER
    #define DIVIDER_49 DIVIDER_48 DIVIDER
    #define DIVIDER_50 DIVIDER_49 DIVIDER
    #define DIVIDER_51 DIVIDER_50 DIVIDER
    #define DIVIDER_52 DIVIDER_51 DIVIDER
    #define DIVIDER_53 DIVIDER_52 DIVIDER
    #define DIVIDER_54 DIVIDER_53 DIVIDER
    #define DIVIDER_55 DIVIDER_54 DIVIDER
    #define DIVIDER_56 DIVIDER_55 DIVIDER
    #define DIVIDER_57 DIVIDER_56 DIVIDER
    #define DIVIDER_58 DIVIDER_57 DIVIDER
    #define DIVIDER_59 DIVIDER_58 DIVIDER
    #define DIVIDER_60 DIVIDER_59 DIVIDER
    #define DIVIDER_61 DIVIDER_60 DIVIDER
    #define DIVIDER_62 DIVIDER_61 DIVIDER
    #define DIVIDER_63 DIVIDER_62 DIVIDER
    #define DIVIDER_64 DIVIDER_63 DIVIDER
    #define DIVIDER_65 DIVIDER_64 DIVIDER
    #define DIVIDER_66 DIVIDER_65 DIVIDER
    #define DIVIDER_67 DIVIDER_66 DIVIDER
    #define DIVIDER_68 DIVIDER_67 DIVIDER
    #define DIVIDER_69 DIVIDER_68 DIVIDER
    #define DIVIDER_70 DIVIDER_69 DIVIDER
    #define DIVIDER_71 DIVIDER_70 DIVIDER
    #define DIVIDER_72 DIVIDER_71 DIVIDER
    #define DIVIDER_73 DIVIDER_72 DIVIDER
    #define DIVIDER_74 DIVIDER_73 DIVIDER
    #define DIVIDER_75 DIVIDER_74 DIVIDER
    #define DIVIDER_76 DIVIDER_75 DIVIDER
    #define DIVIDER_77 DIVIDER_76 DIVIDER
    #define DIVIDER_78 DIVIDER_77 DIVIDER
    #define DIVIDER_79 DIVIDER_78 DIVIDER
    #define DIVIDER_80 DIVIDER_79 DIVIDER
    #define DIVIDER_81 DIVIDER_80 DIVIDER
    #define DIVIDER_82 DIVIDER_81 DIVIDER
    #define DIVIDER_83 DIVIDER_82 DIVIDER
    #define DIVIDER_84 DIVIDER_83 DIVIDER
    #define DIVIDER_85 DIVIDER_84 DIVIDER
    #define DIVIDER_86 DIVIDER_85 DIVIDER
    #define DIVIDER_87 DIVIDER_86 DIVIDER
    #define DIVIDER_88 DIVIDER_87 DIVIDER
    #define DIVIDER_89 DIVIDER_88 DIVIDER
    #define DIVIDER_90 DIVIDER_89 DIVIDER
    #define DIVIDER_91 DIVIDER_90 DIVIDER
    #define DIVIDER_92 DIVIDER_91 DIVIDER
    #define DIVIDER_93 DIVIDER_92 DIVIDER
    #define DIVIDER_94 DIVIDER_93 DIVIDER
    #define DIVIDER_95 DIVIDER_94 DIVIDER
    #define DIVIDER_96 DIVIDER_95 DIVIDER
    #define DIVIDER_97 DIVIDER_96 DIVIDER
    #define DIVIDER_98 DIVIDER_97 DIVIDER
    #define DIVIDER_99 DIVIDER_98 DIVIDER
    // We're not done. 99 more to go...

// BLANK DIVIDER /////////////////////////////////
    #define UI_BLANK(x) \
    int blank##x < \
        string UIName   = BLANKSPACE_##x; \
        int UIMin       =  0; \
        int UIMax       =  0; \
    >                   = {0};

    // Here we go again...
    #define BLANKSPACE    " "
    #define BLANKSPACE_1  BLANKSPACE
    #define BLANKSPACE_2  BLANKSPACE_1  BLANKSPACE
    #define BLANKSPACE_3  BLANKSPACE_2  BLANKSPACE
    #define BLANKSPACE_4  BLANKSPACE_3  BLANKSPACE
    #define BLANKSPACE_5  BLANKSPACE_4  BLANKSPACE
    #define BLANKSPACE_6  BLANKSPACE_5  BLANKSPACE
    #define BLANKSPACE_7  BLANKSPACE_6  BLANKSPACE
    #define BLANKSPACE_8  BLANKSPACE_7  BLANKSPACE
    #define BLANKSPACE_9  BLANKSPACE_8  BLANKSPACE
    #define BLANKSPACE_10 BLANKSPACE_9  BLANKSPACE
    #define BLANKSPACE_11 BLANKSPACE_10 BLANKSPACE
    #define BLANKSPACE_12 BLANKSPACE_11 BLANKSPACE
    #define BLANKSPACE_13 BLANKSPACE_12 BLANKSPACE
    #define BLANKSPACE_14 BLANKSPACE_13 BLANKSPACE
    #define BLANKSPACE_15 BLANKSPACE_14 BLANKSPACE
    #define BLANKSPACE_16 BLANKSPACE_15 BLANKSPACE
    #define BLANKSPACE_17 BLANKSPACE_16 BLANKSPACE
    #define BLANKSPACE_18 BLANKSPACE_17 BLANKSPACE
    #define BLANKSPACE_19 BLANKSPACE_18 BLANKSPACE
    #define BLANKSPACE_20 BLANKSPACE_19 BLANKSPACE
    #define BLANKSPACE_21 BLANKSPACE_20 BLANKSPACE
    #define BLANKSPACE_22 BLANKSPACE_21 BLANKSPACE
    #define BLANKSPACE_23 BLANKSPACE_22 BLANKSPACE
    #define BLANKSPACE_24 BLANKSPACE_23 BLANKSPACE
    #define BLANKSPACE_25 BLANKSPACE_24 BLANKSPACE
    #define BLANKSPACE_26 BLANKSPACE_25 BLANKSPACE
    #define BLANKSPACE_27 BLANKSPACE_26 BLANKSPACE
    #define BLANKSPACE_28 BLANKSPACE_27 BLANKSPACE
    #define BLANKSPACE_29 BLANKSPACE_28 BLANKSPACE
    #define BLANKSPACE_30 BLANKSPACE_29 BLANKSPACE
    #define BLANKSPACE_31 BLANKSPACE_30 BLANKSPACE
    #define BLANKSPACE_32 BLANKSPACE_31 BLANKSPACE
    #define BLANKSPACE_33 BLANKSPACE_32 BLANKSPACE
    #define BLANKSPACE_34 BLANKSPACE_33 BLANKSPACE
    #define BLANKSPACE_35 BLANKSPACE_34 BLANKSPACE
    #define BLANKSPACE_36 BLANKSPACE_35 BLANKSPACE
    #define BLANKSPACE_37 BLANKSPACE_36 BLANKSPACE
    #define BLANKSPACE_38 BLANKSPACE_37 BLANKSPACE
    #define BLANKSPACE_39 BLANKSPACE_38 BLANKSPACE
    #define BLANKSPACE_40 BLANKSPACE_39 BLANKSPACE
    #define BLANKSPACE_41 BLANKSPACE_40 BLANKSPACE
    #define BLANKSPACE_42 BLANKSPACE_41 BLANKSPACE
    #define BLANKSPACE_43 BLANKSPACE_42 BLANKSPACE
    #define BLANKSPACE_44 BLANKSPACE_43 BLANKSPACE
    #define BLANKSPACE_45 BLANKSPACE_44 BLANKSPACE
    #define BLANKSPACE_46 BLANKSPACE_45 BLANKSPACE
    #define BLANKSPACE_47 BLANKSPACE_46 BLANKSPACE
    #define BLANKSPACE_48 BLANKSPACE_47 BLANKSPACE
    #define BLANKSPACE_49 BLANKSPACE_48 BLANKSPACE
    #define BLANKSPACE_50 BLANKSPACE_49 BLANKSPACE
    #define BLANKSPACE_51 BLANKSPACE_50 BLANKSPACE
    #define BLANKSPACE_52 BLANKSPACE_51 BLANKSPACE
    #define BLANKSPACE_53 BLANKSPACE_52 BLANKSPACE
    #define BLANKSPACE_54 BLANKSPACE_53 BLANKSPACE
    #define BLANKSPACE_55 BLANKSPACE_54 BLANKSPACE
    #define BLANKSPACE_56 BLANKSPACE_55 BLANKSPACE
    #define BLANKSPACE_57 BLANKSPACE_56 BLANKSPACE
    #define BLANKSPACE_58 BLANKSPACE_57 BLANKSPACE
    #define BLANKSPACE_59 BLANKSPACE_58 BLANKSPACE
    #define BLANKSPACE_60 BLANKSPACE_59 BLANKSPACE
    #define BLANKSPACE_61 BLANKSPACE_60 BLANKSPACE
    #define BLANKSPACE_62 BLANKSPACE_61 BLANKSPACE
    #define BLANKSPACE_63 BLANKSPACE_62 BLANKSPACE
    #define BLANKSPACE_64 BLANKSPACE_63 BLANKSPACE
    #define BLANKSPACE_65 BLANKSPACE_64 BLANKSPACE
    #define BLANKSPACE_66 BLANKSPACE_65 BLANKSPACE
    #define BLANKSPACE_67 BLANKSPACE_66 BLANKSPACE
    #define BLANKSPACE_68 BLANKSPACE_67 BLANKSPACE
    #define BLANKSPACE_69 BLANKSPACE_68 BLANKSPACE
    #define BLANKSPACE_70 BLANKSPACE_69 BLANKSPACE
    #define BLANKSPACE_71 BLANKSPACE_70 BLANKSPACE
    #define BLANKSPACE_72 BLANKSPACE_71 BLANKSPACE
    #define BLANKSPACE_73 BLANKSPACE_72 BLANKSPACE
    #define BLANKSPACE_74 BLANKSPACE_73 BLANKSPACE
    #define BLANKSPACE_75 BLANKSPACE_74 BLANKSPACE
    #define BLANKSPACE_76 BLANKSPACE_75 BLANKSPACE
    #define BLANKSPACE_77 BLANKSPACE_76 BLANKSPACE
    #define BLANKSPACE_78 BLANKSPACE_77 BLANKSPACE
    #define BLANKSPACE_79 BLANKSPACE_78 BLANKSPACE
    #define BLANKSPACE_80 BLANKSPACE_79 BLANKSPACE
    #define BLANKSPACE_81 BLANKSPACE_80 BLANKSPACE
    #define BLANKSPACE_82 BLANKSPACE_81 BLANKSPACE
    #define BLANKSPACE_83 BLANKSPACE_82 BLANKSPACE
    #define BLANKSPACE_84 BLANKSPACE_83 BLANKSPACE
    #define BLANKSPACE_85 BLANKSPACE_84 BLANKSPACE
    #define BLANKSPACE_86 BLANKSPACE_85 BLANKSPACE
    #define BLANKSPACE_87 BLANKSPACE_86 BLANKSPACE
    #define BLANKSPACE_88 BLANKSPACE_87 BLANKSPACE
    #define BLANKSPACE_89 BLANKSPACE_88 BLANKSPACE
    #define BLANKSPACE_90 BLANKSPACE_89 BLANKSPACE
    #define BLANKSPACE_91 BLANKSPACE_90 BLANKSPACE
    #define BLANKSPACE_92 BLANKSPACE_91 BLANKSPACE
    #define BLANKSPACE_93 BLANKSPACE_92 BLANKSPACE
    #define BLANKSPACE_94 BLANKSPACE_93 BLANKSPACE
    #define BLANKSPACE_95 BLANKSPACE_94 BLANKSPACE
    #define BLANKSPACE_96 BLANKSPACE_95 BLANKSPACE
    #define BLANKSPACE_97 BLANKSPACE_96 BLANKSPACE
    #define BLANKSPACE_98 BLANKSPACE_97 BLANKSPACE
    #define BLANKSPACE_99 BLANKSPACE_98 BLANKSPACE
    // Finally done...

// BONUS ROUND ///////////////////////////////////

// Call Backbuffer lazily ////////////////////////
#define BACKBUFFER(uv) TextureColor.Sample(PointSampler, uv)

#define CONCATE(a0, a1) a0##a1
#define STRING(a0) #a0

#define FILE(p) p
