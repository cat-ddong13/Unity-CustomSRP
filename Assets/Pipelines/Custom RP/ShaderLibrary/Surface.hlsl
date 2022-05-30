#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct Surface
{
    // 世界坐标
    float3 position;
    // 法线
    float3 normal;
    // 插值法线
    float3 interpolatedNormal;
    // 视线方向
    float3 viewDirection;
    // 深度-(view-space)
    float depth;

    // 颜色
    float3 color;
    // 透明度
    float alpha;
    // 金属度
    float metallic;
    // 平滑度
    float smoothness;
    // 遮挡,只受间接光影响
    float occlusion;
    // 抖动
    float dither;
    // 菲涅尔反射强度
    float fresnelStrength;

    // 渲染层级位掩码
    uint renderingLayerMask;

    // cell
    float3 specColor;
    float3 specMaskMap;
    float specRange;

    float3 rimColor;
    float rimThreshold;
    float rimPower;

    float diffuseRange;
    float3 surfaceShadowColor;
    float surfaceShadowSmooth;

    float4 shadowCoords;
};

struct ToonSurface
{
    // 世界坐标
    float3 position;
    // 法线
    float3 normal;
    // 视线方向
    float3 viewDirection;
    // 颜色
    float3 color;
    // 透明度
    float alpha;

    // 高光
    float3 specColor;
    float3 specMaskMap;
    float specRange;
    float2 specFlipbookUV;

    // 边缘光
    float3 rimColor;
    float rimThreshold;
    float rimPower;

    // 漫反射和阴影区域
    float diffuseRange;
    float3 surfaceShadowColor;
    float surfaceShadowSmooth;
    float3 surfaceShadowMask;
    float3 surfaceShadowRamp;
    float4 shadowCoords;
    float2 surfaceShadowRampUV;

    float4 mapcap;
};

#endif
