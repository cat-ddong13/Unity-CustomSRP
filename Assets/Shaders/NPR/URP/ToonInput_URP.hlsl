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

TEXTURE2D(_SurfaceShadowMask);
SAMPLER(sampler_SurfaceShadowMask);

TEXTURE2D(_SurfaceShadowRamp);
SAMPLER(sampler_SurfaceShadowRamp);

TEXTURE2D(_SpecFlipBook);
SAMPLER(sampler_SpecFlipBook);

TEXTURE2D(_MatcapMap);
SAMPLER(sampler_MatcapMap);

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
UNITY_DEFINE_INSTANCED_PROP(float4, _SpecFlipBook_ST)
UNITY_DEFINE_INSTANCED_PROP(float4, _SpecFlipBookColor)
UNITY_DEFINE_INSTANCED_PROP(float, _SpecFlipBookBlendRatio)

// rim
UNITY_DEFINE_INSTANCED_PROP(float4, _RimColor)
UNITY_DEFINE_INSTANCED_PROP(float, _RimThreshold)
UNITY_DEFINE_INSTANCED_PROP(float, _RimPower)

// diffuse
UNITY_DEFINE_INSTANCED_PROP(float, _DiffuseRange)

// surface-shadow
UNITY_DEFINE_INSTANCED_PROP(float4, _SurfaceShadowColor)
UNITY_DEFINE_INSTANCED_PROP(float, _SurfaceShadowSmooth)
UNITY_DEFINE_INSTANCED_PROP(float4, _SurfaceShadowMask_ST)
UNITY_DEFINE_INSTANCED_PROP(float4, _SurfaceShadowRamp_ST)

// Eyeball-Focus
UNITY_DEFINE_INSTANCED_PROP(float4, _EyeballSize)
UNITY_DEFINE_INSTANCED_PROP(float, _FocusSpeed)

UNITY_DEFINE_INSTANCED_PROP(int, _FrameCount)

UNITY_DEFINE_INSTANCED_PROP(float4, _MapcapColor)

UNITY_DEFINE_INSTANCED_PROP(float4, _FrontNormal)
UNITY_DEFINE_INSTANCED_PROP(float4, _LeftNormal)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct InputConfig
{
    Fragment fragment;
    float2 baseUV;

    float2 normalUV;
    bool useNormalMap;

    float2 specUV;
    bool useSpec;

    bool useSurfaceShadowMask;
    float2 surfaceShadowMaskUV;

    bool useSurfaceShadowRamp;
    float2 surfaceShadowRampUV;

    bool useSpecFlipbook;
    float2 specFlipbookUV;

    float2 surfShadowUV;

    float4 shadowCoord;

    bool useMatCap;
    float3 normalVS;
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
    ic.useSurfaceShadowMask = false;
    ic.surfaceShadowMaskUV = .0;
    ic.surfaceShadowRampUV = .0;
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

float2 TransformSpecFlipbookUV(float2 flipbookUV)
{
    float4 flipbookST = INPUT_PROP(_SpecFlipBook_ST);
    return flipbookUV * flipbookST.xy + flipbookST.zw;
}

float2 TransformSurfaceShadowMaskUV(float2 shadowUV)
{
    float4 shadowST = INPUT_PROP(_SurfaceShadowMask_ST);
    return shadowUV * shadowST.xy + shadowST.zw;
}

float2 TransformSurfaceShadowRampUV(float2 shadowUV)
{
    float4 shadowST = INPUT_PROP(_SurfaceShadowRamp_ST);

    return (shadowUV * shadowST.xy + shadowST.zw) * 0.25;
}

//spec

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

float4 GetSpecFlipbook(float2 uv, float row, float column)
{
    float width = 128.0;
    float height = 128.0;

    float2 newUV = float2(column * width, row * height) / 512.0 + uv * 0.25;
    float4 map = SAMPLE_TEXTURE2D(_SpecFlipBook, sampler_SpecFlipBook, newUV);
    float4 color = INPUT_PROP(_SpecFlipBookColor);
    return map * color;
}

float4 GetSpecFlipbook(float2 uv, int tile)
{
    int row = floor((tile - 1) / 4);;
    int column = fmod(tile - 1, 4);

    float4 color = GetSpecFlipbook(uv, row, column);

    #if defined(_SPEC_FLIP_BOOK_BLEND)
    tile++;
    row = floor((tile - 1) / 4);;
    column = fmod(tile - 1, 4);
    float4 color2 = GetSpecFlipbook(uv, row, column);
    color = lerp(color, color2, INPUT_PROP(_SpecFlipBookBlendRatio));
    #endif

    return color;
}

float GetSpecRange(InputConfig ic)
{
    return INPUT_PROP(_SpecRange);
}

// rim
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

// diffuse-shadow 
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

float4 GetSurfaceShadowMaskMap(InputConfig ic)
{
    float4 shadowMaskMap = SAMPLE_TEXTURE2D(_SurfaceShadowMask, sampler_SurfaceShadowMask, ic.surfaceShadowMaskUV);
    return shadowMaskMap;
}

float4 GetSurfaceShadowRampMap(InputConfig ic)
{
    float4 shadowMap = SAMPLE_TEXTURE2D(_SurfaceShadowRamp, sampler_SurfaceShadowRamp, ic.surfaceShadowRampUV);
    return shadowMap;
}

float4 GetSurfaceShadowRampMap(float2 uv)
{
    return SAMPLE_TEXTURE2D(_SurfaceShadowRamp, sampler_SurfaceShadowRamp, uv);
}

//eyd-ball focus camera

float4 GetEyeballSize(InputConfig ic)
{
    return INPUT_PROP(_EyeballSize);
}

float4 GetFrontNormal()
{
    return INPUT_PROP(_FrontNormal);
}

float4 GetLeftNormal()
{
    return INPUT_PROP(_LeftNormal);
}

float GetFocusSpeed(InputConfig ic)
{
    return INPUT_PROP(_FocusSpeed);
}

int GetFrameCount()
{
    return INPUT_PROP(_FrameCount);
}

float2 TransformMatcapUV(float3 normalVS, float3 viewDirection)
{
    float3 uvDetail = normalVS * float3(-1.0, -1.0, 1.0);
    float3 uvBase = mul(unity_MatrixV, float4(viewDirection, 0)).rgb * float3(-1.0, -1.0, 1.0) + float3(0, 0, 1.0);
    float3 noSknewViewNormal = uvBase * dot(uvBase, uvDetail) / uvBase.z - uvDetail;
    float2 viewNormalAsMatCapUV = noSknewViewNormal.xy * 0.5 + 0.5;

    return viewNormalAsMatCapUV;
}

float4 GetMapcap(float2 uv)
{
    float4 mapcap = SAMPLE_TEXTURE2D(_MatcapMap, sampler_MatcapMap, uv);

    return mapcap * INPUT_PROP(_MapcapColor);
}

float4 GetMapcap(InputConfig ic, float3 viewDirection)
{
    float2 mapcapUV = TransformMatcapUV(ic.normalVS, viewDirection);

    float4 mapcap = SAMPLE_TEXTURE2D(_MatcapMap, sampler_MatcapMap, mapcapUV);

    return mapcap * INPUT_PROP(_MapcapColor);
}

#endif
