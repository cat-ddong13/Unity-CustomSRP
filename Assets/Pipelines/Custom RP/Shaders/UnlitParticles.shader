Shader "Custom RP/Particles/Unlit"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white"{}
        [HDR]_BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _Cutoff("Alpha Cutoff",Range(0.0,1.0))= 0.5
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend",Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Dst Blend",Float) = 0
        [Enum(Off,0,On,1)]_ZWrite("ZWrite",int) = 0
        [Toggle(_CLIPPING)]_Clipping("Alpha Clipping",Float) = 0
        [Toggle(_VERTEX_COLORS)]_VertexColor("Vertex Colors",float) = 0
        [Toggle(_FLIPBOOK_BLENDING)]_FlipbookBlending("Flipbook Blending",Float) = 0
        [Toggle(_NEAR_FADE)]_NearFade("Near Fade",Float) = 0
        _NearFadeDistance("Near Fade Distance",Range(.0,10.0)) = 1
        _NearFadeRange("Near Fade Range",Range(0.01,10.0)) = 1

        [Toggle(_SOFT_PARTICLES)]_SoftParticles("Soft Particles",Float) = 0
        _SoftParticlesDistance("Soft Particles Distance",Range(.0,10.0)) = 0
        _SoftParticlesRange("Soft Particles Range",Range(0.01,10.0)) = 1

        [Toggle(_DISTORTION)]_Distortion("Distortion",Float) = 0
        [NoScaleOffset]_DistortionMap("Distortion Vectors",2D) = "bumb"{}
        _DistortionStrength("Distortion Strength",Range(.0,.2)) = .1
        _DistortionBlend("Distortion Blend",Range(0,1.0)) = 1
    }
    SubShader
    {
        HLSLINCLUDE
        #include "../ShaderLibrary/Common.hlsl"
        #include "UnlitInput.hlsl"
        ENDHLSL
        Pass
        {
            Name "Unlit Base"
            Blend [_SrcBlend] [_DstBlend],One OneMinusSrcAlpha
            ZWrite [_ZWrite]
            HLSLPROGRAM
            #include "UnlitPass.hlsl"

            #pragma target 3.5
            // 特性-裁剪
            #pragma shader_feature _CLIPPING
            // 启用顶点色
            #pragma shader_feature _VERTEX_COLORS
            // 翻页动画融合
            #pragma shader_feature _FLIPBOOK_BLENDING
            // 开启近裁剪面淡出
            #pragma shader_feature _NEAR_FADE
            // 软粒子
            #pragma shader_feature _SOFT_PARTICLES
            // 扭曲
            #pragma shader_feature _DISTORTION

            // 特性-gpu instancing
            #pragma multi_compile_instancing
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            ENDHLSL
        }

        Pass
        {
            Name "Shadow Caster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            ZWrite On
            // 颜色通道遮罩
            ColorMask 0
            HLSLPROGRAM
            #include "ShadowCasterPass.hlsl"

            // 开启d3d11调试，加此命令后相关的名称与代码不会被剔除，便于在调试工具(如RenderDoc)中进行查看分析
            #pragma enable_d3d11_debug_symbols
            #pragma target 3.5
            // 特性-空、阴影裁剪、阴影抖动
            #pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
            #pragma multi_compile_instancing

            #pragma vertex ShadowCasterPassVertex
            #pragma fragment ShadowCasterPassFragment
            ENDHLSL
        }
    }
    CustomEditor "Rendering.CusomSRP.Editor.CustomShaderGUI"
}