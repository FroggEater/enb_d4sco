// ----------------------------------------------------------------------------------------------------------
// REFORGED UI BY THE SANDVICH MAKER

// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
// OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
// OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ----------------------------------------------------------------------------------------------------------



#ifndef REFORGED_UI_H
#define REFORGED_UI_H



// ----------------------------------------------------------------------------------------------------------
// GENERIC MACROS
// ----------------------------------------------------------------------------------------------------------
#define TO_STRING(x) #x
#define MERGE(a, b) a##b
#define COMBINE(a, b) a##_##b



// ----------------------------------------------------------------------------------------------------------
// TOD CALCULATOR
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



// ----------------------------------------------------------------------------------------------------------
// UI SETUP
// ----------------------------------------------------------------------------------------------------------
#define UI_CATEGORY NO_CATEGORY

#define UI_CUSTOM_PREFIX "UNDEFINED"
#define UI_PREFIX_MODE NO_PREFIX
#define __FETCH_NAME UI_PREFIX_MODE

#define NO_PREFIX(name) name
#define PREFIX(name) MERGE(MERGE(TO_STRING(UI_CATEGORY), ": "), name)
#define CUSTOM_PREFIX(name) MERGE(MERGE(UI_CUSTOM_PREFIX, ": "), name)

#define UI_INTERPOLATOR_MODE INTERPOLATE
#define __GET_INTERPOLATOR UI_INTERPOLATOR_MODE

#define INTERPOLATE(type, style, archetype, var) type style##_##archetype(var)
#define DONT_INTERPOLATE(type, style, archetype, var) // crickets...



// ----------------------------------------------------------------------------------------------------------
// SELECTERS
// ----------------------------------------------------------------------------------------------------------
#define SELECT_EI(var) var = (EInteriorFactor == 1.0 ? var##Interior : var##Exterior);
#define SELECT_DN(var) var = (ENightDayFactor > 0.5 ? var##Day : var##Night);
#define SELECT_DN_I(var) var = (EInteriorFactor == 1.0 ? var##Interior : (ENightDayFactor > 0.5 ? var##Day : var##Night));

#define SELECT_DNE_DNI(var) var = EInteriorFactor == 1.0 ? \
    ENightDayFactor > 0.5 ? var##InteriorDay : var##InteriorNight : \
    ENightDayFactor > 0.5 ? var##ExteriorDay : var##ExteriorNight;

// I kinda can't be arsed to make proper selecters for these because you shouldn't use them anyway, they're
// just there to make stuff not break (they will work, they'll just floor instead of round)
#define SELECT_TOD(var) LERP_TOD(var)
#define SELECT_TOD_I(var) LERP_TOD_I(var)
#define SELECT_TODE_DNI(var) LERP_TODE_DNI(var)
#define SELECT_TODE_TODI(var) LERP_TODE_TODI(var)



// ----------------------------------------------------------------------------------------------------------
// LERPERS
// ----------------------------------------------------------------------------------------------------------
#define LERP_EI(var) SELECT_EI(var)
#define LERP_DN(var) var = lerp(var##Night, var##Day, ENightDayFactor);
#define LERP_DN_I(var) var = (EInteriorFactor == 1.0 ? var##Interior : lerp(var##Night, var##Day, ENightDayFactor));

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
// SPECIAL PARAMETERS
// ----------------------------------------------------------------------------------------------------------
// #define UI_SEPARATOR int MERGE(UI_CATEGORY, _SEPARATOR) \
// < \
//     string UIName = MERGE(MERGE("\xAB\xAB\xAB ", TO_STRING(UI_CATEGORY)), " \xBB\xBB\xBB"); \
//     int UIMin = 0; \
//     int UIMax = 0; \
// > = { 0 };


// #define UI_SEPARATOR_CUSTOM(msg) int MERGE(UI_CATEGORY, _SEPARATOR) \
// < \
//     string UIName = MERGE(MERGE("\xAB\xAB\xAB ", msg), " \xBB\xBB\xBB"); \
//     int UIMin = 0; \
//     int UIMax = 0; \
// > = { 0 };


