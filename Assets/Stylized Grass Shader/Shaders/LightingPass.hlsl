//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

struct Varyings
{
	float4 uv                       : TEXCOORD0;
	DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

	float4 color					: COLOR0;
	float3 positionWS               : TEXCOORD2;
	half3  normalWS                 : TEXCOORD3;

#ifdef _NORMALMAP
	half3 tangentWS                 : TEXCOORD4;
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
	half4 fogFactorAndVertexLight   : TEXCOORD5; // x: fogFactor, yzw: vertex light
#else
	half  fogFactor                 : TEXCOORD5;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	float4 shadowCoord              : TEXCOORD6; // compute shadow coord per-vertex for the main light
#endif
		
	float4 positionCS               : SV_POSITION;
	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

#define SHADOW_BIAS_OFFSET 0.01

float4 GetVertexShadowCoords(VertexOutput vertexData)
{
	//https://github.com/Unity-Technologies/Graphics/blob/47c15c6a9746f2c9bf0635db2f3ab6669281f461/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl#L423
	
#if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
	return ComputeScreenPos(vertexData.positionCS);
#else

	#if _SHADOWBIAS_CORRECTION
	//Move the shadowed position slightly away from the camera to avoid banding artifacts
	float3 shadowPos = vertexData.positionWS + (vertexData.viewDir * SHADOW_BIAS_OFFSET);
	#else
	float3 shadowPos = vertexData.positionWS;
	#endif
	
	return TransformWorldToShadowCoord(shadowPos);
#endif
}

float4 GetPixelShadowCoords(Varyings input, float3 viewDirWS)
{	
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) //Per-vertex coord if no cascades are used
	return input.shadowCoord; 
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS) //Shadow cascades

	#if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
	//Screen-space shadow map (pre-resolved)
	return ComputeScreenPos(input.positionCS);
	#else

	#if _SHADOWBIAS_CORRECTION
	//Move the shadowed position slightly away from the camera to avoid banding artifacts
	float3 shadowPos = input.positionWS + (viewDirWS * SHADOW_BIAS_OFFSET);
	#else
	float3 shadowPos = input.positionWS;
	#endif
	
	//Cascades in use, calculate per-pixel now
	return TransformWorldToShadowCoord(shadowPos);
	#endif

#else //No shadows
	//Unused, but needs to be initialized...
	return float4(0, 0, 0, 0);
#endif

}

Varyings LitPassVertex(Attributes input)
{
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

	float posOffset = ObjectPosRand01();

	WindSettings wind = PopulateWindSettings(_WindAmbientStrength, _WindSpeed, _WindDirection, _WindSwinging, BEND_MASK, _WindObjectRand, _WindVertexRand, _WindRandStrength, _WindGustStrength, _WindGustFreq);
	BendSettings bending = PopulateBendSettings(_BendMode, BEND_MASK, _BendPushStrength, _BendFlattenStrength, _PerspectiveCorrection);

	//Object space position, normals (and tangents)
	VertexInputs vertexInputs = GetVertexInputs(input);
	vertexInputs.normalOS = lerp(vertexInputs.normalOS , normalize(vertexInputs.positionOS.xyz), _NormalParams.x * lerp(1, BEND_MASK, _NormalParams.z));
	vertexInputs.normalOS = lerp(vertexInputs.normalOS, float3(0,1,0), _NormalParams.y * (1-BEND_MASK));
	//Apply transformations and bending/wind (Can't use GetVertexPositionInputs, because it would amount to double matrix transformations)
	VertexOutput vertexData = GetVertexOutput(vertexInputs, posOffset, wind, bending);

	
	//Vertex color
	output.color = input.color;
	output.color = ApplyVertexColor(input.positionOS, vertexData.positionWS.xyz, _BaseColor.rgb, AO_MASK, _OcclusionStrength, _VertexDarkening, _HueVariation, posOffset);

	half fogFactor = ComputeFogFactor(vertexData.positionCS.z);
	
	output.normalWS = vertexData.normalWS;

	OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
	OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
	
#ifdef _ADDITIONAL_LIGHTS_VERTEX
	//Apply per-vertex light if enabled in pipeline
	//Pass to fragment shader to apply in Lighting function
	half3 vertexLight = VertexLighting(vertexData.positionWS, vertexData.normalWS);
	output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
#else
	output.fogFactor = fogFactor;
#endif
	
#ifdef _NORMALMAP
	output.uv.zw = TRANSFORM_TEX(input.uv, _BumpMap);
	output.tangentWS = vertexData.tangentWS;
#else
	//Initialize with 0
	output.uv.zw = 0;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	output.shadowCoord = GetVertexShadowCoords(vertexData);
#endif
	
	output.uv.xy = TRANSFORM_TEX(input.uv, _BaseMap);
	output.positionWS = vertexData.positionWS;
	output.positionCS = vertexData.positionCS;

	return output;
}

