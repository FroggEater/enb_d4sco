//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries TES Skyrim SE hlsl DX11 format, sample file of depth of field
// visit http://enbdev.com for updates
// Author: Boris Vorontsov
// It's similar to enbeffectpostpass.fx, but works with hdr input and output
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



//+++++++++++++++++++++++++++++
//internal parameters, modify or add new
//+++++++++++++++++++++++++++++
/*
//example parameters with annotations for in-game editor
float	ExampleScalar
<
	string UIName="Example scalar";
	string UIWidget="spinner";
	float UIMin=0.0;
	float UIMax=1000.0;
> = {1.0};

float3	ExampleColor
<
	string UIName = "Example color";
	string UIWidget = "color";
> = {0.0, 1.0, 0.0};

float4	ExampleVector
<
	string UIName="Example vector";
	string UIWidget="vector";
> = {0.0, 1.0, 0.0, 0.0};

int	ExampleQuality
<
	string UIName="Example quality";
	string UIWidget="quality";
	int UIMin=0;
	int UIMax=3;
> = {1};

Texture2D ExampleTexture
<
	string UIName = "Example texture";
	string ResourceName = "test.bmp";
>;
SamplerState ExampleSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
*/

float	EFocusingSensitivity
<
	string UIName="Focus:: sensitivity to nearest";
	string UIWidget="spinner";
	float UIMin=0.0;
	float UIMax=1.0;
> = {0.5};

float	EApertureSize
<
	string UIName="Aperture:: size";
	string UIWidget="spinner";
	float UIMin=1.0;
	float UIMax=16.0;
> = {2.0};

float	ESensorSize //kinda 1/CropFactor
<
	string UIName="Dof:: sensor size";
	string UIWidget="spinner";
	float UIMin=4.8; //1/3"
	float UIMax=36.0; //35 mm full frame
> = {36.0};

float	EBokehSoftness
<
	string UIName="Dof:: bokeh softness";
	string UIWidget="spinner";
	float UIMin=0.01;
	float UIMax=1.0;
> = {1.0};

float	EBlurRange
<
	string UIName="Dof:: blur max range";
	string UIWidget="spinner";
	float UIMin=0.1;
	float UIMax=2.0;
> = {1.0};



//+++++++++++++++++++++++++++++
//external enb parameters, do not modify
//+++++++++++++++++++++++++++++
//x = generic timer in range 0..1, period of 16777216 ms (4.6 hours), y = average fps, w = frame time elapsed (in seconds)
float4	Timer;
//x = Width, y = 1/Width, z = aspect, w = 1/aspect, aspect is Width/Height
float4	ScreenSize;
//changes in range 0..1, 0 means full quality, 1 lowest dynamic quality (0.33, 0.66 are limits for quality levels)
float	AdaptiveQuality;
//x = current weather index, y = outgoing weather index, z = weather transition, w = time of the day in 24 standart hours. Weather index is value from weather ini file, for example WEATHER002 means index==2, but index==0 means that weather not captured.
float4	Weather;
//x = dawn, y = sunrise, z = day, w = sunset. Interpolators range from 0..1
float4	TimeOfDay1;
//x = dusk, y = night. Interpolators range from 0..1
float4	TimeOfDay2;
//changes in range 0..1, 0 means that night time, 1 - day time
float	ENightDayFactor;
//changes 0 or 1. 0 means that exterior, 1 - interior
float	EInteriorFactor;
float	FieldOfView;

//+++++++++++++++++++++++++++++
//external enb debugging parameters for shader programmers, do not modify
//+++++++++++++++++++++++++++++
//keyboard controlled temporary variables. Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4	tempF1; //0,1,2,3
float4	tempF2; //5,6,7,8
float4	tempF3; //9,0
// xy = cursor position in range 0..1 of screen;
// z = is shader editor window active;
// w = mouse buttons with values 0..7 as follows:
//    0 = none
//    1 = left
//    2 = right
//    3 = left+right
//    4 = middle
//    5 = left+middle
//    6 = right+middle
//    7 = left+right+middle (or rather cat is sitting on your mouse)
float4	tempInfo1;
// xy = cursor position of previous left mouse button click
// zw = cursor position of previous right mouse button click
float4	tempInfo2;



//+++++++++++++++++++++++++++++
//mod parameters, do not modify
//+++++++++++++++++++++++++++++
//z = ApertureTime multiplied by time elapsed, w = FocusingTime multiplied by time elapsed
float4				DofParameters;

Texture2D			TextureCurrent; //current frame focus depth or aperture. unused in dof computation
Texture2D			TexturePrevious; //previous frame focus depth or aperture. unused in dof computation

