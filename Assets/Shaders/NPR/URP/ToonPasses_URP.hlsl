#ifndef TOONPASSES_INCLUDE
#define TOONPASSES_INCLUDE

#include "Assets/Pipelines/Custom RP/ShaderLibrary/Surface.hlsl"
// #include "Assets/Custom RP/ShaderLibrary/GI.hlsl"
// #include "Assets/Custom RP/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float3 positionOS:POSITION;
    float3 normalOS:NORMAL;
    float2 uv:TEXCOORD0;

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

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord: TEXCOORD6; // compute shadow coord per-vertex for the main light
    #endif

    // GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

float4 GetVertexShadowCoords(Varyings input)
{
    //https://github.com/Unity-Technologies/Graphics/blob/47c15c6a9746f2c9bf0635db2f3ab6669281f461/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl#L423
	
    #if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
    return ComputeScreenPos(vertexData.positionCS);
    #else

    #if _SHADOWBIAS_CORRECTION
    //Move the shadowed position slightly away from the camera to avoid banding artifacts
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
    
    // #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) //Per-vertex coord if no cascades are used
    // return input.shadowCoord; 
    // #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS) //Shadow cascades
    //
    // #if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
    // //Screen-space shadow map (pre-resolved)
    // return ComputeScreenPos(input.positionCS_SS);
    // #else
    //
    // #if _SHADOWBIAS_CORRECTION
    // //Move the shadowed position slightly away from the camera to avoid banding artifacts
    // float3 shadowPos = input.positionWS + (viewDirWS * SHADOW_BIAS_OFFSET);
    // #else
    // float3 shadowPos = input.positionWS;
    // #endif
	   //
    // //Cascades in use, calculate per-pixel now
    // return TransformWorldToShadowCoord(shadowPos);
    // #endif
    //
    // #else //No shadows
    // //Unused, but needs to be initialized...
    // return float4(0, 0, 0, 0);
    // #endif
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
    
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetVertexShadowCoords(output);
    #endif

    return output;
}

float3 CelLighting(Surface surface, Light light)
{
    float3 finalColor = .0;
    float3 specular = .0;

    // 高光
    float3 halfView = normalize(light.direction + surface.viewDirection);
    float spec = max(0, dot(surface.normal, halfView));
    float pixelWidth = fwidth(spec) * 0.5;
    specular = surface.specColor * lerp(
        0, 1, smoothstep(-pixelWidth, pixelWidth, spec + surface.specRange - 1)) * step(
        0.0001, surface.specRange);
    finalColor += light.color * specular * light.shadowAttenuation * surface.specMaskMap.r;

    // 漫反射
    float ndotl = dot(surface.normal, light.direction);
    ndotl = ndotl * 0.5 + 0.5;
    float shadowAtten = ndotl * light.shadowAttenuation;

    float diffuse = (smoothstep(-pixelWidth + surface.diffuseRange, pixelWidth + surface.diffuseRange, ndotl) * surface.
        surfaceShadowSmooth + step(surface.diffuseRange, ndotl) * (1.0 - surface.
            surfaceShadowSmooth)) * shadowAtten;

    float3 diffCol1 = diffuse * surface.color * light.color;
    float3 diffCol2 = (1 - diffuse) * surface.surfaceShadowColor * surface.color;

    #if defined(_SURFACE_SHADOW_RAMP)
    float4 surfaceShadowRamp = GetSurfaceShadow(float2(ndotl, .0));
    diffCol2 *= surfaceShadowRamp.r;
    #endif

    float3 diffColor = diffCol1 + diffCol2;
    finalColor += diffColor;

    //边缘光
    #if defined(_RIM_LIGHTING)
    float rimValue = pow(1 - dot(surface.normal, surface.viewDirection), surface.rimPower);
    float rimStep = smoothstep(-pixelWidth + surface.rimThreshold, pixelWidth + surface.rimThreshold, rimValue);
    float3 rimColor =  surface.color * light.color * rimStep * surface.rimColor * 2 * diffuse;
    finalColor += rimColor;
    #endif
    
    return finalColor;
}

float3 CelLighting(Surface surface)
{
    float3 color = float3(1, 0, 0);
    // 平行光
    // int dirLightCount = GetDirectionalLightCount();
    // for (int i = 0; i < dirLightCount; i++)
    // {
    //     Light light = GetDirectionalLight(i, surface, shadowData);
    //     // 判断渲染层是否有重叠
    //     if (IsRenderingLayersOverlap(surface, light))
    //     {
    //         color += CelLighting(surface, light);
    //     }
    // }

    return color;
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
    //
    // #if defined(_DETAIL_MAP)
    // ic.useDetail = true;
    // ic.detailUV = input.detailUV;
    // #endif
    //
    #if defined(_SPEC_MASK_MAP)
    ic.useSpec = true;
    ic.specUV = input.specUV;
    #endif
    Surface surface = (Surface)0;
    surface.position = input.positionWS;
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
    
    ic.shadowCoord = GetPixelShadowCoords(input, surface.viewDirection);
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
    Light mainLight = GetMainLight(ic.shadowCoord);
    // return float4(mainLight.shadowAttenuation * mainLight.distanceAttenuation,0,0,1);
    float3 color = CelLighting(surface,mainLight);
    return float4(color, 1);
}

#endif
