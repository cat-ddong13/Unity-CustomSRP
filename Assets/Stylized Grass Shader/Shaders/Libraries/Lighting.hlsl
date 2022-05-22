//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

void ApplyTranslucency(inout float3 color, float3 viewDirectionWS, Light light, float amount)
{
	float VdotL = saturate(dot(-viewDirectionWS, light.direction));
	VdotL = pow(VdotL, 4);

	//Translucency masked by shadows and grass mesh bottom
	float tMask = VdotL * light.shadowAttenuation * light.distanceAttenuation;

	//Fade the effect out as the sun approaches the horizon (75 to 90 degrees)
	half sunAngle = dot(float3(0, 1, 0), light.direction);
	half angleMask = saturate(sunAngle * 6.666); /* 1.0/0.15 = 6.666 */

	tMask *= angleMask;

	float3 tColor = color + BlendOverlay((light.color), color);
	color = lerp(color, tColor, tMask * (amount * 4.0));
}

//Blinn-phong shading with SH
half3 SimpleLighting(Light light, half3 normalWS, half3 bakedGI, half3 albedo, half occlusion, half3 emission)
{
	light.color *= light.distanceAttenuation * light.shadowAttenuation;

	half3 diffuseColor = bakedGI + LightingLambert(light.color, light.direction, normalWS);

	return (albedo * diffuseColor) + emission;
}

// General function to apply lighting based on the configured mode
half3 ApplyLighting(SurfaceData surfaceData, InputData input, Light mainLight, half translucency)
{
	half3 color = 0;

#if defined(_SCREEN_SPACE_OCCLUSION) && VERSION_GREATER_EQUAL(10,0)
	AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(input.normalizedScreenSpaceUV);
	surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);

	#ifdef _UNLIT
	surfaceData.albedo *= min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
	#endif
#endif

#ifdef _UNLIT
	color = surfaceData.albedo;
#endif

#ifndef _UNLIT

	half4 shadowMask = 1.0;
	
	#if VERSION_GREATER_EQUAL(10,0)
	//https://github.com/Unity-Technologies/Graphics/blob/47c15c6a9746f2c9bf0635db2f3ab6669281f461/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl#L34
	#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON) //Baked shadows
	shadowMask = input.shadowMask;
	#elif !defined (LIGHTMAP_ON)
	shadowMask = unity_ProbesOcclusion;
	#else
	shadowMask = half4(1, 1, 1, 1);
	#endif
	#endif
	
	#if defined(_SCREEN_SPACE_OCCLUSION) && VERSION_GREATER_EQUAL(10,0)
	mainLight.color *= aoFactor.directAmbientOcclusion;
	input.bakedGI *= aoFactor.indirectAmbientOcclusion;
	#endif

	//Shading for main light
	
#if _ADVANCED_LIGHTING
	// BRDFData holds energy conserving diffuse and specular material reflections and its roughness.
	BRDFData brdfData;
	//Note: _SPECULARHIGHLIGHTS_OFF is forced off
	InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

	// Mix diffuse GI with environment reflections.
	color = GlobalIllumination(brdfData, input.bakedGI, surfaceData.occlusion, input.normalWS, input.viewDirectionWS);

	// LightingPhysicallyBased computes direct light contribution.
#if VERSION_GREATER_EQUAL(9,0)
	color += LightingPhysicallyBased(brdfData, mainLight, input.normalWS, input.viewDirectionWS, true);
#else
	color += LightingPhysicallyBased(brdfData, mainLight, input.normalWS, input.viewDirectionWS);
#endif
#endif
	
#if _SIMPLE_LIGHTING
	#if defined(_SCREEN_SPACE_OCCLUSION) && VERSION_GREATER_EQUAL(10,0)
	//MixRealtimeAndBakedGI has no occlusion factor, multiply GI by occlusion to emulate the behaviour of LightingPhysicallyBased
	input.bakedGI *= surfaceData.occlusion;
	#endif
	//Simple diffuse and specular shading
	MixRealtimeAndBakedGI(mainLight, input.normalWS, input.bakedGI, shadowMask);

	color = SimpleLighting(mainLight, input.normalWS, input.bakedGI, surfaceData.albedo.rgb, surfaceData.occlusion, surfaceData.emission);
#endif

	//Shading for point/spot lights
	
#ifdef _ADDITIONAL_LIGHTS_VERTEX
	#if defined(_SCREEN_SPACE_OCCLUSION) && VERSION_GREATER_EQUAL(10,0)
	input.vertexLighting *= aoFactor.directAmbientOcclusion;
	#endif
	
	//Apply light color, previously calculated in vertex shader
	color += input.vertexLighting;
#endif // Vertex lights

	// Additional lights loop per-pixel
#if _ADDITIONAL_LIGHTS

	uint additionalLightsCount = GetAdditionalLightsCount();
	for (uint i = 0u; i < additionalLightsCount; ++i)
	{
		#if VERSION_GREATER_EQUAL(10,0)
		Light light = GetAdditionalLight(i, input.positionWS, shadowMask);
		#else
		Light light = GetAdditionalLight(i, input.positionWS);
		#endif

		#if defined(_SCREEN_SPACE_OCCLUSION) && VERSION_GREATER_EQUAL(10,0)
		light.color *= aoFactor.directAmbientOcclusion;
		#endif
		
#if _ADVANCED_LIGHTING
		// Same functions used to shade the main light.
#if VERSION_GREATER_EQUAL(9,0)
		color += LightingPhysicallyBased(brdfData, light, input.normalWS, input.viewDirectionWS, true);
#else
		color += LightingPhysicallyBased(brdfData, light, input.normalWS, input.viewDirectionWS);
#endif
		
		// Apply translucency for additional lights?
		//ApplyTranslucency(color, viewDirectionWS, light, translucency);
#endif
		
#if _SIMPLE_LIGHTING
		//Diffuse + specular lighting
		color += SimpleLighting(light, input.normalWS, input.bakedGI, surfaceData.albedo.rgb, surfaceData.occlusion, surfaceData.emission);
#endif
	}
#endif //Additional lights per-pixel

	ApplyTranslucency(color, input.viewDirectionWS, mainLight, translucency);
#endif //Not unlit

	//Emission is always added on top of lighting
	color += surfaceData.emission;

	return color;
}