void PopulateSurfaceData(Varyings input, out SurfaceData surfaceData)
{
	float4 mainTex = SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));

	//Albedo
	float3 albedo = mainTex.rgb;

	//Apply hue var and ambient occlusion from vertex stage
	albedo.rgb *= input.color.rgb;

	//Apply color map per-pixel
	if (_ColorMapUV.w == 1) {
		float mask = smoothstep(_ColorMapHeight, 1.0 + _ColorMapHeight, sqrt(input.color.a));
		albedo.rgb = lerp(ApplyColorMap(input.positionWS.xyz, albedo.rgb, _ColorMapStrength), albedo.rgb, mask);
	}

	float bendingMask = saturate(GetBendVector(input.positionWS.xyz).a);
	albedo.rgb = lerp(albedo.rgb, albedo.rgb * _BendTint.rgb, bendingMask * sqrt(input.color.a) * _BendTint.a);

	//Albedo must be saturated, may cause sparkles otherwise
	surfaceData.albedo = saturate(albedo);
	//Not using specular setup, free to use this to pass data
	surfaceData.specular = float3(0, 0, 0);
	surfaceData.metallic = 0.0;
	surfaceData.smoothness = _Smoothness;
#ifdef _NORMALMAP
	surfaceData.normalTS = SampleNormal(input.uv.zw, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
#else
	surfaceData.normalTS = float3(0.5, 0.5, 1.0);
#endif
	surfaceData.emission = 0.0;
	surfaceData.occlusion = 1.0;
	surfaceData.alpha = mainTex.a;
	
	#if VERSION_GREATER_EQUAL(10,0)
	surfaceData.clearCoatMask = 0.0h;
	surfaceData.clearCoatSmoothness = 0.0h;
	#endif
}

void PopulateLightingInputData(Varyings input, half3 normalTS, out InputData inputData)
{
	inputData = (InputData)0;
	inputData.positionWS = input.positionWS.xyz;

	#if defined(_NORMALMAP)
	float sgn = -1.0; //No support for mirrored meshes!
	float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
	inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
	#else
	inputData.normalWS = input.normalWS;
	#endif
	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
	
	inputData.viewDirectionWS = SafeNormalize(GetWorldSpaceViewDir(input.positionWS.xyz));

	inputData.shadowCoord = GetPixelShadowCoords(input, inputData.viewDirectionWS);

#ifdef _ADDITIONAL_LIGHTS_VERTEX
	inputData.fogCoord = input.fogFactorAndVertexLight.x;
	inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
#else
	inputData.fogCoord = input.fogFactor;
	//Unused, but needs to be initialized...
	inputData.vertexLighting = float3(0.0, 0.0, 0.0);
#endif
	
	inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
	
#if VERSION_GREATER_EQUAL(10,0)
	inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
	inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
#endif
}

half4 ForwardPassFragment(Varyings input) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

	WindSettings wind;
	if(_WindGustTint > 0) wind = PopulateWindSettings(_WindAmbientStrength, _WindSpeed, _WindDirection, _WindSwinging, AO_MASK, _WindObjectRand, _WindVertexRand, _WindRandStrength, _WindGustStrength, _WindGustFreq);

	SurfaceData surfaceData;
	PopulateSurfaceData(input, surfaceData);
	InputData inputData = (InputData)0;
	PopulateLightingInputData(input, surfaceData.normalTS, inputData);
	
	//Get main light first, need attenuation to mask wind gust
	Light mainLight = GetMainLight(inputData.shadowCoord);

	//Tint by wind gust
	if(_WindGustTint > 0)
	{
		wind.gustStrength = 1;
		float gust = SampleGustMap(input.positionWS.xyz, wind);
		surfaceData.albedo += gust * _WindGustTint * 10 * (mainLight.shadowAttenuation) * input.color.a;
		surfaceData.albedo = saturate(surfaceData.albedo);
	}
	
#ifdef _ALPHATEST_ON
	AlphaClip(surfaceData.alpha, _Cutoff, input.positionCS.xyz, input.positionWS.xyz, _FadeParams);
#endif

	float translucencyMask = input.color.a * _Translucency;

	float3 finalColor = ApplyLighting(surfaceData, inputData, mainLight, translucencyMask);

	finalColor = MixFog(finalColor, inputData.fogCoord);

	return half4(finalColor, surfaceData.alpha);
}