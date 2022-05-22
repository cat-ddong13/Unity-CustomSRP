#ifndef CUSTOM_SHADOWS_INCLUDED
#define CUSTOM_SHADOWS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"

// 定义阴影滤波器采集范围
#if defined(_DIRECTIONAL_PCF3)
    #define DIRECTIONAL_FILTER_SAMPLES 4
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
#elif defined(_DIRECTIONAL_PCF5)
    #define DIRECTIONAL_FILTER_SAMPLES 9
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
#elif defined(_DIRECTIONAL_PCF7)
    #define DIRECTIONAL_FILTER_SAMPLES 16
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif

// 定义阴影滤波器采集范围
#if defined(_OTHER_PCF3)
    #define OTHER_FILTER_SAMPLES 4
    #define OTHER_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
#elif defined(_OTHER_PCF5)
    #define OTHER_FILTER_SAMPLES 9
    #define OTHER_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
#elif defined(_OTHER_PCF7)
    #define OTHER_FILTER_SAMPLES 16
    #define OTHER_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif

// 最大平行光阴影数量
#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
// 最大非平行光阴影数量
#define MAX_SHADOWED_OTHER_LIGHT_COUNT 16
// 最大阴影级联数
#define MAX_SHADOW_CASCADES_COUNT 4

// 阴影贴图
TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
TEXTURE2D_SHADOW(_OtherShadowAtlas);
// inline sampler
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);


CBUFFER_START(_CustomShadows)

int _CascadeCount;
// x=平行光图集阴影贴图大小 y=平行光图集纹素大小
// z=非平行光图集阴影贴图大小
float4 _ShadowAtlasSize;
// 阴影距离过度因子
// x=1/shadowSettings.MaxDistance
// y=1/shadowSettings.DistanceFadeRatio
// z=1/1-(1-directional.CascadeFadeRatio)*(1-directional.CascadeFadeRatio)
float4 _ShadowDistanceFade;
// 平行光阴影贴图空间矩阵
float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_SHADOW_CASCADES_COUNT];
// 非平行光阴影贴图空间矩阵
float4x4 _OtherShadowMatrices[MAX_SHADOWED_OTHER_LIGHT_COUNT];
// 非平行光的阴影图集瓦片索引
// xy:偏移 z:采样tile的缩放 w:bias
float4 _OtherShadowTiles[MAX_SHADOWED_OTHER_LIGHT_COUNT];
// 阴影级联裁剪球体
float4 _CascadeCullingSpheres[MAX_SHADOW_CASCADES_COUNT];
// 级联数据 x=1/cullingSphere.w;y=(因滤波器采样级别做的额外的)沿法线的偏移量(normalBias)
float4 _CascadeData[MAX_SHADOW_CASCADES_COUNT];

CBUFFER_END

static const float3 PointShadowPlanes[6] =
{
    float3(-1.0, .0, .0),
    float3(1.0, .0, .0),
    float3(.0, -1.0, .0),
    float3(.0, 1.0, .0),
    float3(.0, .0, -1.0),
    float3(.0, .0, 1.0)
};

// 平行光阴影数据结构
struct DirectionalShadowData
{
    // 阴影强度
    float strength;
    // 瓦片索引
    int tileIndex;
    // 法线偏移
    float normalBias;
    // 阴影遮罩通道
    int shadowMaskChannel;
};

// 非平行光阴影数据
struct OtherShadowData
{
    // 阴影强度
    float strength;
    // 阴影遮罩通道
    int shadowMaskChannel;
    // 瓦片索引
    int tileIndex;
    // 世界空间光源的方向
    float3 lightDirectionWS;
    // 聚光灯的方向
    float3 spotDirectionWS;
    // 世界空间表面到光源的方向
    float3 surface2LightWS;
    // 是否是点光源
    bool isPoint;
};

// 阴影遮罩
struct ShadowMask
{
    bool always;
    bool distance;
    // 灯光的烘焙阴影数据存储在4个通道中
    float4 shadows;
};

// 存储了从级联中获取到的阴影数据结构
struct ShadowData
{
    // 处于的级联索引
    int cascadeIndex;
    // 阴影强度
    float strength;
    // 级联融合
    float cascadeBlendFactor;
    // 阴影遮罩数据
    ShadowMask shadowMask;
};

// 根据表面深度和淡化因子淡化阴影强度
float FadedShadowStrength(float distance, float scale, float fade)
{
    return saturate((1.0 - distance * scale) * fade);
}

