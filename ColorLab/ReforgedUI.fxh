// ----------------------------------------------------------------------------------------------------------
// reforged ui 1.1 by the sandvich maker

// permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// the software is provided "as is" and the author disclaims all warranties with regard to this software
// including all implied warranties of merchantability and fitness. in no event shall the author be liable
// for any special, direct, indirect, or consequential damages or any damages whatsoever resulting from loss
// of use, data or profits, whether in an action of contract, negligence or other tortious action, arising
// out of or in connection with the use or performance of this software.
// ----------------------------------------------------------------------------------------------------------



#ifndef REFORGED_UI_H
#define REFORGED_UI_H



// ----------------------------------------------------------------------------------------------------------
// generic macros
// ----------------------------------------------------------------------------------------------------------
#define TO_STRING(x) #x
#define MERGE(a, b) a##b
#define COMBINE(a, b) a##_##b



// ----------------------------------------------------------------------------------------------------------
// tod calculator
// ----------------------------------------------------------------------------------------------------------
#if UI_CALCULATE_CUSTOM_TOD
    #define REMAP(v, a, b) saturate(((v) - (a)) / ((b) - (a)))
    #define REMAP_TRI(t, a, b, c) REMAP(t, t < b ? a : c, b)

#ifndef DAWN
    #define DAWN 2.0
#endif
#ifndef SUNRISE
    #define SUNRISE 7.50
#endif
#ifndef DAY
    #define DAY 13.0
#endif
#ifndef SUNSET
    #define SUNSET 18.50
#endif
#ifndef DUSK
    #define DUSK 2.0
#endif
#ifndef NIGHT
    #define NIGHT 0.0
#endif
    #define TIME WeatherAndTime.w

    static const float DawnTime = SUNRISE - DAWN * 0.5;
    static const float DuskTime = SUNSET + DUSK * 0.5;

    static const float4 TimeOfDay1 = float4(
        REMAP_TRI(TIME, SUNRISE - DAWN, DawnTime, SUNRISE),
        REMAP_TRI(TIME, DawnTime, SUNRISE, DAY),
        REMAP_TRI(TIME, SUNRISE, DAY, SUNSET),
        REMAP_TRI(TIME, DAY, SUNSET, DuskTime)
    );
    static const float4 TimeOfDay2 = float4(
        REMAP_TRI(TIME, SUNSET - DUSK, DuskTime, SUNSET + DUSK),
        TIME > DuskTime ? REMAP(TIME, DuskTime, SUNSET + DUSK) : REMAP(TIME, DawnTime, SUNRISE - DAWN),
        0.0,
        0.0
    );

    #undef REMAP
    #undef REMAP_TRI
#endif


static const float3 __DNI_WEIGHTS = float3(ENightDayFactor*(1.0-EInteriorFactor), (1.0-ENightDayFactor)*(1.0-EInteriorFactor), EInteriorFactor);



// ----------------------------------------------------------------------------------------------------------
// ui setup
// ----------------------------------------------------------------------------------------------------------
// user editables
#define UI_CATEGORY NO_CATEGORY

#define UI_CUSTOM_PREFIX "UNDEFINED"

#define UI_PREFIX_MODE NO_PREFIX
#define __FETCH_NAME UI_PREFIX_MODE

#define UI_VAR_PREFIX_MODE NO_PREFIX
#define __FETCH_VAR_NAME UI_VAR_PREFIX_MODE

#define UI_INDENT_MODE NO_INDENT
#define __FETCH_INDENTATION UI_INDENT_MODE
#define UI_INDENT_DEPTH 4
#define UI_INDENT_STYLISH_ANCHOR "|"
#define UI_INDENT_STYLISH_CHAR "\x97"
#define UI_INDENT_STYLISH_CAP ""

#define UI_SEPARATOR_MODE BUMPERS
#define __FETCH_SEPARATOR_MODE UI_SEPARATOR_MODE
#define UI_SEPARATOR_BUMPER_LEFT "\xAB\xAB\xAB "
#define UI_SEPARATOR_BUMPER_RIGHT " \xBB\xBB\xBB"

#define UI_INTERPOLATOR_MODE INTERPOLATE
#define __GET_INTERPOLATOR UI_INTERPOLATOR_MODE

#define UI_SPLITTER_ANCHOR ""
#define UI_SPLITTER_CHAR "\x97"
#define UI_SPLITTER_CAP ""
#define UI_SPLITTER_LENGTH 21
#define UI_SPLITTER_STRING "\xAB\xAB\xAB\xAB\xAB\xAB\xBB\xBB\xBB\xBB\xBB\xBB"
#define UI_SPLITTER_MODE CHAR
#define __FETCH_SPLITTER UI_SPLITTER_MODE

#define UI_BLANK_LINE_STYLE DX11
#define __FETCH_LINE_STYLE UI_BLANK_LINE_STYLE