// #define UI_SEPARATOR_UNIQUE(id, msg) int MERGE(SEPARATOR_, id) \
// < \
//     string UIName = MERGE(MERGE("\xAB\xAB\xAB ", msg), " \xBB\xBB\xBB"); \
//     int UIMin = 0; \
//     int UIMax = 0; \
// > = { 0 };


// #define UI_MESSAGE(id, msg) int MERGE(MESSAGE_, id) \
// < \
//     string UIName = msg; \
//     int UIMin = 0; \
//     int UIMax = 0; \
// > = { 0 };
#define SEPARATOR_STRING(str) MERGE(MERGE("\xAB\xAB\xAB ", str), " \xBB\xBB\xBB")
#define UI_SEPARATOR UI_INT(COMBINE(SEPARATOR, UI_CATEGORY), SEPARATOR_STRING(TO_STRING(UI_CATEGORY)), 0, 0, 0)
#define UI_SEPARATOR_CUSTOM(msg) UI_INT(COMBINE(CUSTOM_SEPARATOR, UI_CATEGORY), SEPARATOR_STRING(msg), 0, 0, 0)
#define UI_SEPARATOR_UNIQUE(id, msg) UI_INT(COMBINE(UNIQUE_SEPARATOR, id), SEPARATOR_STRING(msg), 0, 0, 0)
#define UI_MESSAGE(id, msg) UI_INT(COMBINE(MESSAGE, id), msg, 0, 0, 0)
#define UI_WHITESPACE(num) UI_MESSAGE(Whitespace##num, WHITESPACE_##num)



// ----------------------------------------------------------------------------------------------------------
// MULTIPARAMETER ARCHETYPES
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
// MAIN PARAMETERS
// Any parameter defined with the syntax PROTOTYPE__UI_xx with the right number of arguments is automatically
// available to all archetypes.
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------
// BOOL
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_BOOL(var, name, def, arg2, arg3, arg4) bool var < string UIName = __FETCH_NAME(name); > = {def};
#define UI_BOOL_MULTI(archetype, var, name, def) ARCHETYPE__##archetype(BOOL, bool, SELECT, var, name, def, NULL, NULL, NULL)

// I ended up copypasting a lot manually after all... At least I have powerful multi-line editing to help me
// out with this kind of stuff. I'd recommend the VSCode + Vim Extension combination to anyone.
#define UI_BOOL(var, name, def) UI_BOOL_MULTI(SINGLE, var, name, def)
#define UI_BOOL_SINGLE(var, name, def) UI_BOOL_MULTI(SINGLE, var, name, def)
#define UI_BOOL_EI(var, name, def) UI_BOOL_MULTI(EI, var, name, def)
#define UI_BOOL_DNI(var, name, def) UI_BOOL_MULTI(DNI, var, name, def)
#define UI_BOOL_DN_I(var, name, def) UI_BOOL_MULTI(DN_I, var, name, def)
#define UI_BOOL_DNE_DNI(var, name, def) UI_BOOL_MULTI(DNE_DNI, var, name, def)
#define UI_BOOL_TODI(var, name, def) UI_BOOL_MULTI(TODI, var, name, def)
#define UI_BOOL_TOD_I(var, name, def) UI_BOOL_MULTI(TOD_I, var, name, def)
#define UI_BOOL_TODE_DNI(var, name, def) UI_BOOL_MULTI(TODE_DNI, var, name, def)
#define UI_BOOL_TODE_TODI(var, name, def) UI_BOOL_MULTI(TODE_TODI, var, name, def)



// ----------------------------------------------------------------------------------------------------------
// QUALITY
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
#define UI_QUALITY_DNI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(DNI, var, name, minval, maxval, defval)
#define UI_QUALITY_DN_I(var, name, minval, maxval, defval) UI_QUALITY_MULTI(DN_I, var, name, minval, maxval, defval)
#define UI_QUALITY_DNE_DNI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(DNE_DNI, var, name, minval, maxval, defval)
#define UI_QUALITY_TODI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TODI, var, name, minval, maxval, defval)
#define UI_QUALITY_TOD_I(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TOD_I, var, name, minval, maxval, defval)
#define UI_QUALITY_TODE_DNI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TODE_DNI, var, name, minval, maxval, defval)
#define UI_QUALITY_TODE_TODI(var, name, minval, maxval, defval) UI_QUALITY_MULTI(TODE_TODI, var, name, minval, maxval, defval)



