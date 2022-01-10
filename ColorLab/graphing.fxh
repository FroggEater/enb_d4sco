// ----------------------------------------------------------------------------------------------------------
// graphing include file by the sandvich maker

// permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// the software is provided "as is" and the author disclaims all warranties with regard to this software
// including all implied warranties of merchantability and fitness. in no event shall the author be liable
// for any special, direct, indirect, or consequential damages or any damages whatsoever resulting from loss
// of use, data or profits, whether in an action of contract, negligence or other tortious action, arising
// out of or in connection with the use or performance of this software.
// ----------------------------------------------------------------------------------------------------------


#ifndef REFORGED_GRAPHING_H
#define REFORGED_GRAPHING_H


#define remap(v, a, b) (((v) - (a)) / ((b) - (a)))
#define min2(v) min(v.x, v.y)
#define max2(v) max(v.x, v.y)


// default plot line color
#define GRAPH_COLOR float4(1.0, 1.0, 1.0, 1.0)
// default plot line thickness
#define GRAPH_THICKNESS 2.0


struct GraphStruct
{
    float4 area;
    float2 lines;
    float2 co;
    float2 uv;
    float4 color;
    float4 background_color;
    float roundness;
    float drop_shadow;
    float drop_shadow_radius;
    float3 lines_x_color;
    float3 lines_y_color;
};


float2 graphCoord(float4 area, float2 co)
{
    float2 uv = remap(co, area.xy, area.xy + area.zw-1);
    return float2(uv.x, 1.0 - uv.y);
}


GraphStruct graphNew(float2 position, float2 size, float2 co, float2 lines)
{
    GraphStruct g;
    g.area               = float4(position, size);
    g.co                 = co;
    g.uv                 = graphCoord(g.area, co);
    g.lines              = lines;
    g.color              = 0.0;
    g.background_color   = float4(0.0, 0.0, 0.0, 1.0);
    g.roundness          = 0.0;
    g.drop_shadow        = 0.0;
    g.drop_shadow_radius = 1.0;
    g.lines_x_color      = 0.25;
    g.lines_y_color      = 0.125;
    return g;
}


void graphAddPlot(inout GraphStruct g, float f, float4 color, float thickness)
{
    thickness *= rcp(g.area.w); //ScreenSize.y*ScreenSize.z;
    f = (f - 0.5) * (1.0-thickness) + 0.5 - g.uv.y;
    float dist = abs(f) / length(float2(ddx(f) / ddx(g.uv.x), -1.0));//ddy(f) / ddy(g.uv.y)));
    g.color = max(g.color, smoothstep(thickness, 0.0, dist) * color);
}


void graphAddPlot(inout GraphStruct g, float f, float3 color) { graphAddPlot(g, f, float4(color, 1.0), GRAPH_THICKNESS); }
void graphAddPlot(inout GraphStruct g, float f, float4 color) { graphAddPlot(g, f, color, GRAPH_THICKNESS); }
void graphAddPlot(inout GraphStruct g, float f, float thickness) { graphAddPlot(g, f, GRAPH_COLOR, thickness); }
void graphAddPlot(inout GraphStruct g, float f) { graphAddPlot(g, f, GRAPH_COLOR, GRAPH_THICKNESS); }


void graphDraw(GraphStruct g, inout float4 color)
{
    color.xyz *= color.w > 0.0 ? rcp(color.w+1e-6) : 1.0;

    float2 d = abs(g.co - g.area.xy - g.area.zw * 0.5) - g.area.zw * 0.5 + g.roundness;
    float box = length(max(0.0, d)) + min(0.0, max2(d)) - g.roundness;

    if (box <= 0.0)
    {
        g.lines = g.area.zw / max(1.0, g.lines);
        float2 lines = ((uint2)abs(g.co - g.area.xy + 1) % (uint2)g.lines) < 2;
        g.background_color.xyz += lines.x * g.lines_x_color + lines.y * g.lines_y_color;
        color.xyz = lerp(color.xyz, g.background_color.xyz, g.background_color.w);
        color.xyz = lerp(color.xyz, g.color.xyz, g.color.w);
        color.w = 0.0;
    }
    else
    {
        color.w = min(color.w, sqrt(lerp(1.0, saturate(box * 0.02 / g.drop_shadow_radius), g.drop_shadow)));
        color.xyz *= color.w > 0.0 ? color.w : 1.0;
    }
}


#endif