// prefix modes
#define NO_PREFIX(name) __FETCH_INDENTATION(name)
#define PREFIX(name) __FETCH_INDENTATION(MERGE(MERGE(TO_STRING(UI_CATEGORY), ": "), name))
#define CUSTOM_PREFIX(name) __FETCH_INDENTATION(MERGE(MERGE(UI_CUSTOM_PREFIX, ": "), name))
#define VAR_PREFIX(var) MERGE(UI_CATEGORY, var)

// indent modes
#define NO_INDENT(name) name
#define INDENT(name) MERGE(WHITESPACE_STR(UI_INDENT_DEPTH), name)
#define STYLISH_INDENT(name) MERGE(MERGE(MERGE(UI_INDENT_STYLISH_ANCHOR, REPLICATOR(UI_INDENT_DEPTH)(UI_INDENT_STYLISH_CHAR)), UI_INDENT_STYLISH_CAP), name)

// separator modes
#define BUMPERS(str) MERGE(MERGE(UI_SEPARATOR_BUMPER_LEFT, str), UI_SEPARATOR_BUMPER_RIGHT)
#define COLON(str) MERGE(str, ":")
#define SIMPLE(str) str

// splitter modes
#define CHAR(num) MERGE(UI_SPLITTER_ANCHOR, MERGE(MERGE(MERGE(REPLICATE_, UI_SPLITTER_LENGTH)(UI_SPLITTER_CHAR), UI_SPLITTER_CAP), WHITESPACE_STR(num)))
#define STRING(num) MERGE(UI_SPLITTER_STRING, WHITESPACE_STR(num))

// blank parameter modes
#define DX11(var, name) int var \
< \
    string UIName = name; \
    int UIMin = 0; \
    int UIMax = 0; \
> = { 0 };
#define DX9(var, name) string var = name;

// interpolate modes
#define INTERPOLATE(type, style, archetype, var) type style##_##archetype(var)
#define DONT_INTERPOLATE(type, style, archetype, var) // crickets...



// ----------------------------------------------------------------------------------------------------------
// selectors
// ----------------------------------------------------------------------------------------------------------
#define SELECT_EI(var) var = (EInteriorFactor == 1.0 ? var##Interior : var##Exterior);
#define SELECT_DN(var) var = (ENightDayFactor > 0.5 ? var##Day : var##Night);
#define SELECT_DN_I(var) var = (EInteriorFactor == 1.0 ? var##Interior : (ENightDayFactor > 0.5 ? var##Day : var##Night));

#define SELECT_DNE_DNI(var) var = EInteriorFactor == 1.0 ? \
    ENightDayFactor > 0.5 ? var##InteriorDay : var##InteriorNight : \
    ENightDayFactor > 0.5 ? var##ExteriorDay : var##ExteriorNight;

// I kinda can't be arsed to make proper selectors for these because you shouldn't use them anyway, they're
// just there to make stuff not break (they will work, they'll just floor instead of round)
#define SELECT_TOD(var) LERP_TOD(var)
#define SELECT_TOD_I(var) LERP_TOD_I(var)
#define SELECT_TODE_DNI(var) LERP_TODE_DNI(var)
#define SELECT_TODE_TODI(var) LERP_TODE_TODI(var)



// ----------------------------------------------------------------------------------------------------------
// lerpers
// ----------------------------------------------------------------------------------------------------------
#define LERP_EI(var) SELECT_EI(var)
// #define LERP_DN(var) var = lerp(var##Night, var##Day, ENightDayFactor);
// #define LERP_DN_I(var) var = (EInteriorFactor == 1.0 ? var##Interior : lerp(var##Night, var##Day, ENightDayFactor));
#define LERP_DN(var) var = dot(float2(var##Night, var##Day), __DNI_WEIGHTS.xy);
#define LERP_DNI(var) var = dot(float3(var##Night, var##Day, var##Interior), __DNI_WEIGHTS);