// 获取级联中的阴影数据
ShadowData GetShadowData(Surface surface)
{
    ShadowData shadowData;
    // 设置级联中阴影强度
    shadowData.strength = FadedShadowStrength(surface.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
    // 设置默认级联融合因子为1.0(不参与融合)
    shadowData.cascadeBlendFactor = 1.0;
    // 设置阴影遮罩属性
    shadowData.shadowMask.always = false;
    shadowData.shadowMask.distance = false;
    shadowData.shadowMask.shadows = 1.0;
    int i = 0;
    // 取距离表面最近的一个级联
    for (; i < _CascadeCount; i++)
    {
        float4 cullingSphere = _CascadeCullingSpheres[i];
        // 计算表面位置和裁剪球体中心位置的距离
        float distanceSqr = DistanceSquared(surface.position, cullingSphere.xyz);
        // 比较是否在球内，cullingSphere.w 存储了球体半径的平方
        if (distanceSqr < cullingSphere.w)
        {
            // 获取阴影淡化比率
            float fadeRatio = FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
            // 如果表面处于最后一个级联
            if (i == _CascadeCount - 1)
            {
                // 将级联的阴影强度淡化，并且不参与级联融合(cascadeBlendRatio == 1.0)
                shadowData.strength *= fadeRatio;
            }
            else
            {
                // 否则设置级联间融合因子为淡化后的阴影比率
                shadowData.cascadeBlendFactor = fadeRatio;
            }
            break;
        }
    }

    // 如果表面不在级联中
    if (i == _CascadeCount && _CascadeCount > 0)
    {
        // 阴影强度为0
        shadowData.strength = 0.0;
    }
    // 如果定义了级联融合方式为抖动
    #if defined(_CASCADE_BLEND_DITHER)
    // 表面在级联中 && 级联融合因子 < 表面抖动值
    else if(shadowData.cascadeBlendFactor < surface.dither)
    {
        // 将使用的级联级别+1
        i++;
    }
    #endif
    // 如果没有定义级联软融合
    #if !defined(_CASCADE_BLEND_SOFT)
    //设置级联融合因子为1.0(不参与融合)
    shadowData.cascadeBlendFactor = 1.0;
    #endif

    // 设置表面使用的阴影级联
    shadowData.cascadeIndex = i;
    return shadowData;
}

// 根据表面的阴影贴图空间坐标从阴影图集中采样平行光阴影
// positionSTS:shadow texture space potision
float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    // 根据表面坐标从阴影图集中采样阴影
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);
}

// 根据表面的阴影贴图空间坐标从阴影图集中采样非平行光阴影
float SampleOtherShadowAtlas(float3 positionSTS, float3 bounds)
{
    // 将采样坐标夹在对应的图集tile范围中
    positionSTS.xy = clamp(positionSTS.xy, bounds.xy, bounds.xy + bounds.z);

    // 根据表面坐标从阴影图集中采样阴影
    return SAMPLE_TEXTURE2D_SHADOW(_OtherShadowAtlas, SHADOW_SAMPLER, positionSTS);
}

// 通过滤波器采样方向光阴影
float FilterDirectionalShadow(float3 positionSTS)
{
    // 如果定义了滤波器模式(3x3、5x5、7x7)
    #if defined(DIRECTIONAL_FILTER_SETUP)
        float shadow = .0;
        // 存储了采样的权重
        float weights[DIRECTIONAL_FILTER_SAMPLES];
        // 存储了采样的坐标
        float2 positions[DIRECTIONAL_FILTER_SAMPLES];
        // 采样大小
        float4 size = _ShadowAtlasSize.yyxx;
        // 去对应的采样方法中采样一个数据集合,得到采样到的权重和坐标
        DIRECTIONAL_FILTER_SETUP(size,positionSTS.xy,weights,positions);
        // 计算阴影强度
        for (int i = 0;i < DIRECTIONAL_FILTER_SAMPLES;i++)
        {
            shadow += weights[i] * SampleDirectionalShadowAtlas(float3(positions[i].xy,positionSTS.z));       
        }
        return shadow;
    // 否则直接对该表面采样阴影
    #else
    return SampleDirectionalShadowAtlas(positionSTS);
    #endif
}

// 通过滤波器采样非平行光阴影
float FilterOtherShadow(float3 positionSTS, float3 bounds)
{
    // 如果定义了滤波器模式(3x3、5x5、7x7)
    #if defined(OTHER_FILTER_SETUP)
        float shadow = .0;
        // 存储了采样的权重
        float weights[OTHER_FILTER_SAMPLES];
        // 存储了采样的坐标
        float2 positions[OTHER_FILTER_SAMPLES];
        // 采样大小
        float4 size = _ShadowAtlasSize.wwzz;
        // 去对应的采样方法中采样一个数据集合,得到采样到的权重和坐标
        OTHER_FILTER_SETUP(size,positionSTS.xy,weights,positions);
        // 计算阴影强度
        for (int i = 0;i < OTHER_FILTER_SAMPLES;i++)
        {
            shadow += weights[i] * SampleOtherShadowAtlas(float3(positions[i].xy,positionSTS.z),bounds);       
        }
        return shadow;
    // 否则直接对该表面采样阴影
    #else
    return SampleOtherShadowAtlas(positionSTS, bounds);
    #endif
}

