//双向反射比分布模型的颜色计算

#ifndef CUSTOM_BRDF_INCLUDED
#define CUSTOM_LIGHT_INCLUDED
#define MAX_DIRECTIONAL_LIGHT_COUNT 4
#define MIN_REFLECTIVITY 0.04

struct BRDF
{
    // 漫反射
    float3 diffuse;
    // 高光
    float3 specular;
    // 粗糙度
    float roughness;
    // 直观上的粗糙度
    float perceptualRoughness;
    // 菲涅尔反射
    float fresnel;
};

float OneMinusReflectivity(float metallic)
{
    float range = 1.0 - MIN_REFLECTIVITY;
    return range - metallic * range;
}

// 双向反射分布函数模型
BRDF GetBRDF(Surface surface,bool applyAlphaToDiffuse = false)
{
    BRDF brdf;
    float oneMinusRelecttivity = OneMinusReflectivity(surface.metallic);
    brdf.diffuse = surface.color * oneMinusRelecttivity;
    if(applyAlphaToDiffuse)
    {
        brdf.diffuse *= surface.alpha;
    }
    
    brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
    brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
    brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
    brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusRelecttivity);
    return brdf;
}

float SpecularStrength(Surface surface, BRDF brdf, Light light)
{
    // half direction between view and light
    float3 h = SafeNormalize(light.direction + surface.viewDirection);
    // normal和half direction点乘的平方 
    float nh2 = Square(saturate(dot(surface.normal, h)));
    // light和half direction点乘的平方
    float lh2 = Square(saturate(dot(light.direction, h)));
    // 粗糙度的平方
    float r2 = Square(brdf.roughness);
    float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
    float normalization = brdf.roughness * 4.0 + 2.0;
    return r2 / (d2 * max(0.1, lh2) * normalization);
}

// 直接光的双向反射分布函数模型
float3 DirectBRDF(Surface surface, BRDF brdf, Light light)
{
    return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}

// 间接光的双向反射分布函数模型
float3 IndirectBRDF(Surface surface,BRDF brdf,float3 diffuse,float3 specular)
{
    float fresnelStrength = surface.fresnelStrength * Pow4(1.0 - saturate(dot(surface.normal,surface.viewDirection)));
    float3 reflection = specular * lerp(brdf.specular,brdf.fresnel,fresnelStrength);
    reflection /= (brdf.roughness * brdf.roughness + 1.0);
    return (diffuse * brdf.diffuse + reflection) * surface.occlusion;
}

#endif
