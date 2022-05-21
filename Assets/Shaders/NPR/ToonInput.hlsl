#ifndef CUSTOM_TOON_INPUT_INCLUDE
#define CUSTOM_TOON_INPUT_INCLUDE

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,name)

TEXTURE2D(_BaseMap);
// r:metallic g:occlusion b:detail a:smoothness
TEXTURE2D(_MaskMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

TEXTURE2D(_SpecMaskMap);
SAMPLER(sampler_SpecMaskMap);

TEXTURE2D(_SurfaceShadowMap);
SAMPLER(sampler_SurfaceShadowMap);

// r:albedo b:smoothness
TEXTURE2D(_DetailMap);
SAMPLER(sampler_DetailMap);
TEXTURE2D(_DetailNormalMap);
SAMPLER(sampler_DetailNormalMap);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_DEFINE_INSTANCED_PROP(float, _ZWrite)

UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
UNITY_DEFINE_INSTANCED_PROP(float4, _NormalMap_ST)
UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)
UNITY_DEFINE_INSTANCED_PROP(float, _DetailNormalScale)

// Cel

// spec
UNITY_DEFINE_INSTANCED_PROP(float4, _SpecColor)
UNITY_DEFINE_INSTANCED_PROP(float, _SpecRange)
UNITY_DEFINE_INSTANCED_PROP(float4, _SpecMaskMap_ST)
UNITY_DEFINE_INSTANCED_PROP(float, _SpecTexRotate)

// rim
UNITY_DEFINE_INSTANCED_PROP(float4, _RimColor)
UNITY_DEFINE_INSTANCED_PROP(float, _RimThreshold)
UNITY_DEFINE_INSTANCED_PROP(float, _RimPower)

// diffuse
UNITY_DEFINE_INSTANCED_PROP(float, _DiffuseRange)

// surface-shadow
UNITY_DEFINE_INSTANCED_PROP(float4, _SurfaceShadowColor)
UNITY_DEFINE_INSTANCED_PROP(float, _SurfaceShadowSmooth)
UNITY_DEFINE_INSTANCED_PROP(float4, _SurfaceShadowMap_ST)

// Eyeball-Focus
UNITY_DEFINE_INSTANCED_PROP(float4, _FrontNormal)
UNITY_DEFINE_INSTANCED_PROP(float4, _EyeballSize)
UNITY_DEFINE_INSTANCED_PROP(float, _FocusSpeed)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct InputConfig
{
    Fragment fragment;
    float2 baseUV;

    float2 normalUV;
    bool useNormalMap;

    float2 specUV;
    bool useSpec;

    float2 surfShadowUV;
};

InputConfig GetInputConfig(float4 positionCS, float2 baseUV, float2 detailUV = .0, float2 normalUV = .0,
                           float2 specUV = .0)
{
    InputConfig ic = (InputConfig)0;
    ic.fragment = GetFragment(positionCS);
    ic.baseUV = baseUV;
    ic.normalUV = normalUV;
    ic.specUV = specUV;
    ic.useSpec = false;
    ic.useNormalMap = false;
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

float2 TransformNormalUV(float2 normalUV)
{
    float4 normalST = INPUT_PROP(_NormalMap_ST);
    return normalUV * normalST.xy + normalST.zw;
}

float4 GetBaseColor(InputConfig ic)
{
    return INPUT_PROP(_BaseColor);
}

float4 GetBase(InputConfig ic)
{
    float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, ic.baseUV);
    float4 color = GetBaseColor(ic);

    return baseMap * color;
}

float3 GetNormalTS(InputConfig ic)
{
    float4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, ic.normalUV);
    float scale = INPUT_PROP(_NormalScale);
    float3 normal = DecodeNormal(normalMap, scale);

    return normal;
}

float GetCutoff(InputConfig ic)
{
    return INPUT_PROP(_Cutoff);
}

// Cel
float2 TransformSpecUV(float2 specUV)
{
    float4 specST = INPUT_PROP(_SpecMaskMap_ST);
    return specUV * specST.xy + specST.zw;
}

float2 TransformSurfaceShadowUV(float2 shadowUV)
{
    float4 shadowST = INPUT_PROP(_SurfaceShadowMap_ST);
    return shadowUV * shadowST.xy + shadowST.zw;
}

float4 GetSpec(InputConfig ic)
{
    if (ic.useSpec)
    {
        float4 specMap = SAMPLE_TEXTURE2D(_SpecMaskMap, sampler_SpecMaskMap, ic.specUV);
        return specMap;
    }

    return .0;
}

float4 GetSpecColor(InputConfig ic)
{
    return INPUT_PROP(_SpecColor);
}

float4 GetSpecMaskMap(InputConfig ic)
{
    float specTexRotate = INPUT_PROP(_SpecTexRotate);
    float2 uv = float2(ic.specUV.x * cos(specTexRotate) - ic.specUV.y * sin(specTexRotate),
                       ic.specUV.x * sin(specTexRotate) + ic.specUV.y * cos(specTexRotate));
    ic.specUV = uv;
    float4 specMap = GetSpec(ic);
    return specMap;
}

float4 GetSurfaceShadow(InputConfig ic)
{
    float4 shadowMap = SAMPLE_TEXTURE2D(_SurfaceShadowMap, sampler_SurfaceShadowMap, float2(ic.surfShadowUV.x,.0));
    return shadowMap;
}

float GetSurfaceShadowMap(InputConfig ic)
{
    float4 shadowMap = GetSurfaceShadow(ic);
    return shadowMap.r;
}

float4 GetSurfaceShadow(float2 uv)
{
    float4 shadowMap = SAMPLE_TEXTURE2D(_SurfaceShadowMap, sampler_SurfaceShadowMap, uv);
    return shadowMap;
}

float GetSpecRange(InputConfig ic)
{
    return INPUT_PROP(_SpecRange);
}

float3 GetRimColor(InputConfig ic)
{
    return INPUT_PROP(_RimColor);
}

float GetRimPower(InputConfig ic)
{
    return INPUT_PROP(_RimPower);
}

float GetRimThreshold(InputConfig ic)
{
    return INPUT_PROP(_RimThreshold);
}

float GetDiffuseRange(InputConfig ic)
{
    return INPUT_PROP(_DiffuseRange);
}

float4 GetSurfaceShadowColor(InputConfig ic)
{
    return INPUT_PROP(_SurfaceShadowColor);
}

float GetSurfaceShadowShadowSmooth(InputConfig ic)
{
    return INPUT_PROP(_SurfaceShadowSmooth);
}

float4 GetEyeballSize(InputConfig ic)
{
    return INPUT_PROP(_EyeballSize);
}

float4 GetFrontNormal(InputConfig ic)
{
    return INPUT_PROP(_FrontNormal);
}

float GetFocusSpeed(InputConfig ic)
{
    return INPUT_PROP(_FocusSpeed);
}

#endif