// 获取级联阴影强度
float GetCascadedShadow(DirectionalShadowData dirShadowData, ShadowData global, Surface surfaceWS)
{
    // 法线偏移 = 表面法线 * (平行光光设置的法线偏移强度 * (因滤波器采样级别做的额外的)沿法线的偏移量)
    float3 normalBias = surfaceWS.interpolatedNormal * (dirShadowData.normalBias * _CascadeData[global.cascadeIndex].y);
    // 将表面的世界坐标沿法线偏移后，转换到阴影贴图空间坐标STS
    float3 positionSTS = mul(_DirectionalShadowMatrices[dirShadowData.tileIndex],
                             float4(surfaceWS.position + normalBias, 1.0)).xyz;
    // 采样阴影
    float shadow = FilterDirectionalShadow(positionSTS);
    // 级联间阴影融合过度
    if (global.cascadeBlendFactor < 1.0)
    {
        // 计算下一个级联的法线偏移
        normalBias = surfaceWS.interpolatedNormal * (dirShadowData.normalBias * _CascadeData[global.cascadeIndex + 1].
            y);
        // 计算下一个级联的阴影贴图空间坐标
        positionSTS = mul(_DirectionalShadowMatrices[dirShadowData.tileIndex + 1],
                          float4(surfaceWS.position + normalBias, 1.0)).xyz;
        // 融合过度两个级联间的阴影强度
        shadow = lerp(FilterDirectionalShadow(positionSTS), shadow, global.cascadeBlendFactor);
    }

    return shadow;
}

// 获取烘焙阴影
float GetBakedShadow(ShadowMask shadowMask, int maskChannel)
{
    float shadow = 1.0;
    if (shadowMask.always || shadowMask.distance)
    {
        if (maskChannel >= 0)
        {
            shadow = shadowMask.shadows[maskChannel];
        }
    }

    return shadow;
}

float GetBakedShadow(ShadowMask shadowMask, int maskChannel, float strength)
{
    if (shadowMask.always || shadowMask.distance)
    {
        return lerp(1.0, GetBakedShadow(shadowMask, maskChannel), strength);
    }

    return 1.0;
}

// 混合烘焙阴影和实时阴影
float MixBakedAndRealtimeShadows(ShadowData global, float shadow, int maskChannel, float strength)
{
    ShadowMask mask = global.shadowMask;
    float bakedShadow = GetBakedShadow(mask, maskChannel);
    if (mask.always)
    {
        shadow = lerp(1.0, shadow, global.strength);
        shadow = min(bakedShadow, shadow);
        return lerp(1.0, shadow, strength);
    }
    else if (mask.distance)
    {
        shadow = lerp(bakedShadow, shadow, global.strength);
        return lerp(1.0, shadow, strength);
    }

    return lerp(1.0, shadow, strength * global.strength);
}

// 获取方向阴影强度衰减
float GetDirectionalShadowAttenuation(DirectionalShadowData dirShadowData, ShadowData global, Surface surface)
{
    // 如果定义了不接收阴影
    #if !defined(_RECEIVE_SHADOWS)
    return 1.0;
    #endif

    float shadow = .0;
    // 如果平行光阴影强度 * 级联阴影强度 <= 0，证明没有实时阴影，此时去获取烘焙阴影
    if (dirShadowData.strength * global.strength <= .0)
    {
        shadow = GetBakedShadow(global.shadowMask, dirShadowData.shadowMaskChannel, abs(dirShadowData.strength));
    }
    else
    {
        // 否则去获取实时级联阴影，并实现烘焙阴影和实时阴影之间的融合过度
        shadow = GetCascadedShadow(dirShadowData, global, surface);
        shadow = MixBakedAndRealtimeShadows(global, shadow, dirShadowData.shadowMaskChannel, dirShadowData.strength);
    }

    return shadow;
}

float GetOtherShadow(OtherShadowData other, ShadowData global, Surface surface)
{
    float tileIndex = other.tileIndex;
    float3 lightPlanes = other.spotDirectionWS;
    if (other.isPoint)
    {
        // 获取点光tile的索引
        float faceOffset = CubeMapFaceID(-other.lightDirectionWS);
        tileIndex += faceOffset;
        // 根据索引取点光的光平面(可以简单理解为点光分解为六个光源空间后的'方向')
        lightPlanes = PointShadowPlanes[faceOffset];
    }

    float4 tile = _OtherShadowTiles[tileIndex];
    // 聚光灯方向向量在点-聚光灯向量方向上的投影，用于受光影响的不同的点的法线偏移的计算调整
    float distance2LitPlane = dot(other.surface2LightWS, lightPlanes);
    float3 normalBias = surface.interpolatedNormal * (distance2LitPlane * tile.w);
    float4 positionSTS = mul(_OtherShadowMatrices[tileIndex], float4(surface.position + normalBias, 1.0));

    return FilterOtherShadow(positionSTS.xyz / positionSTS.w, tile.xyz);
}

// 获取其他阴影强度衰减
float GetOtherShadowAttenuation(OtherShadowData other, ShadowData global, Surface surface)
{
    #if !defined(_RECEIVE_SHADOWS)
    return 1.0;
    #endif

    float shadow = .0;
    if (other.strength * global.strength <= .0)
    {
        shadow = GetBakedShadow(global.shadowMask, other.shadowMaskChannel, abs(other.strength));
    }
    else
    {
        shadow = GetOtherShadow(other, global, surface);
        shadow = MixBakedAndRealtimeShadows(global, shadow, other.shadowMaskChannel, other.strength);
    }

    return shadow;
}

#endif
