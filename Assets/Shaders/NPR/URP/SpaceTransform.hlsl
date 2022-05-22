#ifndef CUSTOM_SPACE_TRANSFORM_INCLUDED
#define CUSTOM_SPACE_TRANSFORM_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

float4x4 GetObject2ViewNormalMatrix()
{
    return UNITY_MATRIX_IT_MV;
}

float4x4 GetObject2ViewMatrix()
{
    return UNITY_MATRIX_MV;
}

float2 TransformView2HClip(float2 v)
{
    return mul((float2x2)UNITY_MATRIX_P, v);
}

float3 TransformObject2ViewPos(float3 positionOS)
{
    return mul((float3x3)GetObject2ViewMatrix(), positionOS);
}

float3 TransformObject2ViewNormal(float3 normalOS, bool doNormalize = false)
{
    float3 normalVS = mul((float3x3)GetObject2ViewNormalMatrix(), normalOS);
    if (doNormalize)
        return SafeNormalize(normalVS);

    return normalVS;
}

#endif
