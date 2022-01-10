// ----------------------------------------------------------------------------------------------------------
// REFORGED INCLUDE FILE

// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
// OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
// OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ----------------------------------------------------------------------------------------------------------


#include "Reforged/ReforgedUI.fxh"



#ifndef REFORGED_MACROS_H
#define REFORGED_MACROS_H



// ----------------------------------------------------------------------------------------------------------
// TEXTURES
// ----------------------------------------------------------------------------------------------------------
#if REFORGED_HLSL_3
    #define TEXTURE_PATH(name, path, filter, uv, srgb) \
        texture2D tex##name < string ResourceName = path; >; \
        sampler2D Sampler##name = sampler_state \
        { \
            Texture     = <tex##name>; \
            MinFilter   = filter; \
            MagFilter   = filter; \
            MipFilter   = NONE; \
            AddressU    = uv; \
            AddressV    = uv; \
            SRGBTexture = srgb; \
        };


    #define TEXTURE_UNIFORM(name, filter, uv, srgb) \
        texture2D tex##name; \
        sampler2D Sampler##name = sampler_state \
        { \
            Texture     = <tex##name>; \
            MinFilter   = filter; \
            MagFilter   = filter; \
            MipFilter   = NONE; \
            AddressU    = uv; \
            AddressV    = uv; \
            SRGBTexture = srgb; \
        };


    #define TEXTURE_ENBEFFECT(name, filter, uv, srgb) \
        texture2D texs##name; \
        sampler2D _s##name = sampler_state \
        { \
            Texture     = <texs##name>; \
            MinFilter   = filter; \
            MagFilter   = filter; \
            MipFilter   = NONE; \
            AddressU    = uv; \
            AddressV    = uv; \
            SRGBTexture = srgb; \
        };
#endif



// ----------------------------------------------------------------------------------------------------------
// TECHNIQUES
// ----------------------------------------------------------------------------------------------------------
#if REFORGED_HLSL_5
    #define TECHNIQUE(name, vs, ps) \
        technique11 name \
        { \
            pass p0 \
            { \
                SetVertexShader(CompileShader(vs_5_0, vs)); \
                SetPixelShader(CompileShader(ps_5_0, ps)); \
            } \
        }

    #define TECHNIQUE_TARGETED(name, target, vs, ps) \
        technique11 name < string RenderTarget = TO_STRING(target); > \
        { \
            pass p0 \
            { \
                SetVertexShader(CompileShader(vs_5_0, vs)); \
                SetPixelShader(CompileShader(ps_5_0, ps)); \
            } \
        }

    #define TECHNIQUE_NAMED(name, uiName, vs, ps) \
        technique11 name < string UIName = uiName; > \
        { \
            pass p0 \
            { \
                SetVertexShader(CompileShader(vs_5_0, vs)); \
                SetPixelShader(CompileShader(ps_5_0, ps)); \
            } \
        }

    #define TECHNIQUE_NAMED_TARGETED(name, uiName, target, vs, ps) \
        technique11 name < string UIName = uiName; string RenderTarget = TO_STRING(target); > \
        { \
            pass p0 \
            { \
                SetVertexShader(CompileShader(vs_5_0, vs)); \
                SetPixelShader(CompileShader(ps_5_0, ps)); \
            } \
        }
#endif



#endif // REFORGED_MACROS_H