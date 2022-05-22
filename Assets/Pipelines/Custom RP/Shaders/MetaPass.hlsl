//metapass
//https://docs.unity3d.com/cn/current/Manual/MetaPass.html

#ifndef CUSTOM_META_PASS_INCLUDE
#define CUSTOM_META_PASS_INCLUDE

#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"

CBUFFER_START(UnityMetaPass)
// x = 烘焙表面漫反射对其他物体的影响，也就是让物体表面漫反射的颜色，参与gi
// y = 让物体的自发光，参与gi。
// 如果勾选了Global Illumination，则烘焙是自发光，否则是物体表面主纹理反射的颜色。
// 对应unity_MetaFragmentControl两个分量。
bool4 unity_MetaFragmentControl;
CBUFFER_END

// 幂
float unity_OneOverOutputBoost;
// 限制输出的最大值
float unity_MaxOutputValue;

struct Attributes
{
    float3 positionOS:POSITION;
    float2 uv:TEXCOORD0;
    float2 lightmapUV:TEXCOORD1;
};

struct Varyings
{
    float4 positionCS_SS:SV_POSITION;
    float2 uv:VAR_UV;
};

Varyings MetaPassVertex(Attributes input)
{
    Varyings output;
    input.positionOS.xy = input.lightmapUV.xy * unity_LightmapST.xy + unity_LightmapST.zw;
    input.positionOS.z = input.positionOS.z > .0 ? FLT_MIN : .0;
    output.positionCS_SS = TransformWorldToHClip(input.positionOS);
    output.uv = TransformBaseUV(input.uv);
    return output;
}

float4 MetaPassFragment(Varyings input):SV_TARGET
{
    InputConfig ic = GetInputConfig(input.positionCS_SS, input.uv);
    float4 base = GetBase(ic);
    Surface surface;
    // 初始化结构初始值为0
    ZERO_INITIALIZE(Surface, surface);
    surface.color = base.rgb;
    surface.metallic = GetMetallic(ic);
    surface.smoothness = GetSmoothness(ic);
    BRDF brdf = GetBRDF(surface);
    float4 meta = .0;
    if (unity_MetaFragmentControl.x)
    {
        meta = float4(brdf.diffuse, 1.0);
        meta.rgb += brdf.specular * brdf.roughness * 0.5;
        // 通过一个正幂运算提升输出
        meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
    }
    else if (unity_MetaFragmentControl.y)
    {
        meta = float4(GetEmission(ic), 1.0);
    }

    return meta;
}

#endif
