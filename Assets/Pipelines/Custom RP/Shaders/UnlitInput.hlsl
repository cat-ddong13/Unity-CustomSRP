#ifndef CUSTOM_UNLIT_INPUT_INCLUDE
#define CUSTOM_UNLIT_INPUT_INCLUDE

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,name)

TEXTURE2D(_BaseMap);
TEXTURE2D(_DistortionMap);
SAMPLER(sampler_BaseMap);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_DEFINE_INSTANCED_PROP(float, _ZWrite)

UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)

UNITY_DEFINE_INSTANCED_PROP(float, _NearFadeDistance)
UNITY_DEFINE_INSTANCED_PROP(float, _NearFadeRange)

UNITY_DEFINE_INSTANCED_PROP(float, _SoftParticlesDistance)
UNITY_DEFINE_INSTANCED_PROP(float, _SoftParticlesRange)

UNITY_DEFINE_INSTANCED_PROP(float, _DistortionStrength)
UNITY_DEFINE_INSTANCED_PROP(float, _DistortionBlend)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct InputConfig
{
    Fragment fragment;
    float2 baseUV;
    float4 color;
    // xy:uv  z:融合因子
    float3 flipbookUVB;
    bool flipbookBlending;
    bool nearFade;
    bool softParticles;
};

InputConfig GetInputConfig(float4 positionCS, float2 baseUV)
{
    InputConfig c;
    c.fragment = GetFragment(positionCS);
    c.baseUV = baseUV;
    c.color = 1.0;
    c.flipbookBlending = false;
    c.flipbookUVB = .0;
    c.nearFade = false;
    c.softParticles = false;
    return c;
}

float GetFinalAlpha(float alpha)
{
    return INPUT_PROP(_ZWrite) ? 1.0 : alpha;
}

float2 TransformBaseUV(float2 baseUV)
{
    float4 baseST = INPUT_PROP(_BaseMap_ST);
    return baseUV * baseST.xy + baseST.zw;
}

float4 GetBase(InputConfig ic)
{
    float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, ic.baseUV);
    // 翻页融合
    if (ic.flipbookBlending)
    {
        float4 map2 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, ic.flipbookUVB.xy);
        map = lerp(map, map2, ic.flipbookUVB.z);
    }

    // 近相机淡出
    if (ic.nearFade)
    {
        float atten = (ic.fragment.depth - INPUT_PROP(_NearFadeDistance)) / INPUT_PROP(_NearFadeRange);
        // 限制与0-1
        map.a *= saturate(atten);
    }

    if (ic.softParticles)
    {
        float depthDelta = ic.fragment.bufferDepth - ic.fragment.depth;
        float nearAttention = (depthDelta - INPUT_PROP(_SoftParticlesDistance)) / INPUT_PROP(_SoftParticlesRange);
        map.a *= saturate(nearAttention);
    }

    float4 baseColor = INPUT_PROP(_BaseColor);
    return map * baseColor * ic.color;
}

float2 GetDistortion(InputConfig ic)
{
    float4 map = SAMPLE_TEXTURE2D(_DistortionMap, sampler_BaseMap, ic.baseUV);
    if (ic.flipbookBlending)
    {
        map = lerp(
            map, SAMPLE_TEXTURE2D(_DistortionMap, sampler_BaseMap, ic.flipbookUVB.xy),
            ic.flipbookUVB.z
        );
    }
    return DecodeNormal(map, INPUT_PROP(_DistortionStrength)).xy;
}

float GetDistortionBlend(InputConfig ic)
{
    return INPUT_PROP(_DistortionBlend);
}

float GetCutoff(InputConfig ic)
{
    return INPUT_PROP(_Cutoff);
}

float3 GetEmission(InputConfig ic)
{
    return GetBase(ic).rgb;
}

float3 GetFresnel(InputConfig ic)
{
    return .0;
}

float GetMetallic(InputConfig ic)
{
    return 0.0;
}

float GetSmoothness(InputConfig ic)
{
    return 0.0;
}

#endif
