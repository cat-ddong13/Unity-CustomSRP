#ifndef CUSTOM_LIT_INPUT_INCLUDE
#define CUSTOM_LIT_INPUT_INCLUDE

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,name)

TEXTURE2D(_BaseMap);
TEXTURE2D(_EmissionMap);
// r:metallic g:occlusion b:detail a:smoothness
TEXTURE2D(_MaskMap);
TEXTURE2D(_NormalMap);
SAMPLER(sampler_BaseMap);
// r:albedo b:smoothness
TEXTURE2D(_DetailMap);
SAMPLER(sampler_DetailMap);
TEXTURE2D(_DetailNormalMap);
SAMPLER(sampler_DetailNormalMap);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_DEFINE_INSTANCED_PROP(float, _ZWrite)

UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
// 自发光颜色
UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
UNITY_DEFINE_INSTANCED_PROP(float4, _DetailMap_ST)
UNITY_DEFINE_INSTANCED_PROP(float, _DetailAlbedo)
UNITY_DEFINE_INSTANCED_PROP(float, _DetailSmoothness)
UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)
UNITY_DEFINE_INSTANCED_PROP(float, _DetailNormalScale)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct InputConfig
{
    Fragment fragment;
    float2 baseUV;
    float2 detailUV;
    bool useMask;
    bool useDetail;
};

InputConfig GetInputConfig(float4 positionCS,float2 baseUV, float2 detailUV = .0)
{
    InputConfig ic;
    ic.fragment = GetFragment(positionCS);
    ic.baseUV = baseUV;
    ic.detailUV = detailUV;
    ic.useMask = false;
    ic.useDetail = false;
    return ic;
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

float2 TransformDetail(float2 detailUV)
{
    float4 detailST = INPUT_PROP(_DetailMap_ST);
    return detailUV * detailST.xy + detailST.zw;
}

float4 GetDetail(InputConfig ic)
{
    if (ic.useDetail)
    {
        float4 detailMap = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, ic.detailUV);
        // 将范围[0,1]->[-1,1]
        return detailMap * 2.0 - 1.0;
    }

    return .0;
}

// 采集掩码
float4 GetMask(InputConfig ic)
{
    if (ic.useMask)
        return SAMPLE_TEXTURE2D(_MaskMap, sampler_BaseMap, ic.baseUV);

    return 1.0;
}

float4 GetBase(InputConfig ic)
{
    float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, ic.baseUV);
    float4 color = INPUT_PROP(_BaseColor);

    if (ic.useDetail)
    {
        float detail = GetDetail(ic).r * INPUT_PROP(_DetailAlbedo);
        // detail的掩码
        float mask = GetMask(ic).b;
        // 进行gamma校正
        baseMap.rgb = lerp(sqrt(baseMap.rgb), detail < .0 ? .0 : 1.0, abs(detail) * mask);
        baseMap.rgb *= baseMap.rgb;
    }

    return baseMap * color;
}

float3 GetNormalTS(InputConfig ic)
{
    float4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_BaseMap, ic.baseUV);
    float scale = INPUT_PROP(_NormalScale);
    float3 normal = DecodeNormal(normalMap, scale);

    if (ic.useDetail)
    {
        // detail normal
        normalMap = SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, ic.detailUV);
        scale = INPUT_PROP(_DetailNormalScale) * GetMask(ic).b;
        float3 detail = DecodeNormal(normalMap, scale);

        normal = BlendNormalRNM(normal, detail);
    }

    return normal;
}

float GetCutoff(InputConfig ic)
{
    return INPUT_PROP(_Cutoff);
}

float GetMetallic(InputConfig ic)
{
    return INPUT_PROP(_Metallic) * GetMask(ic).r;
}

float GetSmoothness(InputConfig ic)
{
    float smoothness = INPUT_PROP(_Smoothness);
    float4 mask = GetMask(ic);
    smoothness *= mask.a;

    if (ic.useDetail)
    {
        float detail = GetDetail(ic).b * INPUT_PROP(_DetailSmoothness);
        smoothness = lerp(smoothness, detail < 0.0 ? 0.0 : 1.0, abs(detail) * mask.b);
    }

    return smoothness;
}

float GetOcclusion(InputConfig ic)
{
    float strength = INPUT_PROP(_Occlusion);
    float occlusion = GetMask(ic).g;
    occlusion = lerp(occlusion, 1.0, strength);
    return occlusion;
}

float3 GetEmission(InputConfig ic)
{
    return SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, ic.baseUV).rgb * INPUT_PROP(_EmissionColor).rgb;
}

float GetFresnel(InputConfig ic)
{
    return INPUT_PROP(_Fresnel);
}

#endif
