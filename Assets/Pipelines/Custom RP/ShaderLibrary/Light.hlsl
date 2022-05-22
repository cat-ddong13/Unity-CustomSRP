#ifndef CUSTOM_LIGHT_INCLUDED
#define CUSTOM_LIGHT_INCLUDED
// 平行光数量限制
#define MAX_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_OTHER_LIGHT_COUNT 64

CBUFFER_START(_CustomLight)

// 平行光数量
int _DirectionalLightCount;
// 存储了平行光的颜色
float4 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
// xyz:方向  w:灯光的渲染层级掩码属性
float4 _DirectionalLightDirectionsAndMasks[MAX_DIRECTIONAL_LIGHT_COUNT];
// 存储了平行光的阴影数据
// x=方向光阴影强度(light.shadowStrength)
// y=级联数*方向光数
// z=方向光阴影法线偏移(shadowNormalBias)
// w=阴影遮罩通道
float4 _DirectionalLightShadowDatas[MAX_DIRECTIONAL_LIGHT_COUNT];

// 非平行光(点光源、聚光灯)数量
float _OtherLightCount;
float4 _OtherLightColors[MAX_OTHER_LIGHT_COUNT];
// w: 1 / sqrt(light.range)
float4 _OtherLightPositions[MAX_OTHER_LIGHT_COUNT];
// 非平行光(聚光灯)方向
// xyz:方向 w:灯光渲染层级掩码
float4 _OtherLightDirectionsAndMasks[MAX_OTHER_LIGHT_COUNT];
// 计算聚光灯角度
// Square(saturate(d*a+b))
// d:dot(lightDir,lightDir2Frag)
// a:1 / (cos(ri/2) - cos(ro/2))
// b:-cos(ro/2)*a
// .........
// x:a y:b
float4 _OtherLightSpotsCone[MAX_OTHER_LIGHT_COUNT];
// 存储了非平行光的阴影数据
// x=阴影强度
// w=阴影遮罩通道
float4 _OtherLightShadowDatas[MAX_OTHER_LIGHT_COUNT];

CBUFFER_END

//方向光数据
struct Light
{
    // 方向
    float3 direction;
    // 颜色
    float3 color;
    // 衰减
    float attenuation;

    // 灯光的渲染层级位掩码
    uint renderingLayerMask;
};

int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}

int GetOtherLightCount()
{
    return _OtherLightCount;
}

// 获取平行光设置的阴影数据
DirectionalShadowData GetDirectionalShadowData(int lightIndex, ShadowData shadowData)
{
    DirectionalShadowData data;

    float4 dirLightShadowData = _DirectionalLightShadowDatas[lightIndex];
    data.strength = dirLightShadowData.x;
    // 瓦片索引
    data.tileIndex = dirLightShadowData.y + shadowData.cascadeIndex;
    // 法线偏移
    data.normalBias = dirLightShadowData.z;
    // 阴影遮罩通道
    data.shadowMaskChannel = dirLightShadowData.w;
    return data;
}

// 获取非平行光阴影数据
OtherShadowData GetOtherShadowData(int lightIndex)
{
    OtherShadowData data;
    float4 otherLightShadowData = _OtherLightShadowDatas[lightIndex];
    data.strength = otherLightShadowData.x;
    data.tileIndex = otherLightShadowData.y;
    data.shadowMaskChannel = otherLightShadowData.w;
    data.spotDirectionWS = .0;
    data.surface2LightWS = .0;
    data.lightDirectionWS = .0;
    data.isPoint = otherLightShadowData.z == 1.0;
    return data;
}

// 获取平行光
Light GetDirectionalLight(int lightIndex, Surface surfaceWS, ShadowData shadowData)
{
    Light light;
    light.color = _DirectionalLightColors[lightIndex].rgb;
    light.direction = _DirectionalLightDirectionsAndMasks[lightIndex].xyz;
    light.renderingLayerMask = asuint(_DirectionalLightDirectionsAndMasks[lightIndex].w);
    // 获取平行光阴影数据
    DirectionalShadowData dirShadowData = GetDirectionalShadowData(lightIndex, shadowData);
    // 获取平行光衰减 = 阴影强度
    light.attenuation = GetDirectionalShadowAttenuation(dirShadowData, shadowData, surfaceWS);
    return light;
}

Light GetOtherLight(int lightIndex, Surface surface, ShadowData shadowData)
{
    Light light;
    light.color = _OtherLightColors[lightIndex].rgb;

    float3 lightPosition = _OtherLightPositions[lightIndex].xyz;
    float3 s2l = lightPosition - surface.position;
    light.direction = normalize(s2l);

    // rangeAttenuation = max(0 , sqrt(1 - Square(Square(d)/sqrt(r))));
    float distanceSqr = max(dot(s2l, s2l), 0.00001);
    float rangeAttenuation = Square(saturate(1.0 - Square(distanceSqr * _OtherLightPositions[lightIndex].w)));

    // 计算聚光灯衰减
    // Square(saturate(d*a+b))
    // x:a y:b
    float3 spotLightDirection = _OtherLightDirectionsAndMasks[lightIndex].xyz;
    light.renderingLayerMask = asuint(_OtherLightDirectionsAndMasks[lightIndex].w);
    float4 spot = _OtherLightSpotsCone[lightIndex];
    float spotAttenuation = Square(saturate(dot(spotLightDirection, light.direction) * spot.x + spot.y));

    OtherShadowData otherShadowData = GetOtherShadowData(lightIndex);
    otherShadowData.spotDirectionWS = spotLightDirection;
    otherShadowData.surface2LightWS = s2l;
    otherShadowData.lightDirectionWS = light.direction;

    float shadow = GetOtherShadowAttenuation(otherShadowData, shadowData, surface);

    light.attenuation = shadow * spotAttenuation * rangeAttenuation / distanceSqr;
    return light;
}

#endif