#define LERP_DNE_DNI(var) var = EInteriorFactor == 1.0 ? \
    lerp(var##InteriorNight, var##InteriorDay, ENightDayFactor) : \
    lerp(var##ExteriorNight, var##ExteriorDay, ENightDayFactor);

#define LERP_TOD(var) var = \
        var##Dawn    * TimeOfDay1.x + \
        var##Sunrise * TimeOfDay1.y + \
        var##Day     * TimeOfDay1.z + \
        var##Sunset  * TimeOfDay1.w + \
        var##Dusk    * TimeOfDay2.x + \
        var##Night   * TimeOfDay2.y;

#define LERP_TOD_I(var) var = \
    EInteriorFactor == 1.0 ? var##Interior : \
        var##Dawn    * TimeOfDay1.x + \
        var##Sunrise * TimeOfDay1.y + \
        var##Day     * TimeOfDay1.z + \
        var##Sunset  * TimeOfDay1.w + \
        var##Dusk    * TimeOfDay2.x + \
        var##Night   * TimeOfDay2.y;

#define LERP_TODE_DNI(var) var = \
    EInteriorFactor == 1.0 ? \
        lerp(var##InteriorNight, var##InteriorDay, ENightDayFactor) : \
        var##ExteriorDawn    * TimeOfDay1.x + \
        var##ExteriorSunrise * TimeOfDay1.y + \
        var##ExteriorDay     * TimeOfDay1.z + \
        var##ExteriorSunset  * TimeOfDay1.w + \
        var##ExteriorDusk    * TimeOfDay2.x + \
        var##ExteriorNight   * TimeOfDay2.y;

#define LERP_TODE_TODI(var) var = \
    EInteriorFactor == 1.0 ? \
        var##InteriorDawn    * TimeOfDay1.x + \
        var##InteriorSunrise * TimeOfDay1.y + \
        var##InteriorDay     * TimeOfDay1.z + \
        var##InteriorSunset  * TimeOfDay1.w + \
        var##InteriorDusk    * TimeOfDay2.x + \
        var##InteriorNight   * TimeOfDay2.y : \
        var##ExteriorDawn    * TimeOfDay1.x + \
        var##ExteriorSunrise * TimeOfDay1.y + \
        var##ExteriorDay     * TimeOfDay1.z + \
        var##ExteriorSunset  * TimeOfDay1.w + \
        var##ExteriorDusk    * TimeOfDay2.x + \
        var##ExteriorNight   * TimeOfDay2.y;



// ----------------------------------------------------------------------------------------------------------
// special parameters
// ----------------------------------------------------------------------------------------------------------
#define MAKE_UNIQUE(str, num) MERGE(MERGE(str, WHITESPACE_STR(50)), REPLICATOR(num)("c"))
#define WHITESPACE_STR(num) REPLICATOR(num)(" ")

#define UI_BLANK(var, name) __FETCH_LINE_STYLE(var, name)
#define UI_SEPARATOR UI_BLANK(MERGE(UI_CATEGORY, _SEPARATOR), __FETCH_SEPARATOR_MODE(TO_STRING(UI_CATEGORY)))
#define UI_SEPARATOR_CUSTOM(msg) UI_BLANK(MERGE(UI_CATEGORY, _SEPARATOR), __FETCH_SEPARATOR_MODE(msg))
#define UI_SEPARATOR_UNIQUE(id, msg) UI_BLANK(MERGE(SEPARATOR_, id), __FETCH_SEPARATOR_MODE(msg))
#define UI_MESSAGE(id, msg) UI_BLANK(Message##id, msg)
#define UI_WHITESPACE(num) UI_BLANK(Whitespace##num, WHITESPACE_STR(num))
#define UI_SPLITTER(num) UI_BLANK(Splitter##num, __FETCH_SPLITTER(num))



// ----------------------------------------------------------------------------------------------------------
// multiparameter archetypes
// Any archetype you make with the right syntax is automatically available to UI_xx_MULTI(archetype, ...) but
// I couldn't think of a good way of making the UI_xx_archetype syntax work without manual copypasting.
// ----------------------------------------------------------------------------------------------------------
#define ARCHETYPE__SINGLE(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var, name, arg1, arg2, arg3, arg4)


#define ARCHETYPE__EI(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Exterior, name##" (Exterior)", arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Interior, name##" (Interior)", arg1, arg2, arg3, arg4) \
    __GET_INTERPOLATOR(static const type, lerpstyle, EI, var)


#define TEMPLATE__DN(macro, var, name, arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Day, name##" (Day)", arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Night, name##" (Night)", arg1, arg2, arg3, arg4)


#define ARCHETYPE__DN(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    TEMPLATE__DN(macro, var, name, arg1, arg2, arg3, arg4) \
    __GET_INTERPOLATOR(static const type, lerpstyle, DN, var)


#define ARCHETYPE__DN_I(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    TEMPLATE__DN(macro, var, name, arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Interior, name##" (Interior)", arg1, arg2, arg3, arg4) \
    __GET_INTERPOLATOR(static const type, lerpstyle, DN_I, var)


// Alias because this is more familiar syntax
#define ARCHETYPE__DNI ARCHETYPE__DN_I


#define ARCHETYPE__DNE_DNI(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    TEMPLATE__DN(macro, var##Exterior, name##" (Exterior)", arg1, arg2, arg3, arg4) \
    TEMPLATE__DN(macro, var##Interior, name##" (Interior)", arg1, arg2, arg3, arg4) \
    __GET_INTERPOLATOR(static const type, lerpstyle, DNE_DNI, var)


#define TEMPLATE__TOD(macro, var, name, arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Dawn, name##" (Dawn)", arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Sunrise, name##" (Sunrise)", arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Day, name##" (Day)", arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Sunset, name##" (Sunset)", arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Dusk, name##" (Dusk)", arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Night, name##" (Night)", arg1, arg2, arg3, arg4)


#define ARCHETYPE__TOD(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    TEMPLATE__TOD(macro, var, name, arg1, arg2, arg3, arg4) \
    __GET_INTERPOLATOR(static const type, lerpstyle, TOD, var)


#define ARCHETYPE__TOD_I(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    TEMPLATE__TOD(macro, var, name, arg1, arg2, arg3, arg4) \
    PROTOTYPE__UI_##macro(var##Interior, name##" (Interior)", arg1, arg2, arg3, arg4) \
    __GET_INTERPOLATOR(static const type, lerpstyle, TOD_I, var)


// Alias because this is more familiar syntax
#define ARCHETYPE__TODI ARCHETYPE__TOD_I


#define ARCHETYPE__TODE_DNI(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    TEMPLATE__TOD(macro, var##Exterior, name##" (Exterior)", arg1, arg2, arg3, arg4) \
    TEMPLATE__DN(macro, var##Interior, name##" (Interior)", arg1, arg2, arg3, arg4) \
    __GET_INTERPOLATOR(static const type, lerpstyle, TODE_DNI, var)


#define ARCHETYPE__TODE_TODI(macro, type, lerpstyle, var, name, arg1, arg2, arg3, arg4) \
    TEMPLATE__TOD(macro, var##Exterior, name##" (Exterior)", arg1, arg2, arg3, arg4) \
    TEMPLATE__TOD(macro, var##Interior, name##" (Interior)", arg1, arg2, arg3, arg4) \
    __GET_INTERPOLATOR(static const type, lerpstyle, TODE_TODI, var)



// ----------------------------------------------------------------------------------------------------------
// main parameters
// Any parameter defined with the syntax PROTOTYPE__UI_xx with the right number of arguments is automatically
// available to all archetypes.
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------
// bool
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_BOOL(var, name, def, arg2, arg3, arg4) bool var < string UIName = __FETCH_NAME(name); > = {def};
#define UI_BOOL_MULTI(archetype, var, name, def) ARCHETYPE__##archetype(BOOL, bool, SELECT, var, name, def, NULL, NULL, NULL)

// I ended up copypasting a lot manually after all... At least I have powerful multi-line editing to help me
// out with this kind of stuff. I'd recommend the VSCode + Vim Extension combination to anyone.
#define UI_BOOL(var, name, def) UI_BOOL_MULTI(SINGLE, var, name, def)
#define UI_BOOL_SINGLE(var, name, def) UI_BOOL_MULTI(SINGLE, var, name, def)
#define UI_BOOL_EI(var, name, def) UI_BOOL_MULTI(EI, var, name, def)
#define UI_BOOL_DN(var, name, def) UI_BOOL_MULTI(DN, var, name, def)
#define UI_BOOL_DNI(var, name, def) UI_BOOL_MULTI(DNI, var, name, def)
#define UI_BOOL_DN_I(var, name, def) UI_BOOL_MULTI(DN_I, var, name, def)
#define UI_BOOL_DNE_DNI(var, name, def) UI_BOOL_MULTI(DNE_DNI, var, name, def)
#define UI_BOOL_TOD(var, name, def) UI_BOOL_MULTI(TOD, var, name, def)
#define UI_BOOL_TODI(var, name, def) UI_BOOL_MULTI(TODI, var, name, def)
#define UI_BOOL_TOD_I(var, name, def) UI_BOOL_MULTI(TOD_I, var, name, def)
#define UI_BOOL_TODE_DNI(var, name, def) UI_BOOL_MULTI(TODE_DNI, var, name, def)
#define UI_BOOL_TODE_TODI(var, name, def) UI_BOOL_MULTI(TODE_TODI, var, name, def)



// ----------------------------------------------------------------------------------------------------------
// quality
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_QUALITY(var, name, minval, maxval, defval, arg4) \
    int var \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "quality"; \
        int UIMin = minval; \
        int UIMax = maxval; \
    > = {defval};

#define UI_QUALITY_MULTI(archetype, var, name, minval, maxval, defval) \
    ARCHETYPE__##archetype(QUALITY, int, SELECT, var, name, minval, maxval, defval, NULL)

#define UI_QUALITY(var, name, minval, maxval, defval) UI_QUALITY_MULTI(SINGLE, var, name, minval, maxval, defval)
#define UI_QUALITY_SINGLE(var, name, minval, maxval, defval) UI_QUALITY_MULTI(SINGLE, var, name, minval, maxval, defval)
#define UI_QUALITY_EI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(EI, var, name, minval, maxval, defval)
#define UI_QUALITY_DN(var, name, minval, maxval, defval) UI_QUALITY_MULTI(DN, var, name, minval, maxval, defval)
#define UI_QUALITY_DNI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(DNI, var, name, minval, maxval, defval)
#define UI_QUALITY_DN_I(var, name, minval, maxval, defval) UI_QUALITY_MULTI(DN_I, var, name, minval, maxval, defval)
#define UI_QUALITY_DNE_DNI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(DNE_DNI, var, name, minval, maxval, defval)
#define UI_QUALITY_TOD(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TOD, var, name, minval, maxval, defval)
#define UI_QUALITY_TODI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TODI, var, name, minval, maxval, defval)
#define UI_QUALITY_TOD_I(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TOD_I, var, name, minval, maxval, defval)
#define UI_QUALITY_TODE_DNI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TODE_DNI, var, name, minval, maxval, defval)
#define UI_QUALITY_TODE_TODI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TODE_TODI, var, name, minval, maxval, defval)



// ----------------------------------------------------------------------------------------------------------
// int
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_INT(var, name, minval, maxval, defval, arg4) \
    int var \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "Spinner"; \
        int UIMin = minval; \
        int UIMax = maxval; \
    > = {defval};

#define UI_INT_MULTI(archetype, var, name, minval, maxval, defval) \
    ARCHETYPE__##archetype(INT, int, LERP, var, name, minval, maxval, defval, NULL)

#define UI_INT(var, name, minval, maxval, defval) UI_INT_MULTI(SINGLE, var, name, minval, maxval, defval)
#define UI_INT_SINGLE(var, name, minval, maxval, defval) UI_INT_MULTI(SINGLE, var, name, minval, maxval, defval)
#define UI_INT_EI(var, name, minval, maxval, defval) UI_INT_MULTI(EI, var, name, minval, maxval, defval)
#define UI_INT_DN(var, name, minval, maxval, defval) UI_INT_MULTI(DN, var, name, minval, maxval, defval)
#define UI_INT_DNI(var, name, minval, maxval, defval) UI_INT_MULTI(DNI, var, name, minval, maxval, defval)
#define UI_INT_DN_I(var, name, minval, maxval, defval) UI_INT_MULTI(DN_I, var, name, minval, maxval, defval)
#define UI_INT_DNE_DNI(var, name, minval, maxval, defval) UI_INT_MULTI(DNE_DNI, var, name, minval, maxval, defval)
#define UI_INT_TOD(var, name, minval, maxval, defval) UI_INT_MULTI(TOD, var, name, minval, maxval, defval)
#define UI_INT_TODI(var, name, minval, maxval, defval) UI_INT_MULTI(TODI, var, name, minval, maxval, defval)
#define UI_INT_TOD_I(var, name, minval, maxval, defval) UI_INT_MULTI(TOD_I, var, name, minval, maxval, defval)
#define UI_INT_TODE_DNI(var, name, minval, maxval, defval) UI_INT_MULTI(TODE_DNI, var, name, minval, maxval, defval)
#define UI_INT_TODE_TODI(var, name, minval, maxval, defval) UI_INT_MULTI(TODE_TODI, var, name, minval, maxval, defval)



// ----------------------------------------------------------------------------------------------------------
// float
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_FLOAT(var, name, minval, maxval, defval, step) \
    float var \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "Spinner"; \
        float UIMin = minval; \
        float UIMax = maxval; \
        float UIStep = step; \
    > = {defval};

#define UI_FLOAT_MULTI(archetype, var, name, minval, maxval, defval) \
    ARCHETYPE__##archetype(FLOAT, float, LERP, var, name, minval, maxval, defval, 0.01)
#define UI_FLOAT_FINE_MULTI(archetype, var, name, minval, maxval, defval, step) \
    ARCHETYPE__##archetype(FLOAT, float, LERP, var, name, minval, maxval, defval, step)

#define UI_FLOAT(var, name, minval, maxval, defval) UI_FLOAT_MULTI(SINGLE, var, name, minval, maxval, defval)
#define UI_FLOAT_SINGLE(var, name, minval, maxval, defval) UI_FLOAT_MULTI(SINGLE, var, name, minval, maxval, defval)
#define UI_FLOAT_EI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(EI, var, name, minval, maxval, defval)
#define UI_FLOAT_DN(var, name, minval, maxval, defval) UI_FLOAT_MULTI(DN, var, name, minval, maxval, defval)
#define UI_FLOAT_DNI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(DNI, var, name, minval, maxval, defval)
#define UI_FLOAT_DN_I(var, name, minval, maxval, defval) UI_FLOAT_MULTI(DN_I, var, name, minval, maxval, defval)
#define UI_FLOAT_DNE_DNI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(DNE_DNI, var, name, minval, maxval, defval)
#define UI_FLOAT_TOD(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TOD, var, name, minval, maxval, defval)
#define UI_FLOAT_TODI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TODI, var, name, minval, maxval, defval)
#define UI_FLOAT_TOD_I(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TOD_I, var, name, minval, maxval, defval)
#define UI_FLOAT_TODE_DNI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TODE_DNI, var, name, minval, maxval, defval)
#define UI_FLOAT_TODE_TODI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TODE_TODI, var, name, minval, maxval, defval)

#define UI_FLOAT_FINE(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(SINGLE, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_SINGLE(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(SINGLE, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_EI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(EI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_DN(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(DN, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_DNI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(DNI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_DN_I(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(DN_I, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_DNE_DNI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(DNE_DNI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TOD(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TOD, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TODI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TODI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TOD_I(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TOD_I, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TODE_DNI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TODE_DNI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TODE_TODI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TODE_TODI, var, name, minval, maxval, defval, step)



// ----------------------------------------------------------------------------------------------------------
// float2
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_FLOAT2(var, name, minval, maxval, defval1, defval2) \
    float2 var \
    < \
        string UIName = __FETCH_NAME(name); \
        float UIMin = minval; \
        float UIMax = maxval; \
    > = {defval1, defval2};

#define UI_FLOAT2_MULTI(archetype, var, name, arg1, arg2, arg3, arg4) \
    ARCHETYPE__##archetype(FLOAT2, float2, LERP, var, name, arg1, arg2, arg3, arg4)

#define UI_FLOAT2(var, name, arg1, arg2, arg3, arg4) UI_FLOAT2_MULTI(SINGLE, var, name, arg1, arg2, arg3, arg4)



// ----------------------------------------------------------------------------------------------------------
// color
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_COLOR(var, name, defval1, defval2, defval3, arg4) \
    float3 var \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "color"; \
    > = {defval1, defval2, defval3};

#define UI_COLOR_MULTI(archetype, var, name, defval1, defval2, defval3) \
    ARCHETYPE__##archetype(COLOR, float3, LERP, var, name, defval1, defval2, defval3, NULL)

#define UI_COLOR(var, name, defval1, defval2, defval3) UI_COLOR_MULTI(SINGLE, var, name, defval1, defval2, defval3)
#define UI_COLOR_SINGLE(var, name, defval1, defval2, defval3) UI_COLOR_MULTI(SINGLE, var, name, defval1, defval2, defval3)
#define UI_COLOR_EI(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(EI, var, name, arg1, arg2, arg3)
#define UI_COLOR_DN(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(DN, var, name, arg1, arg2, arg3)
#define UI_COLOR_DNI(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(DNI, var, name, arg1, arg2, arg3)
#define UI_COLOR_DN_I(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(DN_I, var, name, arg1, arg2, arg3)
#define UI_COLOR_DNE_DNI(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(DNE_DNI, var, name, arg1, arg2, arg3)
#define UI_COLOR_TOD(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(TOD, var, name, arg1, arg2, arg3)
#define UI_COLOR_TODI(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(TODI, var, name, arg1, arg2, arg3)
#define UI_COLOR_TOD_I(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(TOD_I, var, name, arg1, arg2, arg3)
#define UI_COLOR_TODE_DNI(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(TODE_DNI, var, name, arg1, arg2, arg3)
#define UI_COLOR_TODE_TODI(var, name, arg1, arg2, arg3) UI_COLOR_MULTI(TODE_TODI, var, name, arg1, arg2, arg3)



// ----------------------------------------------------------------------------------------------------------
// float3
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_FLOAT3(var, name, minval, maxval, defval, arg4) \
    float3 var \
    < \
        string UIName = __FETCH_NAME(name); \
        float UIMin = minval; \
        float UIMax = maxval; \
    > = {defval, defval, defval};

#define UI_FLOAT3_MULTI(archetype, var, name, minval, maxval, defval) \
    ARCHETYPE__##archetype(FLOAT3, float3, LERP, var, name, minval, maxval, defval, NULL)

#define UI_FLOAT3(var, name, defval1, defval2, defval3) UI_FLOAT3_MULTI(SINGLE, var, name, defval1, defval2, defval3)
#define UI_FLOAT3_SINGLE(var, name, defval1, defval2, defval3) UI_FLOAT3_MULTI(SINGLE, var, name, defval1, defval2, defval3)
#define UI_FLOAT3_EI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(EI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_DN(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(DN, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_DNI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(DNI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_DN_I(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(DN_I, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_DNE_DNI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(DNE_DNI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TOD(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TOD, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TODI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TODI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TOD_I(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TOD_I, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TODE_DNI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TODE_DNI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TODE_TODI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TODE_TODI, var, name, arg1, arg2, arg3)



// ----------------------------------------------------------------------------------------------------------
// float4
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_FLOAT4(var, name, def1, def2, def3, def4) \
    float4 var  \
    < \
        string UIName = __FETCH_NAME(name); \
        float UIMin = def1; \
        float UIMax = def2; \
    > = {def3, def3, def3, def3};

#define UI_FLOAT4_MULTI(archetype, var, name, def1, def2, def3, def4) \
    ARCHETYPE__##archetype(FLOAT4, float4, LERP, var, name, def1, def2, def3, def4)

#define UI_FLOAT4(var, name, def1, def2, def3, def4) UI_FLOAT4_MULTI(SINGLE, var, name, def1, def2, def3, def4)
#define UI_FLOAT4_SINGLE(var, name, def1, def2, def3, def4) UI_FLOAT4_MULTI(SINGLE, var, name, def1, def2, def3, def4)
#define UI_FLOAT4_EI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(EI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_DN(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(DN, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_DNI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_DN_I(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(DN_I, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_DNE_DNI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(DNE_DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TOD(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TOD, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TODI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TODI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TOD_I(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TOD_I, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TODE_DNI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TODE_DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TODE_TODI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TODE_TODI, var, name, arg1, arg2, arg3, arg4)



// ----------------------------------------------------------------------------------------------------------
// color4
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_COLOR4(var, name, def1, def2, def3, def4) \
    float4 var  \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "color"; \
    > = {def1, def2, def3, def4};

#define UI_COLOR4_MULTI(archetype, var, name, def1, def2, def3, def4) \
    ARCHETYPE__##archetype(COLOR4, float4, LERP, var, name, def1, def2, def3, def4)

#define UI_COLOR4(var, name, def1, def2, def3, def4) UI_COLOR4_MULTI(SINGLE, var, name, def1, def2, def3, def4)
#define UI_COLOR4_SINGLE(var, name, def1, def2, def3, def4) UI_COLOR4_MULTI(SINGLE, var, name, def1, def2, def3, def4)
#define UI_COLOR4_EI(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(EI, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_DN(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(DN, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_DNI(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_DN_I(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(DN_I, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_DNE_DNI(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(DNE_DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_TOD(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(TOD, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_TODI(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(TODI, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_TOD_I(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(TOD_I, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_TODE_DNI(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(TODE_DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_COLOR4_TODE_TODI(var, name, arg1, arg2, arg3, arg4) UI_COLOR4_MULTI(TODE_TODI, var, name, arg1, arg2, arg3, arg4)



// ----------------------------------------------------------------------------------------------------------
// replicator collection
// ----------------------------------------------------------------------------------------------------------
#define REPLICATOR(x) REPLICATE_##x
#define REPLICATE_1(x) x
#define REPLICATE_2(x) REPLICATE_1(x)##x
#define REPLICATE_3(x) REPLICATE_2(x)##x
#define REPLICATE_4(x) REPLICATE_3(x)##x
#define REPLICATE_5(x) REPLICATE_4(x)##x
#define REPLICATE_6(x) REPLICATE_5(x)##x
#define REPLICATE_7(x) REPLICATE_6(x)##x
#define REPLICATE_8(x) REPLICATE_7(x)##x
#define REPLICATE_9(x) REPLICATE_8(x)##x
#define REPLICATE_10(x) REPLICATE_9(x)##x
#define REPLICATE_11(x) REPLICATE_10(x)##x
#define REPLICATE_12(x) REPLICATE_11(x)##x
#define REPLICATE_13(x) REPLICATE_12(x)##x
#define REPLICATE_14(x) REPLICATE_13(x)##x
#define REPLICATE_15(x) REPLICATE_14(x)##x
#define REPLICATE_16(x) REPLICATE_15(x)##x
#define REPLICATE_17(x) REPLICATE_16(x)##x
#define REPLICATE_18(x) REPLICATE_17(x)##x
#define REPLICATE_19(x) REPLICATE_18(x)##x
#define REPLICATE_20(x) REPLICATE_19(x)##x
#define REPLICATE_21(x) REPLICATE_20(x)##x
#define REPLICATE_22(x) REPLICATE_21(x)##x
#define REPLICATE_23(x) REPLICATE_22(x)##x
#define REPLICATE_24(x) REPLICATE_23(x)##x
#define REPLICATE_25(x) REPLICATE_24(x)##x
#define REPLICATE_26(x) REPLICATE_25(x)##x
#define REPLICATE_27(x) REPLICATE_26(x)##x
#define REPLICATE_28(x) REPLICATE_27(x)##x
#define REPLICATE_29(x) REPLICATE_28(x)##x
#define REPLICATE_30(x) REPLICATE_29(x)##x
#define REPLICATE_31(x) REPLICATE_30(x)##x
#define REPLICATE_32(x) REPLICATE_31(x)##x
#define REPLICATE_33(x) REPLICATE_32(x)##x
#define REPLICATE_34(x) REPLICATE_33(x)##x
#define REPLICATE_35(x) REPLICATE_34(x)##x
#define REPLICATE_36(x) REPLICATE_35(x)##x
#define REPLICATE_37(x) REPLICATE_36(x)##x
#define REPLICATE_38(x) REPLICATE_37(x)##x
#define REPLICATE_39(x) REPLICATE_38(x)##x
#define REPLICATE_40(x) REPLICATE_39(x)##x
#define REPLICATE_41(x) REPLICATE_40(x)##x
#define REPLICATE_42(x) REPLICATE_41(x)##x
#define REPLICATE_43(x) REPLICATE_42(x)##x
#define REPLICATE_44(x) REPLICATE_43(x)##x
#define REPLICATE_45(x) REPLICATE_44(x)##x
#define REPLICATE_46(x) REPLICATE_45(x)##x
#define REPLICATE_47(x) REPLICATE_46(x)##x
#define REPLICATE_48(x) REPLICATE_47(x)##x
#define REPLICATE_49(x) REPLICATE_48(x)##x
#define REPLICATE_50(x) REPLICATE_49(x)##x
#define REPLICATE_51(x) REPLICATE_50(x)##x
#define REPLICATE_52(x) REPLICATE_51(x)##x
#define REPLICATE_53(x) REPLICATE_52(x)##x
#define REPLICATE_54(x) REPLICATE_53(x)##x
#define REPLICATE_55(x) REPLICATE_54(x)##x
#define REPLICATE_56(x) REPLICATE_55(x)##x
#define REPLICATE_57(x) REPLICATE_56(x)##x
#define REPLICATE_58(x) REPLICATE_57(x)##x
#define REPLICATE_59(x) REPLICATE_58(x)##x
#define REPLICATE_60(x) REPLICATE_59(x)##x
#define REPLICATE_61(x) REPLICATE_60(x)##x
#define REPLICATE_62(x) REPLICATE_61(x)##x
#define REPLICATE_63(x) REPLICATE_62(x)##x
#define REPLICATE_64(x) REPLICATE_63(x)##x
#define REPLICATE_65(x) REPLICATE_64(x)##x
#define REPLICATE_66(x) REPLICATE_65(x)##x
#define REPLICATE_67(x) REPLICATE_66(x)##x
#define REPLICATE_68(x) REPLICATE_67(x)##x
#define REPLICATE_69(x) REPLICATE_68(x)##x
#define REPLICATE_70(x) REPLICATE_69(x)##x
#define REPLICATE_71(x) REPLICATE_70(x)##x
#define REPLICATE_72(x) REPLICATE_71(x)##x
#define REPLICATE_73(x) REPLICATE_72(x)##x
#define REPLICATE_74(x) REPLICATE_73(x)##x
#define REPLICATE_75(x) REPLICATE_74(x)##x
#define REPLICATE_76(x) REPLICATE_75(x)##x
#define REPLICATE_77(x) REPLICATE_76(x)##x
#define REPLICATE_78(x) REPLICATE_77(x)##x
#define REPLICATE_79(x) REPLICATE_78(x)##x
#define REPLICATE_80(x) REPLICATE_79(x)##x
#define REPLICATE_81(x) REPLICATE_80(x)##x
#define REPLICATE_82(x) REPLICATE_81(x)##x
#define REPLICATE_83(x) REPLICATE_82(x)##x
#define REPLICATE_84(x) REPLICATE_83(x)##x
#define REPLICATE_85(x) REPLICATE_84(x)##x
#define REPLICATE_86(x) REPLICATE_85(x)##x
#define REPLICATE_87(x) REPLICATE_86(x)##x
#define REPLICATE_88(x) REPLICATE_87(x)##x
#define REPLICATE_89(x) REPLICATE_88(x)##x
#define REPLICATE_90(x) REPLICATE_89(x)##x
#define REPLICATE_91(x) REPLICATE_90(x)##x
#define REPLICATE_92(x) REPLICATE_91(x)##x
#define REPLICATE_93(x) REPLICATE_92(x)##x
#define REPLICATE_94(x) REPLICATE_93(x)##x
#define REPLICATE_95(x) REPLICATE_94(x)##x
#define REPLICATE_96(x) REPLICATE_95(x)##x
#define REPLICATE_97(x) REPLICATE_96(x)##x
#define REPLICATE_98(x) REPLICATE_97(x)##x
#define REPLICATE_99(x) REPLICATE_98(x)##x
#define REPLICATE_100(x) REPLICATE_99(x)##x
#define REPLICATE_101(x) REPLICATE_100(x)##x
#define REPLICATE_102(x) REPLICATE_101(x)##x
#define REPLICATE_103(x) REPLICATE_102(x)##x
#define REPLICATE_104(x) REPLICATE_103(x)##x
#define REPLICATE_105(x) REPLICATE_104(x)##x
#define REPLICATE_106(x) REPLICATE_105(x)##x
#define REPLICATE_107(x) REPLICATE_106(x)##x
#define REPLICATE_108(x) REPLICATE_107(x)##x
#define REPLICATE_109(x) REPLICATE_108(x)##x
#define REPLICATE_110(x) REPLICATE_109(x)##x
#define REPLICATE_111(x) REPLICATE_110(x)##x
#define REPLICATE_112(x) REPLICATE_111(x)##x
#define REPLICATE_113(x) REPLICATE_112(x)##x
#define REPLICATE_114(x) REPLICATE_113(x)##x
#define REPLICATE_115(x) REPLICATE_114(x)##x
#define REPLICATE_116(x) REPLICATE_115(x)##x
#define REPLICATE_117(x) REPLICATE_116(x)##x
#define REPLICATE_118(x) REPLICATE_117(x)##x
#define REPLICATE_119(x) REPLICATE_118(x)##x
#define REPLICATE_120(x) REPLICATE_119(x)##x
#define REPLICATE_121(x) REPLICATE_120(x)##x
#define REPLICATE_122(x) REPLICATE_121(x)##x
#define REPLICATE_123(x) REPLICATE_122(x)##x
#define REPLICATE_124(x) REPLICATE_123(x)##x
#define REPLICATE_125(x) REPLICATE_124(x)##x
#define REPLICATE_126(x) REPLICATE_125(x)##x
#define REPLICATE_127(x) REPLICATE_126(x)##x
#define REPLICATE_128(x) REPLICATE_127(x)##x



#endif // REFORGED_UI_H