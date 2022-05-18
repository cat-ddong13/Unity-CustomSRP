#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

// 判断物体与灯光渲染层掩码是否有重叠
bool IsRenderingLayersOverlap(Surface surface, Light light)
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
    return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

// 获取照明
float3 GetLighting(Surface surface, BRDF brdf, GI gi)
{
    // 级联阴影数据
    ShadowData shadowData = GetShadowData(surface);
    shadowData.shadowMask = gi.shadowMask;

    float3 color = 0;
    color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);

    // 平行光
    int dirLightCount = GetDirectionalLightCount();
    for (int i = 0; i < dirLightCount; i++)
    {
        Light light = GetDirectionalLight(i, surface, shadowData);
        // 判断渲染层是否有重叠
        if (IsRenderingLayersOverlap(surface, light))
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
    for (int j = 0; j < otherLightCount; j++)
    {
        Light light = GetOtherLight(j, surface, shadowData);
        if (IsRenderingLayersOverlap(surface, light))
        {
            color += GetLighting(surface, brdf, light);
        }
    }
    #endif

    return color;
}

float _TestValue;

float3 CelLighting(Surface surface)
{
    // 级联阴影数据
    ShadowData shadowData = GetShadowData(surface);

    float3 color = 0;

    // float _SoftShadow = 0;
    // float _DiffuseRange = 0.5;
    // float3 _AnColor = float3(0.25, 0.25, 0.25);

    // 平行光
    int dirLightCount = GetDirectionalLightCount();
    for (int i = 0; i < dirLightCount; i++)
    {
        Light light = GetDirectionalLight(i, surface, shadowData);
        // 判断渲染层是否有重叠
        if (IsRenderingLayersOverlap(surface, light))
        {
            float3 finalColor = .0;

            // 高光
            float3 halfView = normalize(light.direction + surface.viewDirection);
            float spec = max(0, dot(surface.normal, halfView));
            float pixelWidth = fwidth(spec) * 2.0;

            surface.specMaskMap.r = max(0, surface.specMaskMap.r);

            float3 specular = light.color * surface.specColor * surface.specMaskMap.r * lerp(
                0, 1, smoothstep(-pixelWidth, pixelWidth, spec + surface.specRange - 1)) * step(
                0.0001, surface.specRange);

            finalColor += specular;

            // 漫反射
            float ndotl = dot(surface.normal, light.direction);
            ndotl = ndotl * 0.5 + 0.5;
            float diffuse = surface.shadowSmooth == 1
                                ? smoothstep(-pixelWidth + _DiffuseRange, pixelWidth + _DiffuseRange, ndotl)
                                : step(_DiffuseRange, ndotl * light.attenuation);

            // float3 diffuse = smoothstep(step(surface.diffuseRange, ndotl * light.attenuation),
            //                             smoothstep(-pixelWidth + _DiffuseRange, pixelWidth + surface.diffuseRange,
            //                                        ndotl),
            //                             surface.shadowSmooth);
            float3 diffCol1 = diffuse * INPUT_PROP(_BaseColor).rgb;
            float3 diffCol2 = (1 - diffuse) * surface.shadowColor;
            float3 diffColor = light.color * (diffCol1 + diffCol2) * surface.color;

            finalColor += diffColor;

            //边缘光
            #if defined(_RIM_LIGHTING)
            float rimValue = pow(1 - dot(surface.normal, surface.viewDirection), surface.rimPower);
            float rimStep = smoothstep(-pixelWidth + surface.rimThreshold, pixelWidth + surface.rimThreshold, rimValue);
            float3 rimColor = surface.color * light.color * rimStep * surface.rimColor * 2 * diffuse;
            finalColor += rimColor;
            #endif

            color += finalColor;
        }
    }

    return color;
}


#endif
