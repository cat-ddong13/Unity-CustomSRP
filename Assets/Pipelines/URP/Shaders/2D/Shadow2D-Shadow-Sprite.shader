Shader "Hidden/Shadow2DShadowSprite"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HideInInspector] _ShadowColorMask("__ShadowColorMask", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }

        Cull Off
        BlendOp Add
        Blend One One, One One
        ZWrite Off
        ZTest Always

        Pass
        {
            //Bit 0: Composite Shadow Bit, Bit 1: Global Shadow Bit
            Stencil
            {
                Ref  0
                Comp Equal
                Pass Keep
                Fail Keep
            }

            ColorMask [_ShadowColorMask]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/Pipelines/URP/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4    _MainTex_ST;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 main = tex2D(_MainTex, i.uv);
                half color = main.a;
                return half4(color, color, color, color);
            }
            ENDHLSL
        }
    }
}