Shader "Custom RP/Lit"
{
    Properties
    {
        [NoScaleOffset]_BaseMap("Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1,1,1,1)

        _Metallic("Metallic",Range(0,1)) = 0.5
        _Smoothness("Smoothness",Range(0,1)) = 0.5
        _Occlusion("Occlusion",Range(0,1)) = 1
        _Fresnel("_Fresnel",Range(0,1)) = 1

        [Toggle(_NORMAL_MAP)]_NormalMapToggle("Normal Map",Float) = 0
        [NoScaleOffset]_NormalMap("Normals",2D) = "bump"{}
        _NormalScale("Normal Scale",Range(0,1)) = 1

        [HideInInspector]_MainTex("Texture for Lightmap",2D) = "white"{}
        [HideInInSpector]_Color("Color for Lightmap",Color) = (0.5,0.5,0.5,1.0)

        _EmissionMap("Emission",2D) = "white"{}
        [HDR]_EmissionColor("HDR",Color) = (0.0,0.0,0.0,0.0)

        _Cutoff("Alpha Cutoff",Range(0.0,1.0))= 0.5
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend",Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Dst Blend",Float) = 0
        [Enum(Off,0,On,1)]_ZWrite("ZWrite",int) = 0
        [Toggle(_CLIPPING)]_Clipping("Alpha Clipping",Float) = 0
        [Toggle(_PREMULTIPLY_ALPHA)]_PremultiplyAlpha("Premultiply Alpha",Float) = 0

        [Toggle(_MASK_MAP)]_MaskMapToggle("Mask Map",Float) = 0
        [NoScaleOffset]_MaskMap("Mask (MODS)",2D) = "white"{}

        [Toggle(_DETAIL_MAP)]_DetailMapToggle("Detail Map",Float) = 0
        _DetailMap("Detail",2D) = "linearGrey"{}
        _DetailAlbedo("Detail Albedo",Range(0,1)) = 1
        _DetailSmoothness("Detail Smoothness",Range(0,1)) = 1

        [NoScaleOffset]_DetailNormalMap("Detail Normal",2D) = "bump"{}
        _DetailNormalScale("Detail Normal Scale",Range(0,1)) = 1

        [KeywordEnum(On,Clip,Dither,Off)]_Shadows("Shadows",Float) = 0
        [Toggle(_RECEIVE_SHADOWS)]_ReceiveShadows("Receive Shadows",Float) = 0
    }
    SubShader
    {
        HLSLINCLUDE
        #include "../ShaderLibrary/Common.hlsl"
        #include "LitInput.hlsl"
        ENDHLSL
        Pass
        {
            Name "Custom Lit"
            Tags
            {
                "LightMode" = "CustomLit"
            }

            Blend [_SrcBlend] [_DstBlend],One OneMinusSrcAlpha
            ZWrite [_ZWrite]
            HLSLPROGRAM
            #include "LitPass.hlsl"

            #pragma target 3.5

            // 开启d3d11调试，加此命令后相关的名称与代码不会被剔除，便于在调试工具(如RenderDoc)中进行查看分析
            #pragma enable_d3d11_debug_symbols

            // 法线贴图
            #pragma shader_feature _NORMAL_MAP
            // 遮罩图
            #pragma shader_feature _MASK_MAP
            // 细节图
            #pragma shader_feature _DETAIL_MAP

            // 裁剪
            #pragma shader_feature _CLIPPING
            // diffuse *= alpha
            #pragma shader_feature _PREMULTIPLY_ALPHA
            // 接收阴影
            #pragma shader_feature _RECEIVE_SHADOWS

            // 光照贴图模式
            #pragma multi_compile _ LIGHTMAP_ON
            // gpu-instancing
            #pragma multi_compile_instancing
            // 方向光阴影采样级别
            #pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            // 非平行光阴影采样级别
            #pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
            // 阴影级联融合方式
            #pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
            // 阴影遮罩
            #pragma multi_compile _ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE
            // LOD淡入淡出
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            // 逐光照对象
            #pragma multi_compile _ _LIGHTS_PER_OBJECT

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Custom ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            // 颜色通道遮罩
            ColorMask 0
            HLSLPROGRAM
            #include "ShadowCasterPass.hlsl"

            #pragma target 3.5

            #pragma enable_d3d11_debug_symbols

            #pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER

            #pragma multi_compile_instancing
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex ShadowCasterPassVertex
            #pragma fragment ShadowCasterPassFragment
            ENDHLSL
        }
        Pass
        {
            Name "Custom Meta"
            //metapass
            //https://docs.unity3d.com/cn/current/Manual/MetaPass.html
            Tags
            {
                "LightMode" = "Meta"
            }
            Cull Off

            HLSLPROGRAM
            #include "MetaPass.hlsl"

            #pragma target 3.5
            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment
            ENDHLSL
        }
    }

    CustomEditor "Rendering.CusomSRP.Editor.CustomShaderGUI"
}