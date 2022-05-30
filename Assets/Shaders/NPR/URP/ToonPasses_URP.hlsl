#ifndef TOONPASSES_INCLUDE
#define TOONPASSES_INCLUDE

#include "Assets/Pipelines/Custom RP/ShaderLibrary/Surface.hlsl"
// #include "Assets/Custom RP/ShaderLibrary/GI.hlsl"
// #include "Assets/Custom RP/ShaderLibrary/Lighting.hlsl"
#include "ToonLighting.hlsl"

struct Attributes
{
    float3 positionOS:POSITION;
    float3 normalOS:NORMAL;
    float2 uv:TEXCOORD0;
    float2 uv1:TEXCOORD1;

    #if defined(_NORMAL_MAP)
    float4 tangentOS:TANGENT;
    #endif

    // GI_ATTRIBUTE_DATA
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
    float3 normalWS:VAR_NORMAL_WS;
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

    #if defined(_SPEC_FLIP_BOOK)
    float2 flipbookUV:VAR_FLIPBOOK_UV;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord: TEXCOORD6; // compute shadow coord per-vertex for the main light
    #endif

    #if defined(_SURFACE_SHADOW_MASK)
    float2 surfaceShadowMaskUV:VAR_SHADOWMASK_UV;
    #endif

    #if defined(_SURFACE_SHADOW_RAMP)
    float2 surfaceShadowRampUV:VAR_SHADOWRAMP_UV;
    #endif

    // GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

float4 GetVertexShadowCoords(Varyings input)
{
    #if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
    return ComputeScreenPos(vertexData.positionCS);
    #else

    #if _SHADOWBIAS_CORRECTION
    float3 shadowPos = input.positionWS + (input.viewDir * SHADOW_BIAS_OFFSET);
    #else
    float3 shadowPos = input.positionWS;
    #endif

    return TransformWorldToShadowCoord(shadowPos);
    #endif
}

float4 GetPixelShadowCoords(Varyings input, float3 viewDirWS)
{
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    return input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    return TransformWorldToShadowCoord(inputData.positionWS);
    #else
    return float4(0, 0, 0, 0);
    #endif
}

Varyings ToonPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    // TRANSFER_GI_DATA(input, output);

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

    #if defined(_SPEC_FLIP_BOOK)
    output.flipbookUV = TransformSpecFlipbookUV(input.uv);
    #endif

    #if defined(_SURFACE_SHADOW_MASK)
    output.surfaceShadowMaskUV = TransformSurfaceShadowMaskUV(input.uv);
    #endif

    #if defined(_SURFACE_SHADOW_RAMP)
    output.surfaceShadowRampUV = TransformSurfaceShadowRampUV(input.uv1);

    output.surfaceShadowRampUV = input.uv1;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetVertexShadowCoords(output);
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

    #if defined(_SPEC_MASK_MAP)
    ic.useSpec = true;
    ic.specUV = input.specUV;
    #endif

    #if defined(_SURFACE_SHADOW_MASK)
    ic.useSurfaceShadowMask = true;
    ic.surfaceShadowMaskUV = input.surfaceShadowMaskUV;
    #endif

    #if defined(_SURFACE_SHADOW_RAMP)
    ic.useSurfaceShadowRamp = true;
    ic.surfaceShadowRampUV = input.surfaceShadowRampUV;
    #endif

    #if defined(_SPEC_FLIP_BOOK)
    ic.useSpecFlipbook = true;
    ic.specFlipbookUV = input.flipbookUV;
    #endif

    #if defined(_USE_MATCAP)
    ic.useMatCap = true;
    #endif

    ToonSurface surface = (ToonSurface)0;
    surface.position = input.positionWS;
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);

    // 眼睛注视相机
    #if defined(_EYEBALL_FOCUS_CAMERA)

    float3 frontNormal = normalize(GetFrontNormal().xyz);

    float ndotv = dot(frontNormal, surface.viewDirection);
    ndotv = max(ndotv, 0.65);

    float3 crossValue = cross(frontNormal, surface.viewDirection);
    crossValue = float3(-crossValue.x, crossValue.y, crossValue.z);

    float2 xy = (1 / ndotv - 1) * GetEyeballSize(ic).xy * ndotv * GetFocusSpeed(ic);

    ic.baseUV = input.uv + float2(xy.x * crossValue.y, -xy.y * crossValue.x);

    #endif

    float4 base = GetBase(ic);

    #if defined(_CLIPPING)
    clip(base.a - GetCutoff(ic));
    #endif

    surface.color = base.rgb;
    surface.alpha = base.a;
    surface.shadowCoords = GetPixelShadowCoords(input, surface.viewDirection);

    #if defined(_NORMAL_MAP)
    ic.normalUV = input.normalUV;

    surface.normal = normalize(NormalTangentToWorld(GetNormalTS(ic), input.normalWS,
                                                    input.tangentWS));

    float3 normalOS = TransformWorldToObjectNormal(surface.normal);
    ic.normalVS = TransformObject2ViewNormal(normalOS);

    #else
    surface.normal = normalize(input.normalWS);
    #endif

    #if defined(_SPEC_MASK_MAP)
    surface.specColor = GetSpecColor(ic).rgb;
    surface.specMaskMap = GetSpecMaskMap(ic).rgb;
    surface.specRange = GetSpecRange(ic);
    #endif

    #if defined(_SPEC_FLIP_BOOK)
    surface.specFlipbookUV = ic.specFlipbookUV;
    #endif
    #if defined(_RIM_LIGHTING)
    surface.rimColor = GetRimColor(ic);
    surface.rimPower = GetRimPower(ic);
    surface.rimThreshold = GetRimThreshold(ic);
    #endif

    #if defined(_SURFACE_SHADOW_MASK)
    surface.surfaceShadowMask = GetSurfaceShadowMaskMap(ic);
    #endif

    #if defined(_SURFACE_SHADOW_RAMP)
    // surface.surfaceShadowRamp = GetSurfaceShadowRampMap(ic);
    surface.surfaceShadowRampUV = input.surfaceShadowRampUV;
    #endif

    surface.surfaceShadowColor = GetSurfaceShadowColor(ic);
    surface.diffuseRange = GetDiffuseRange(ic);
    surface.surfaceShadowSmooth = GetSurfaceShadowShadowSmooth(ic);
    float3 color = CelLighting(surface);

    #if defined(_USE_MATCAP)
    float3 viewDirVS = mul(UNITY_MATRIX_I_V, float4(surface.viewDirection, 0));
    float4 matcap = GetMapcap(ic, viewDirVS);
    // matcap = GetMapcap(input.matcapUV);
    color += matcap.rgb;
    #endif

    return float4(color, 1);
}

#endif