// ----------------------------------------------------------------------------------------------------------
// INT
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_INT(var, name, minval, maxval, defval, arg4) \
    int var \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "spinner"; \
        int UIMin = minval; \
        int UIMax = maxval; \
    > = {defval};

#define UI_INT_MULTI(archetype, var, name, minval, maxval, defval) \
    ARCHETYPE__##archetype(INT, int, SELECT, var, name, minval, maxval, defval, NULL)

#define UI_INT(var, name, minval, maxval, defval) UI_INT_MULTI(SINGLE, var, name, minval, maxval, defval)
#define UI_INT_SINGLE(var, name, minval, maxval, defval) UI_INT_MULTI(SINGLE, var, name, minval, maxval, defval)
#define UI_INT_EI(var, name, minval, maxval, defval) UI_INT_MULTI(EI, var, name, minval, maxval, defval)
#define UI_INT_DNI(var, name, minval, maxval, defval) UI_INT_MULTI(DNI, var, name, minval, maxval, defval)
#define UI_INT_DN_I(var, name, minval, maxval, defval) UI_INT_MULTI(DN_I, var, name, minval, maxval, defval)
#define UI_INT_DNE_DNI(var, name, minval, maxval, defval) UI_INT_MULTI(DNE_DNI, var, name, minval, maxval, defval)
#define UI_INT_TODI(var, name, minval, maxval, defval) UI_INT_MULTI(TODI, var, name, minval, maxval, defval)
#define UI_INT_TOD_I(var, name, minval, maxval, defval) UI_INT_MULTI(TOD_I, var, name, minval, maxval, defval)
#define UI_INT_TODE_DNI(var, name, minval, maxval, defval) UI_INT_MULTI(TODE_DNI, var, name, minval, maxval, defval)
#define UI_INT_TODE_TODI(var, name, minval, maxval, defval) UI_INT_MULTI(TODE_TODI, var, name, minval, maxval, defval)



// ----------------------------------------------------------------------------------------------------------
// FLOAT
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_FLOAT(var, name, minval, maxval, defval, step) \
    float var \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "spinner"; \
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
#define UI_FLOAT_DNI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(DNI, var, name, minval, maxval, defval)
#define UI_FLOAT_DN_I(var, name, minval, maxval, defval) UI_FLOAT_MULTI(DN_I, var, name, minval, maxval, defval)
#define UI_FLOAT_DNE_DNI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(DNE_DNI, var, name, minval, maxval, defval)
#define UI_FLOAT_TODI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TODI, var, name, minval, maxval, defval)
#define UI_FLOAT_TOD_I(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TOD_I, var, name, minval, maxval, defval)
#define UI_FLOAT_TODE_DNI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TODE_DNI, var, name, minval, maxval, defval)
#define UI_FLOAT_TODE_TODI(var, name, minval, maxval, defval) UI_FLOAT_MULTI(TODE_TODI, var, name, minval, maxval, defval)

#define UI_FLOAT_FINE(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(SINGLE, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_SINGLE(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(SINGLE, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_EI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(EI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_DNI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(DNI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_DN_I(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(DN_I, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_DNE_DNI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(DNE_DNI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TODI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TODI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TOD_I(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TOD_I, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TODE_DNI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TODE_DNI, var, name, minval, maxval, defval, step)
#define UI_FLOAT_FINE_TODE_TODI(var, name, minval, maxval, defval, step) UI_FLOAT_FINE_MULTI(TODE_TODI, var, name, minval, maxval, defval, step)



// ----------------------------------------------------------------------------------------------------------
// FLOAT3
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_FLOAT3(var, name, defval1, defval2, defval3, arg4) \
    float3 var \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "color"; \
    > = {defval1, defval2, defval3};

#define UI_FLOAT3_MULTI(archetype, var, name, defval1, defval2, defval3) \
    ARCHETYPE__##archetype(FLOAT3, float3, LERP, var, name, defval1, defval2, defval3, NULL)

