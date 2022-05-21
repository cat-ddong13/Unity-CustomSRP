Shader "Custom/Water Surface Example"
{
  Properties
  {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic ("Metallic", Range(0,1)) = 0.0
  }
  SubShader
  {
    Tags { "RenderType"="Opaque" }
    LOD 200
    
    CGPROGRAM

    #pragma vertex vert
    #pragma surface surf Standard addshadow fullforwardshadows
    #pragma target 3.5 // Boing Kit requres shader model 3.5 or newer


    // include BoingKit.cginc to use the ApplyBoingReactorFieldPerVertex functions
    #include "../../../Shader/BoingKit.cginc"

    // check if BOING_KIT_SUPPORTED is defined to make sure compilation target supports structured buffer (required by BoingKit.cginc)
    #if defined(BOING_KIT_SUPPORTED)
    void vert(inout appdata_full i)
    {
      // convert everything to world space
      float3 posWs = mul(unity_ObjectToWorld, i.vertex).xyz;
      float3 normWs = mul(unity_ObjectToWorld, float4(i.normal, 0.0f)).xyz;
      float3 pivot = mul(unity_ObjectToWorld, float4(0.0f, 0.0f, 0.0f, 1.0f)).xyz;

      // call ApplyBoingReactorFieldPerVertex
      BoingReactorFieldResults results = ApplyBoingReactorFieldPerVertex(posWs, normWs, pivot);

      // convert everything back to object space
      i.vertex.xyz = mul(unity_WorldToObject, float4(results.position, 1.0f)).xyz;

      // calculate X & Z differentials
      BoingReactorFieldResults resultsDxNeg = ApplyBoingReactorFieldPerVertex(posWs + float4(-0.5f, 0.0f, 0.0f, 0.0f), normWs, pivot);
      BoingReactorFieldResults resultsDxPos = ApplyBoingReactorFieldPerVertex(posWs + float4(+0.5f, 0.0f, 0.0f, 0.0f), normWs, pivot);
      BoingReactorFieldResults resultsDzNeg = ApplyBoingReactorFieldPerVertex(posWs + float4(0.0f, 0.0f, -0.5f, 0.0f), normWs, pivot);
      BoingReactorFieldResults resultsDzPos = ApplyBoingReactorFieldPerVertex(posWs + float4(0.0f, 0.0f, +0.5f, 0.0f), normWs, pivot);
      
      // calculate normals
      float3 dx = (resultsDxPos.position - resultsDxNeg.position).xyz;
      float3 dz = (resultsDzPos.position - resultsDzNeg.position).xyz;
      i.normal.xyz = mul(unity_WorldToObject, float4(-normalize(cross(dx, dz)), 0.0f)).xyz;
    }
    #else
    void vert(inout appdata_full i)
    {
      
    }
    #endif


    sampler2D _MainTex;

    struct Input
    {
      float2 uv_MainTex;
    };

    half _Glossiness;
    half _Metallic;
    fixed4 _Color;

    void surf (Input IN, inout SurfaceOutputStandard o)
    {
      // Albedo comes from a texture tinted by color
      fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
      o.Albedo = c.rgb;
      // Metallic and smoothness come from slider variables
      o.Metallic = _Metallic;
      o.Smoothness = _Glossiness;
      o.Emission = float4(0.2f, 0.2f, 0.2f, 1.0f);
      o.Alpha = c.a;
    }
    ENDCG
  }
  FallBack "Diffuse"
}
