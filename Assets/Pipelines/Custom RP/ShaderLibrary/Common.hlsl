#ifndef CUSTOM_COMMON_INCLUDED
#define CUSTOM_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "UnityInput.hlsl"

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_MV unity_MatrixMV
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_IT_MV  unity_MatrixITMV
#define UNITY_MATRIX_P glstate_matrix_projection
// #define UNITY_INSTANCING_ENABLED
#define UNITY_PREV_MATRIX_M .0
#define UNITY_PREV_MATRIX_I_M .0

// 如果定义了shadowmask
#if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
    #define SHADOWS_SHADOWMASK
#endif

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "SpaceTransform.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

SAMPLER(sampler_linear_clamp);
SAMPLER(sampler_point_clamp);

// 是否是正交相机
bool IsOrthographicCamera()
{
    return unity_OrthoParams.w;
}

// 深度缓冲从正交到线性空间
float DepthBufferOrthographic2Linear(float depth)
{
    #if UNITY_REVERSED_Z
    depth = 1.0 - depth;
    #endif

    // 获取深度到相机的距离(near + (far-near)*depth)
    return _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * depth;
}

#include "Fragment.hlsl"

float Square(float v)
{
    return v * v;
}

float DistanceSquared(float3 pA, float3 pB)
{
    float3 sub = pA - pB;
    return dot(sub, sub);
}

// 通过lod的淡入淡出因子和随机的噪声因子进行裁剪
void ClipLOD(Fragment fragment, float fade)
{
    #if defined(LOD_FADE_CROSSFADE)
        float dither = InterleavedGradientNoise(fragment.positionSS.xy , 0);
        clip(fade +(fade < .0 ? dither : -dither));
    #endif
}

// 解码法线
float3 DecodeNormal(float4 sample, float scale)
{
    #if defined(UNITY_NO_DXT5nm)
        return UnpackNormalRGB(sample,scale);
    #else
    return UnpackNormalmapRGorAG(sample, scale);
    #endif
}

// 将法线从切线转到世界空间
float3 NormalTangentToWorld(float3 normalTS, float3 normalWS, float4 tangentWS)
{
    float3x3 tangentToWorld = CreateTangentToWorld(normalWS, tangentWS.xyz, tangentWS.z);
    return TransformTangentToWorld(normalTS, tangentToWorld);
}


#endif
