#ifndef CUSTOM_LIT_PASS_INCLUDE
#define CUSTOM_LIT_PASS_INCLUDE

#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/GI.hlsl"
#include "../ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float3 positionOS:POSITION;
    float3 normalOS:NORMAL;
    float2 uv:TEXCOORD0;

    #if defined(_NORMAL_MAP)
    float4 tangentOS:TANGENT;
    #endif

    GI_ATTRIBUTE_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    // 语义SV_POSITION，
    // 在vertex中为clip space坐标
    // 传递到fragment后，被转换为screen space像素坐标
    // [0, 0] - [width, height]
    // w:用于执行透视除法将3D坐标映射到屏幕上，是片元到相机XY平面的距离，不是近裁剪面
    float4 positionCS_SS:SV_POSITION;
    // world-space
    float3 positionWS:VAR_POSITION;
    float3 normalWS:VAR_NORMAL;
    float2 uv:VAR_UV;

    #if defined(_DETAIL_MAP)
    float2 detailUV:VAR_DETAIL_UV;
    #endif

    #if defined(_NORMAL_MAP)
    float4 tangentWS:VAR_TANGENT;
    #endif

    GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    TRANSFER_GI_DATA(input, output);

    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS_SS = TransformWorldToHClip(output.positionWS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = TransformBaseUV(input.uv);

    #if defined(_DETAIL_MAP)
    output.detailUV = TransformDetail(input.uv);
    #endif

    #if defined(_NORMAL_MAP)
    output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
    #endif

    return output;
}

float4 LitPassFragment(Varyings input):SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);

    InputConfig ic = GetInputConfig(input.positionCS_SS, input.uv);

    ClipLOD(ic.fragment, unity_LODFade.x);

    #if defined(_MASK_MAP)
    ic.useMask = true;
    #endif

    #if defined(_DETAIL_MAP)
    ic.useDetail = true;
    ic.detailUV = input.detailUV;
    #endif

    float4 base = GetBase(ic);

    #if defined(_CLIPPING)
    clip(base.a - GetCutoff(ic));
    #endif

    Surface surface = (Surface)0;
    surface.position = input.positionWS;
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
    surface.depth = -TransformWorldToView(input.positionWS).z;
    surface.color = base.rgb;
    surface.alpha = base.a;
    surface.metallic = GetMetallic(ic);
    surface.smoothness = GetSmoothness(ic);
    surface.occlusion = GetOcclusion(ic);
    surface.dither = InterleavedGradientNoise(input.positionCS_SS.xy, 0);
    surface.fresnelStrength = GetFresnel(ic);
    surface.renderingLayerMask = asuint(unity_RenderingLayer.x);

    #if defined(_NORMAL_MAP)
    surface.normal = normalize(NormalTangentToWorld(GetNormalTS(ic), input.normalWS,
                                                    input.tangentWS));
    surface.interpolatedNormal = input.normalWS;
    #else
    surface.normal = normalize(input.normalWS);
    surface.interpolatedNormal = surface.normal;
    #endif

    BRDF brdf;
    #if defined(_PREMULTIPLY_ALPHA)
    brdf = GetBRDF(surface, true);
    #else
    brdf = GetBRDF(surface);
    #endif

    float2 lightmapUV = GI_FRAGMENT_DATA(input);
    GI gi = GetGI(lightmapUV, surface, brdf);

    float3 color = GetLighting(surface, brdf, gi);
    color += GetEmission(ic);

    return float4(color, GetFinalAlpha(surface.alpha));
}

#endif
