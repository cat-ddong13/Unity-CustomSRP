#ifndef TOONLIGHTING_INCLUDE
#define TOONLIGHTING_INCLUDE

#include "Assets/Pipelines/Custom RP/ShaderLibrary/Surface.hlsl"

float ToonShadow(ToonSurface surface, Light light)
{
    float3 lightDirH = normalize(float3(light.direction.x, 0, light.direction.z));
    float lightAtten = 1 - (dot(lightDirH, GetFrontNormal().xyz) * 0.5 + 0.5);
    float flipU = sign(dot(lightDirH, GetLeftNormal().xyz));
    float3 shadowRamp = GetSurfaceShadowRampMap(surface.surfaceShadowRampUV * float2(flipU, 1));
    float surfaceShadow = step(lightAtten, shadowRamp.r);

    return  surfaceShadow;
}

float3 CellHighLight(ToonSurface surface, Light light, float pixelWidth, float spec)
{
    float smoothSpec = lerp(
        0, 1, smoothstep(-pixelWidth, pixelWidth, spec + surface.specRange - 1)) * step(
        0.0001, surface.specRange);

    float3 specular = smoothSpec * surface.specColor * light.shadowAttenuation * surface.specMaskMap;

    #if defined(_SPEC_FLIP_BOOK)

    int frameCount = GetFrameCount() * 0.4;
    if (fmod(frameCount, 50) <= 16)
    {
        float4 flipBook = GetSpecFlipbook(
            surface.specFlipbookUV, frameCount);

        flipBook.rgb *= smoothSpec * light.shadowAttenuation;
        specular += flipBook.rgb * flipBook.a;
    }

    #endif

    return specular;
}

float3 CellDiffuse(ToonSurface surface, Light light, float pixelWidth, float spec)
{
     // return float3(ToonShadow(surface, light), ToonShadow(surface, light), ToonShadow(surface, light));
    // 漫反射
    float ndotl = dot(surface.normal, light.direction);
    ndotl = ndotl * 0.5 + 0.5;
    // float shadowAtten = ndotl * light.shadowAttenuation;

    float diffuse = (smoothstep(-pixelWidth + surface.diffuseRange, pixelWidth + surface.diffuseRange, ndotl) * surface.
        surfaceShadowSmooth + step(surface.diffuseRange, ndotl) * (1.0 - surface.
            surfaceShadowSmooth)) ;

    float3 diffCol1 = diffuse * surface.color * light.color;
    float3 diffCol2 = (1 - diffuse) * surface.surfaceShadowColor * surface.color;
    // 阴影平滑
    #if defined(_SURFACE_SHADOW_RAMP)
    float shadow = 1 - ToonShadow(surface,light);
    diffCol2 = shadow * surface.surfaceShadowColor * surface.color;
    diffCol1 = (1 - shadow) * surface.color * light.color;
    #endif

    #if defined(_SURFACE_SHADOW_MASK)
    diffCol2 *= surface.surfaceShadowMask;
    #endif

    float3 diffColor = diffCol1 + diffCol2;

    return diffColor;
}

float3 CellRim(ToonSurface surface, Light light, float pixelWidth, float diffuse)
{
    float3 rimColor = (float3).0;
    //边缘光
    #if defined(_RIM_LIGHTING)
    float rimValue = pow(1 - dot(surface.normal, surface.viewDirection), surface.rimPower);
    float rimStep = smoothstep(-pixelWidth + surface.rimThreshold, pixelWidth + surface.rimThreshold, rimValue);
    rimColor = surface.color * light.color * rimStep * surface.rimColor * 2 * diffuse;
    #endif

    return rimColor;
}

float3 CelLighting(ToonSurface surface, Light light)
{
    float3 finalColor = .0;

    // 高光
    float3 halfView = normalize(light.direction + surface.viewDirection);
    float spec = max(0, dot(surface.normal, halfView));
    float pixelWidth = fwidth(spec) * 0.5;

    float3 highLight = CellHighLight(surface, light, pixelWidth, spec);
    float3 diffuse = CellDiffuse(surface, light, pixelWidth, spec);
    float3 rim = CellRim(surface, light, pixelWidth, diffuse);

    return highLight + diffuse + rim;
}

float3 CelLighting(ToonSurface surface)
{
    float3 color = .0;

    Light mainLight = GetMainLight(surface.shadowCoords);

    color += CelLighting(surface, mainLight);

    return color;
}

#endif