#define UI_FLOAT3(var, name, defval1, defval2, defval3) UI_FLOAT3_MULTI(SINGLE, var, name, defval1, defval2, defval3)
#define UI_FLOAT3_SINGLE(var, name, defval1, defval2, defval3) UI_FLOAT3_MULTI(SINGLE, var, name, defval1, defval2, defval3)
#define UI_FLOAT3_EI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(EI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_DNI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(DNI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_DN_I(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(DN_I, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_DNE_DNI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(DNE_DNI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TODI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TODI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TOD_I(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TOD_I, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TODE_DNI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TODE_DNI, var, name, arg1, arg2, arg3)
#define UI_FLOAT3_TODE_TODI(var, name, arg1, arg2, arg3) UI_FLOAT3_MULTI(TODE_TODI, var, name, arg1, arg2, arg3)



// ----------------------------------------------------------------------------------------------------------
// FLOAT4
// ----------------------------------------------------------------------------------------------------------
#define PROTOTYPE__UI_FLOAT4(var, name, def1, def2, def3, def4) \
    float4 var  \
    < \
        string UIName = __FETCH_NAME(name); \
        string UIWidget = "vector"; \
    > = {def1, def2, def3, def4};

#define UI_FLOAT4_MULTI(archetype, var, name, def1, def2, def3, def4) \
    ARCHETYPE__##archetype(FLOAT4, float4, LERP, var, name, def1, def2, def3, def4)

#define UI_FLOAT4(var, name, def1, def2, def3, def4) UI_FLOAT4_MULTI(SINGLE, var, name, def1, def2, def3, def4)
#define UI_FLOAT4_SINGLE(var, name, def1, def2, def3, def4) UI_FLOAT4_MULTI(SINGLE, var, name, def1, def2, def3, def4)
#define UI_FLOAT4_EI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(EI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_DNI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_DN_I(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(DN_I, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_DNE_DNI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(DNE_DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TODI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TODI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TOD_I(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TOD_I, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TODE_DNI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TODE_DNI, var, name, arg1, arg2, arg3, arg4)
#define UI_FLOAT4_TODE_TODI(var, name, arg1, arg2, arg3, arg4) UI_FLOAT4_MULTI(TODE_TODI, var, name, arg1, arg2, arg3, arg4)



