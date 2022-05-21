#ifndef TOONPASSES_INCLUDE
#define TOONPASSES_INCLUDE

#include "Assets/Custom RP/ShaderLibrary/Surface.hlsl"
#include "Assets/Custom RP/ShaderLibrary/Shadows.hlsl"
#include "Assets/Custom RP/ShaderLibrary/Light.hlsl"
#include "Assets/Custom RP/ShaderLibrary/BRDF.hlsl"
#include "Assets/Custom RP/ShaderLibrary/GI.hlsl"
#include "Assets/Custom RP/ShaderLibrary/Lighting.hlsl"

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
    float2 normalUV:VAR_NORMAL_UV;
    float4 tangentWS:VAR_TANGENT;
    #endif

    #if defined(_SPEC_MASK_MAP)
    float2 specUV:VAR_SPEC_UV;
    #endif

    GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings ToonPassVertex(Attributes input)
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
    output.normalUV = TransformNormalUV(input.uv);
    output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
    #endif

    #if defined(_SPEC_MASK_MAP)
    output.specUV = TransformSpecUV(input.uv);
    #endif

    return output;
}


float4 ToonPassFragment(Varyings input):SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);

    #if defined(_Rim_Lighting)
    return  float4(1,0,0,1);
    #endif

    InputConfig ic = GetInputConfig(input.positionCS_SS, input.uv);

    ClipLOD(ic.fragment, unity_LODFade.x);

    #if defined(_MASK_MAP)
    ic.useMask = true;
    #endif

    #if defined(_DETAIL_MAP)
    ic.useDetail = true;
    ic.detailUV = input.detailUV;
    #endif

    #if defined(_SPEC_MASK_MAP)
    ic.useSpec = true;
    ic.specUV = input.specUV;
    #endif

    Surface surface = (Surface)0;
    surface.position = input.positionWS;
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);

    // 眼睛注视相机
    #if defined(_EYEBALL_FOCUS_CAMERA)

    float3 frontNormal = normalize(GetFrontNormal(ic).xyz);

    float ndotv = dot(frontNormal, surface.viewDirection);
    ndotv = max(ndotv, 0.15);

    float3 crossValue = cross(frontNormal, surface.viewDirection);
    crossValue = float3(-crossValue.x, crossValue.y * ndotv, crossValue.z);

    float2 xy = (1 / ndotv - 1) * GetEyeballSize(ic).xy * ndotv * GetFocusSpeed(ic);

    ic.baseUV = input.uv + float2(xy.x * crossValue.y, xy.y * crossValue.x);

    #endif

    float4 base = GetBase(ic);

    #if defined(_CLIPPING)
    clip(base.a - GetCutoff(ic));
    #endif

    surface.depth = -TransformWorldToView(input.positionWS).z;
    surface.color = base.rgb;
    surface.alpha = base.a;
    surface.renderingLayerMask = asuint(unity_RenderingLayer.x);

    #if defined(_NORMAL_MAP)
    ic.normalUV = input.normalUV;
    surface.normal = normalize(NormalTangentToWorld(GetNormalTS(ic), input.normalWS,
                                                    input.tangentWS));
    surface.interpolatedNormal = input.normalWS;
    #else
    surface.normal = normalize(input.normalWS);
    surface.interpolatedNormal = surface.normal;
    #endif

    // BRDF brdf;
    // #if defined(_PREMULTIPLY_ALPHA)
    // brdf = GetBRDF(surface, true);
    // #else
    // brdf = GetBRDF(surface);
    // #endif
    //
    // float2 lightmapUV = GI_FRAGMENT_DATA(input);
    // GI gi = GetGI(lightmapUV, surface, brdf);

    #if defined(_SPEC_MASK_MAP)
    surface.specColor = GetSpecColor(ic).rgb;
    surface.specMaskMap = GetSpecMaskMap(ic).rgb;
    surface.specRange = GetSpecRange(ic);
    #endif

    #if defined(_RIM_LIGHTING)
    surface.rimColor = GetRimColor(ic);
    surface.rimPower = GetRimPower(ic);
    surface.rimThreshold = GetRimThreshold(ic);
    #endif

    surface.surfaceShadowColor = GetSurfaceShadowColor(ic);
    surface.diffuseRange = GetDiffuseRange(ic);
    surface.surfaceShadowSmooth = GetSurfaceShadowShadowSmooth(ic);

    float3 color = CelLighting(surface);
    return float4(color, GetFinalAlpha(surface.alpha));
}

#endif
