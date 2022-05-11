Shader "Hidden/Custom RP/Camera Renderer"
{
    SubShader
    {
        Cull Off
        ZTest Off
        ZWrite Off
        
        HLSLINCLUDE
        #include "../ShaderLibrary/Common.hlsl"
        #include "CameraRenderPasses.hlsl"
        ENDHLSL
        
        Pass
        {
            Name "Copy Base"
            Blend [_CameraSrcBlend] [_CameraDstBlend]
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment CopyPassFragment
            ENDHLSL
        }
        
        Pass
        {
            Name "Copy Depth"
            ColorMask 0
            ZWrite On
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment CopyDepthFragment
            ENDHLSL
        }
    }
}