Texture2D			TextureOriginal; //color R16B16G16A16 64 bit hdr format
Texture2D			TextureColor; //color which is output of previous technique (except when drawed to temporary render target), R16B16G16A16 64 bit hdr format
Texture2D			TextureDepth; //scene depth R32F 32 bit hdr format
Texture2D			TextureFocus; //this frame focus 1*1 R32F hdr red channel only. computed in PS_Focus
Texture2D			TextureAperture; //this frame aperture 1*1 R32F hdr red channel only. computed in PS_Aperture
Texture2D			TextureAdaptation; //previous frame vanilla or enb adaptation 1*1 R32F hdr red channel only. adaptation computed after depth of field and it's kinda "average" brightness of screen!!!

//temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D			RenderTargetRGBA32; //R8G8B8A8 32 bit ldr format
Texture2D			RenderTargetRGBA64; //R16B16G16A16 64 bit ldr format
Texture2D			RenderTargetRGBA64F; //R16B16G16A16F 64 bit hdr format
Texture2D			RenderTargetR16F; //R16F 16 bit hdr format with red channel only
Texture2D			RenderTargetR32F; //R32F 32 bit hdr format with red channel only
Texture2D			RenderTargetRGB32F; //32 bit hdr format without alpha

SamplerState		Sampler0
{
	Filter = MIN_MAG_MIP_POINT;//MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
SamplerState		Sampler1
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};



//+++++++++++++++++++++++++++++
//
//+++++++++++++++++++++++++++++
struct VS_INPUT_POST
{
	float3 pos		: POSITION;
	float2 txcoord	: TEXCOORD0;
};
struct VS_OUTPUT_POST
{
	float4 pos		: SV_POSITION;
	float2 txcoord0	: TEXCOORD0;
};



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
VS_OUTPUT_POST	VS_Quad(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST	OUT;
	float4	pos;
	pos.xyz=IN.pos.xyz;
	pos.w=1.0;
	OUT.pos=pos;
	OUT.txcoord0.xy=IN.txcoord.xy;
	return OUT;
}



////////////////////////////////////////////////////////////////////
//first passes to compute focus distance and aperture, temporary
//render targets are not available for them
////////////////////////////////////////////////////////////////////
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//output size is 1*1
//TexturePrevious size is 1*1
//TextureCurrent not exist, so set to white 1.0
//output and input textures are R32 float format (red channel only)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float4	PS_Aperture(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;

	float	curr;
	float	prev=TexturePrevious.Sample(Sampler0, IN.txcoord0.xy).x;

	//TODO compute aperture here, from adaptation or from global variables
	curr=EApertureSize; //constant in this example
	curr=max(curr, 1.0); //safety
	curr=1.0/curr; //map it to 0..1 range. for brightness it must be curr*curr (2*Pi*R*R)

	//smooth by time
	res=lerp(prev, curr, DofParameters.z); //ApertureTime with elapsed time

	//clamp to avoid bugs, 1 means fully open, bigger than 0 for proper adaptation later
	res=max(res, 0.0000000001);
	res=min(res, 1.0);

	res.w=1.0;
	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//output size is 16*16
//output texture is R32 float format (red channel only)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float4	PS_ReadFocus(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;

	//Warning! For first person models (weapon) it's better to ignore depth to avoid wrong focusing,
	//so this is done via fpdistance

	//this example reads depth almost from center of the screen
	float2	pos;
	float	curr=0.0;
	//float	currmin=1.0;
	const float	step=1.0/16.0;
	const float	halfstep=0.5/16.0;
	pos.x=halfstep;
	for (int x=0; x<16; x++)
	{
		pos.y=halfstep;
		for (int y=0; y<16; y++)
		{
			float2	coord=pos.xy * 0.05;
			coord+=IN.txcoord0.xy * 0.05 + float2(0.5, 0.5); //somewhere around the center of screen
			float	tempcurr=TextureDepth.SampleLevel(Sampler0, coord, 0.0).x;

			//do not blur first person models like weapons and hands
			const float	fpdistance=1.0/0.085;
			float	fpfactor=1.0-saturate(1.0 - tempcurr * fpdistance);
			tempcurr=lerp(1.0, tempcurr, fpfactor*fpfactor);

			//currmin=min(currmin, tempcurr);
			curr+=tempcurr;

			pos.y+=step;
		}
		pos.x+=step;
	}
	curr*=1.0/(16.0*16.0);
	res=curr;

	//clamp to avoid bugs
	res=max(res, 0.0);
	res=min(res, 1.0);

	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//output size is 1*1
