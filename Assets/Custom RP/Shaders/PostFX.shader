Shader "Hidden/Custom RP/PostFX"
{
    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off
        HLSLINCLUDE
        #pragma vertex DefaultPassVertex
        #include "../ShaderLibrary/Common.hlsl"
        #include "PostFXPasses.hlsl"
        ENDHLSL
        Pass
        {
            Name "Copy"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment CopyPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Bloom Horizontal"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment BloomHorizontalPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Bloom Vertical"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment BloomVerticalPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Bloom Additive"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment BloomAdditivePassFragment
            ENDHLSL
        }

        Pass
        {
            Name "Bloom Scatter"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment BloomScatterPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Bloom Prefilter"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment BloomPrefilterPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Bloom Prefileter Fireflies"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment BloomPrefilterFirefliesPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Bloom Scatter Final"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment BloomScatterFinalPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Color Grade None"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment ColorGradeNonePassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Color Grade ACES"

            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment ColorGradeACESPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Color Grade Neutral"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment ColorGradeNeutralPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Color Grade Reinhard"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment ColorGradeReinhardPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Apply Color Grade"
            Blend [_FinalSrcBlend] [_FinalDstBlend]
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment ApplyColorGradePassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Apply Color Grade With Luma"
            Blend [_FinalSrcBlend] [_FinalDstBlend]
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment ApplyColorGradeWithLumaPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Rescale Final"

            Blend [_FinalSrcBlend] [_FinalDstBlend]
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment FinalPassFragmentRescale
            ENDHLSL
        }
        Pass
        {
            Name "FXAA"

            Blend [_FinalSrcBlend] [_FinalDstBlend]

            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment FXAAPassFragment
            #pragma multi_compile _ FXAA_QUALITY_MEDIUM FXAA_QUALITY_LOW
            #include "FXAAPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "FXAA With Luma"

            Blend [_FinalSrcBlend] [_FinalDstBlend]

            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment FXAAPassFragment
            #pragma multi_compile _ FXAA_QUALITY_MEDIUM FXAA_QUALITY_LOW
            #define _FXAA_WITH_LUMA_IN_ALPHA
            #include "FXAAPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "Post Outline"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma fragment OutlineSobelPassFragment
            #include "FXAAPass.hlsl"
            ENDHLSL
        }
    }
}