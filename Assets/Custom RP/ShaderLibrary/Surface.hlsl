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
};

#endif