//TexturePrevious size is 1*1
//TextureCurrent size is 16*16
//output and input textures are R32 float format (red channel only)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float4	PS_Focus(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;

	float	prev=TexturePrevious.Sample(Sampler0, IN.txcoord0.xy).x;

	//downsample 16*16 to 1*1
	float2	pos;
	float	curr=0.0;
	float	currmin=1.0;
	const float	step=1.0/16.0;
	const float	halfstep=0.5/16.0;
	pos.x=halfstep;
	for (int x=0; x<16; x++)
	{
		pos.y=halfstep;
		for (int y=0; y<16; y++)
		{
			float	tempcurr=TextureCurrent.Sample(Sampler0, IN.txcoord0.xy + pos.xy).x;
			currmin=min(currmin, tempcurr);
			curr+=tempcurr;

			pos.y+=step;
		}
		pos.x+=step;
	}
	curr*=1.0/(16.0*16.0);

	//adjust sensitivity to nearest areas of the screen
	curr=lerp(curr, currmin, EFocusingSensitivity);

	//smooth by time
	res=lerp(prev, curr, DofParameters.w); //FocusingTime with elapsed time

	//clamp to avoid bugs, unless it's depth
	res=max(res, 0.0);
	res=min(res, 1.0);

	res.w=1.0;
	return res;
}



////////////////////////////////////////////////////////////////////
//multiple passes for computing depth of field, with temporary render
//targets support.
//TextureCurrent, TexturePrevious are unused
////////////////////////////////////////////////////////////////////
//draw to temporary render target
float4	PS_ComputeFactor(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;

	float	depth=TextureDepth.Sample(Sampler0, IN.txcoord0.xy).x;
	float	focus=TextureFocus.Sample(Sampler0, IN.txcoord0.xy).x;
	float	aperture=TextureAperture.Sample(Sampler0, IN.txcoord0.xy).x;

	//clamp to avoid potenrial bugs
	depth=max(depth, 0.0);
	depth=min(depth, 1.0);

	//compute blur radius
	float	scaling=EBlurRange; //abstract scale in screen space
	float	factor=depth-focus;

	factor=factor * ESensorSize * aperture * scaling;
	//limit size
	float	screensizelimit=ESensorSize * scaling;
	factor=max(factor, -screensizelimit);
	factor=min(factor, screensizelimit);

	res=factor;

	//do not blur first person models like weapons
	const float	fpdistance=1.0/0.085;
	float	fpfactor=1.0-saturate(1.0 - depth * fpdistance);
	res=res * fpfactor*fpfactor;

	return res;
}



//example of blur. without any fixes of artifacts and low performance
float4	PS_Dof(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;

	float	focusing;
	focusing=RenderTargetR16F.Sample(Sampler0, IN.txcoord0.xy).x;

	float2	sourcesizeinv;
	float2	fstepcount;
	sourcesizeinv=ScreenSize.y;
	sourcesizeinv.y=ScreenSize.y*ScreenSize.z;
	fstepcount.x=ScreenSize.x;
	fstepcount.y=ScreenSize.x*ScreenSize.w;

	float2	pos;
	float2	coord;
	float4	curr=0.0;
	float	weight=0.000001;

	fstepcount=abs(focusing);
	sourcesizeinv*=focusing;

	fstepcount=min(fstepcount, 32.0);
	fstepcount=max(fstepcount, 0.0);

	int	stepcountX=(int)(fstepcount.x+1.4999);
	int	stepcountY=(int)(fstepcount.y+1.4999);
	fstepcount=max(fstepcount, 2.0);
	float2	halfstepcountinv=2.0/fstepcount;
	pos.x=-1.0+halfstepcountinv.x;
	for (int x=0; x<stepcountX; x++)
	{
		pos.y=-1.0+halfstepcountinv.y;
		for (int y=0; y<stepcountY; y++)
		{
			float	tempweight;
			float	rangefactor=dot(pos.xy, pos.xy);
			coord=pos.xy * sourcesizeinv;
			coord+=IN.txcoord0.xy;
			float4	tempcurr=TextureColor.SampleLevel(Sampler1, coord.xy, 0.0);
			tempweight=saturate(1001.0 - 1000.0*rangefactor);//arithmetic version to cut circle from square
			tempweight*=saturate(1.0 - rangefactor * EBokehSoftness);
			curr.xyz+=tempcurr.xyz * tempweight;
			weight+=tempweight;

			pos.y+=halfstepcountinv.y;
		}
		pos.x+=halfstepcountinv.x;
	}
	curr.xyz/=weight;

	res.xyz=curr;

	res.w=1.0;
	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Techniques are drawn one after another and they use the result of
// the previous technique as input color to the next one.  The number
// of techniques is limited to 255.  If UIName is specified, then it
// is a base technique which may have extra techniques with indexing
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//write aperture with time factor, this is always first technique
technique11 Aperture
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Aperture()));
	}
}

//compute focus from depth of screen and may be brightness, this is always second technique
technique11 ReadFocus
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_ReadFocus()));
	}
}

//write focus with time factor, this is always third technique
technique11 Focus
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Focus()));
	}
}



//dof example. draw first to temporary texture, then compute effect in other technique.
technique11 Dof <string UIName="Example Dof"; string RenderTarget="RenderTargetR16F";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_ComputeFactor()));
	}
}

technique11 Dof1
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Dof()));
	}
}



