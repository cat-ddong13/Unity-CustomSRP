#ifndef CUSTOM_GI_INCLUDED
#define CUSTOM_GI_INCLUDED
#endif

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"

// 如果启用了lightmap
#if defined(LIGHTMAP_ON)
#define GI_ATTRIBUTE_DATA float2 lightmapUV:TEXCOORD1;
#define GI_VARYINGS_DATA float2 lightmapUV:VAR_LIGHT_MAP_UV;
// 转换光照贴图UV坐标
#define TRANSFER_GI_DATA(input,output) \
    output.lightmapUV = input.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
#define GI_FRAGMENT_DATA(input) input.lightmapUV;
// 如果没有启用lightmap
#else
#define GI_ATTRIBUTE_DATA
#define GI_VARYINGS_DATA
#define TRANSFER_GI_DATA(input,output)
#define GI_FRAGMENT_DATA(input) .0
#endif

// 采样光照贴图
TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

// 采样阴影遮罩
TEXTURE2D(unity_ShadowMask);
SAMPLER(samplerunity_ShadowMask);

// 采样体积探针球谐光照贴图
TEXTURE3D_FLOAT(unity_ProbeVolumeSH);
SAMPLER(samplerunity_ProbeVolumeSH);

// 采样天空盒的立方体贴图
TEXTURECUBE(unity_SpecCube0);
SAMPLER(samplerunity_SpecCube0);

struct GI
{
    float3 diffuse;
    float3 specular;
    ShadowMask shadowMask;
};

// 采样光照贴图
float3 SampleLightmap(float2 lightmapUV)
{
    #if defined(LIGHTMAP_ON)
        return SampleSingleLightmap(
            TEXTURE2D_ARGS(unity_Lightmap,samplerunity_Lightmap),
            lightmapUV,float4(1.0,1.0,.0,.0),
            #if defined(UNITY_LIGHTMAP_FULL_HDR)
                false,
            #else
                true,
            #endif
            float4(LIGHTMAP_HDR_MULTIPLIER,LIGHTMAP_HDR_EXPONENT,.0,.0)
            );
    #else
        return .0;
    #endif
}

// 采样光照探针
float3 SampleLightProbe(Surface surface)
{
    // 如果开启了LPPV
    if(unity_ProbeVolumeParams.x)
    {
        // 采样
        return SampleProbeVolumeSH4(
            TEXTURE3D_ARGS(unity_ProbeVolumeSH,samplerunity_ProbeVolumeSH),
            surface.position,
            surface.normal,
            unity_ProbeVolumeWorldToObject,
            unity_ProbeVolumeParams.y,
            unity_ProbeVolumeParams.z,
            unity_ProbeVolumeMin.xyz,
            unity_ProbeVolumeSizeInv.xyz
            );
    }
    else
    {
        float4 coefficients[7];
        coefficients[0] = unity_SHAr;
        coefficients[1] = unity_SHAg;
        coefficients[2] = unity_SHAb;
        coefficients[3] = unity_SHBr;
        coefficients[4] = unity_SHBg;
        coefficients[5] = unity_SHBb;
        coefficients[6] = unity_SHC;
        return max(.0,SampleSH9(coefficients,surface.normal));
    }
}

// 采样烘焙阴影
float4 SampleBakedShadows(float2 lightmapUV,Surface surface)
{
    // 如果开启了光照贴图，根据光照贴图的uv坐标去采集阴影遮罩
    #if defined(LIGHTMAP_ON)
        return SAMPLE_TEXTURE2D(unity_ShadowMask,samplerunity_ShadowMask,lightmapUV);
    #else
        //如果使用了LPPV
        if(unity_ProbeVolumeParams.x)
        {
            // 对LPPV阴影遮罩采样
            return SampleProbeOcclusion(
                TEXTURE3D_ARGS(unity_ProbeVolumeSH,samplerunity_ProbeVolumeSH),
                surface.position,
                unity_ProbeVolumeWorldToObject,
                unity_ProbeVolumeParams.y,
                unity_ProbeVolumeParams.z,
                unity_ProbeVolumeMin.xyz,
                unity_ProbeVolumeSizeInv.xyz
            );
        }
        else
        {
            // 返回unity自定义的探针阴影遮罩数据
            return unity_ProbesOcclusion;
        }
    #endif
}

// 采样环境
float3 SampleEnvironment(Surface surface,BRDF brdf)
{
    // 采集uv坐标(3D)
    float3 uvw = reflect(-surface.viewDirection,surface.normal);
    // 环境采样级别
    float mip = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
    // 采样环境
    float4 environment = SAMPLE_TEXTURECUBE_LOD(
        unity_SpecCube0,samplerunity_SpecCube0,uvw,mip
    );
    return DecodeHDREnvironment(environment,unity_SpecCube0_HDR);
}

GI GetGI(float2 lightmapUV,Surface surface,BRDF brdf)
{
    GI gi;
    gi.diffuse = SampleLightmap(lightmapUV) + SampleLightProbe(surface);
    gi.specular = SampleEnvironment(surface,brdf);
    gi.shadowMask.always = false;
    gi.shadowMask.distance = false;
    gi.shadowMask.shadows = 1.0;
    #if defined(_SHADOW_MASK_ALWAYS)
        gi.shadowMask.always = true;
        gi.shadowMask.shadows = SampleBakedShadows(lightmapUV,surface);
    #elif defined(_SHADOW_MASK_DISTANCE)
        gi.shadowMask.distance = true;
        gi.shadowMask.shadows = SampleBakedShadows(lightmapUV,surface);
    #endif
    return gi;
}
