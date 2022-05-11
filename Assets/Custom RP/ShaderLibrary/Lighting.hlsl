#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

// 判断物体与灯光渲染层掩码是否有重叠
bool IsRenderingLayersOverlap(Surface surface,Light light)
{
    return (surface.renderingLayerMask & light.renderingLayerMask) != 0;
}

// 入射光
float3 IncomingLight(Surface surface, Light light)
{
    return saturate(dot(surface.normal, light.direction) * light.attenuation) * light.color;
}

float3 GetLighting(Surface surface, BRDF brdf, Light light)
{
    return IncomingLight(surface, light) * DirectBRDF(surface,brdf,light);
}

// 获取照明
float3 GetLighting(Surface surface, BRDF brdf,GI gi)
{
    // 级联阴影数据
    ShadowData shadowData = GetShadowData(surface);
    shadowData.shadowMask = gi.shadowMask;

    float3 color= 0;
    color = IndirectBRDF(surface,brdf,gi.diffuse,gi.specular);

    // 平行光
    int dirLightCount = GetDirectionalLightCount();
    for (int i = 0; i < dirLightCount; i++)
    {
        Light light = GetDirectionalLight(i,surface,shadowData);
        // 判断渲染层是否有重叠
        if(IsRenderingLayersOverlap(surface,light))
        {
            color += GetLighting(surface, brdf, light);
        }
    }

    //非平行光(点光源、聚光灯)
    #if defined(_LIGHTS_PER_OBJECT)
        // 循环8次
        int otherLightCount = min(unity_LightData.y, 8);
        for (int j = 0; j < otherLightCount; j++)
        {
            int lightIndex = unity_LightIndices[(uint)j/4][(uint)j%4];
            Light light = GetOtherLight(lightIndex,surface,shadowData);
            if(IsRenderingLayersOverlap(surface,light))
            {
                color += GetLighting(surface,brdf,light);
            }
        }
    #else
        int otherLightCount = GetOtherLightCount();
        for (int j = 0 ;j < otherLightCount;j++)
        {
            Light light = GetOtherLight(j,surface,shadowData);
            if(IsRenderingLayersOverlap(surface,light))
            {
                color += GetLighting(surface,brdf,light);
            }
        }
    #endif
    
    return color;
}

#endif
