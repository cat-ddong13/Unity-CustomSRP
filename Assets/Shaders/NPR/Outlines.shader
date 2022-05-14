Shader "Custom RP/Toon/Outlines"
{
    Properties
    {
        _Outline("Outline Width",Range(0,1)) = 0.01
        _OutlineColor("Outline Color",Color) = (0.0,0.0,0.0,1.0)
    }
    SubShader
    {
        Pass
        {
            Name "Outlines ZBias"
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
            }
            Cull Front
            HLSLPROGRAM
            #pragma target 3.5
            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Outlines.hlsl"
            #pragma vertex ZBiasVertexPass
            #pragma fragment DefaultFragmentPass
            ENDHLSL
        }
        Pass
        {
            Name "Outlines Vertex Normal 1"
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
            }
            Cull Front
            HLSLPROGRAM
            #pragma target 3.5
            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Outlines.hlsl"
            #pragma vertex VertexNormal1VertexPass
            #pragma fragment DefaultFragmentPass
            ENDHLSL
        }
        Pass
        {
            Name "Outlines Vertex Normal 2"
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
            }
            Cull Front
            HLSLPROGRAM
            #pragma target 3.5
            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Outlines.hlsl"
            #pragma vertex VertexNormal2VertexPass
            #pragma fragment DefaultFragmentPass
            ENDHLSL
        }
        Pass
        {
            Name "Outlines Vertex Shell Methords"
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
            }
            Cull Front
            HLSLPROGRAM
            #pragma target 3.5
            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Outlines.hlsl"
            #pragma vertex ShellMethodsVertexPass
            #pragma fragment DefaultFragmentPass
            ENDHLSL
        }
        Pass
        {
            Name "Outlines Vertex Shell Methords"
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
            }
            Cull Front
            HLSLPROGRAM
            #pragma target 3.5
            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Outlines.hlsl"
            #pragma vertex ShellMethodsVertexPass
            #pragma fragment DefaultFragmentPass
            ENDHLSL
        }
        Pass
        {
            Name "Outlines Test"
            Tags
            {
                "LightMode"="SRPDefaultUnlit"
            }
            Cull Front
            HLSLPROGRAM
            #pragma target 3.5
            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Outlines.hlsl"
            #pragma vertex VertexNormal1VertexPass
            #pragma fragment DefaultFragmentPass
            ENDHLSL
        }
    }
    //    FallBack "Custom RP/Unlit"
}