// ----------------------------------------------------------------------------------------------------------
// WHITESPACE COLLECTION (my pride and joy)
// ----------------------------------------------------------------------------------------------------------
#define WHITESPACE_1   " "
#define WHITESPACE_2   "  "
#define WHITESPACE_3   "   "
#define WHITESPACE_4   "    "
#define WHITESPACE_5   "     "
#define WHITESPACE_6   "      "
#define WHITESPACE_7   "       "
#define WHITESPACE_8   "        "
#define WHITESPACE_9   "         "
#define WHITESPACE_10  "          "
#define WHITESPACE_11  "           "
#define WHITESPACE_12  "            "
#define WHITESPACE_13  "             "
#define WHITESPACE_14  "              "
#define WHITESPACE_15  "               "
#define WHITESPACE_16  "                "
#define WHITESPACE_17  "                 "
#define WHITESPACE_18  "                  "
#define WHITESPACE_19  "                   "
#define WHITESPACE_20  "                    "
#define WHITESPACE_21  "                     "
#define WHITESPACE_22  "                      "
#define WHITESPACE_23  "                       "
#define WHITESPACE_24  "                        "
#define WHITESPACE_25  "                         "
#define WHITESPACE_26  "                          "
#define WHITESPACE_27  "                           "
#define WHITESPACE_28  "                            "
#define WHITESPACE_29  "                             "
#define WHITESPACE_30  "                              "
#define WHITESPACE_31  "                               "
#define WHITESPACE_32  "                                "
#define WHITESPACE_33  "                                 "
#define WHITESPACE_34  "                                  "
#define WHITESPACE_35  "                                   "
#define WHITESPACE_36  "                                    "
#define WHITESPACE_37  "                                     "
#define WHITESPACE_38  "                                      "
#define WHITESPACE_39  "                                       "
#define WHITESPACE_40  "                                        "
#define WHITESPACE_41  "                                         "
#define WHITESPACE_42  "                                          "
#define WHITESPACE_43  "                                           "
#define WHITESPACE_44  "                                            "
#define WHITESPACE_45  "                                             "
#define WHITESPACE_46  "                                              "
#define WHITESPACE_47  "                                               "
#define WHITESPACE_48  "                                                "
#define WHITESPACE_49  "                                                 "
#define WHITESPACE_50  "                                                  "
#define WHITESPACE_51  "                                                   "
#define WHITESPACE_52  "                                                    "
#define WHITESPACE_53  "                                                     "
#define WHITESPACE_54  "                                                      "
#define WHITESPACE_55  "                                                       "
#define WHITESPACE_56  "                                                        "
#define WHITESPACE_57  "                                                         "
#define WHITESPACE_58  "                                                          "
#define WHITESPACE_59  "                                                           "
#define WHITESPACE_60  "                                                            "
#define WHITESPACE_61  "                                                             "
#define WHITESPACE_62  "                                                              "
#define WHITESPACE_63  "                                                               "
#define WHITESPACE_64  "                                                                "
#define WHITESPACE_65  "                                                                 "
#define WHITESPACE_66  "                                                                  "
#define WHITESPACE_67  "                                                                   "
#define WHITESPACE_68  "                                                                    "
#define WHITESPACE_69  "                                                                     "
#define WHITESPACE_70  "                                                                      "
#define WHITESPACE_71  "                                                                       "
#define WHITESPACE_72  "                                                                        "
#define WHITESPACE_73  "                                                                         "
#define WHITESPACE_74  "                                                                          "
#define WHITESPACE_75  "                                                                           "
#define WHITESPACE_76  "                                                                            "
#define WHITESPACE_77  "                                                                             "
#define WHITESPACE_78  "                                                                              "
#define WHITESPACE_79  "                                                                               "
#define WHITESPACE_80  "                                                                                "
#define WHITESPACE_81  "                                                                                 "
#define WHITESPACE_82  "                                                                                  "
#define WHITESPACE_83  "                                                                                   "
#define WHITESPACE_84  "                                                                                    "
#define WHITESPACE_85  "                                                                                     "
#define WHITESPACE_86  "                                                                                      "
#define WHITESPACE_87  "                                                                                       "
#define WHITESPACE_88  "                                                                                        "
#define WHITESPACE_89  "                                                                                         "
#define WHITESPACE_90  "                                                                                          "
#define WHITESPACE_91  "                                                                                           "
#define WHITESPACE_92  "                                                                                            "
#define WHITESPACE_93  "                                                                                             "
#define WHITESPACE_94  "                                                                                              "
#define WHITESPACE_95  "                                                                                               "
#define WHITESPACE_96  "                                                                                                "
#define WHITESPACE_97  "                                                                                                 "
#define WHITESPACE_98  "                                                                                                  "
#define WHITESPACE_99  "                                                                                                   "
#define WHITESPACE_100 "                                                                                                    "
#define WHITESPACE_101 "                                                                                                     "
#define WHITESPACE_102 "                                                                                                      "
#define WHITESPACE_103 "                                                                                                       "
#define WHITESPACE_104 "                                                                                                        "
#define WHITESPACE_105 "                                                                                                         "
#define WHITESPACE_106 "                                                                                                          "
#define WHITESPACE_107 "                                                                                                           "
#define WHITESPACE_108 "                                                                                                            "
#define WHITESPACE_109 "                                                                                                             "
#define WHITESPACE_110 "                                                                                                              "
#define WHITESPACE_111 "                                                                                                               "
#define WHITESPACE_112 "                                                                                                                "
#define WHITESPACE_113 "                                                                                                                 "
#define WHITESPACE_114 "                                                                                                                  "
#define WHITESPACE_115 "                                                                                                                   "
#define WHITESPACE_116 "                                                                                                                    "
#define WHITESPACE_117 "                                                                                                                     "
#define WHITESPACE_118 "                                                                                                                      "
#define WHITESPACE_119 "                                                                                                                       "
#define WHITESPACE_120 "                                                                                                                        "
#define WHITESPACE_121 "                                                                                                                         "
#define WHITESPACE_122 "                                                                                                                          "
#define WHITESPACE_123 "                                                                                                                           "
#define WHITESPACE_124 "                                                                                                                            "
#define WHITESPACE_125 "                                                                                                                             "
#define WHITESPACE_126 "                                                                                                                              "
#define WHITESPACE_127 "                                                                                                                               "
#define WHITESPACE_128 "                                                                                                                                "



#endif // REFORGED_UI_H