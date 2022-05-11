Shader "Custom RP/Unlit"
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
    }
    SubShader
    {
        HLSLINCLUDE
        #include "../ShaderLibrary/Common.hlsl"
        #include "UnlitInput.hlsl"
        ENDHLSL
        Pass
        {
            Blend [_SrcBlend] [_DstBlend],One OneMinusSrcAlpha
            ZWrite [_ZWrite]
            HLSLPROGRAM
            #include "UnlitPass.hlsl"

            #pragma target 3.5
            // 特性-裁剪
            #pragma shader_feature _CLIPPING
            // 特性-gpu instancing
            #pragma multi_compile_instancing
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            ENDHLSL
        }
        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
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
        Pass
        {
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