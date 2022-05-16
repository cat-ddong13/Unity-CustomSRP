Shader "Custom RP/Toon/Outlines"
{
    Properties
    {
        _OutlineWidth("Outline Width",Range(0,1)) = 0.01
        _OutlineColor("Outline Color",Color) = (0.0,0.0,0.0,1.0)
        [KWEnum(_Outline,Normal,_,Tangent,_TANGENT_AS_NORMAL)]
        _OutlineNormalSource("Outline Normal Source",Float ) = 0
        [KWEnum(ShellMethods,_,ZBias,_Z_BIAS,VertexNormal,_VERTEX_NORMAL)]
        _OutlineType("Outline Type",Float) = 0
    }
    SubShader
    {
        Pass
        {
            Name "Outlines Test"
            //            Tags
            //            {
            //                "LightMode"="SRPDefaultUnlit"
            //            }
            Cull Front
            HLSLPROGRAM
            #pragma target 3.5
            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Outlines.hlsl"

            #pragma shader_feature _ENABLE_OUTLINES
            #pragma shader_feature _ _OUTLINE_TANGENT_AS_NORMAL
            #pragma shader_feature _ _OUTLINE_Z_BIAS _OUTLINE_VERTEX_NORMAL
            #pragma shader_feature _OUTLINE_ZOOM_FIXED_WIDTH
            #pragma shader_feature _OUTLINE_INCLUDE_ASPECT_RATIO

            #pragma vertex OutlinesVertexPass
            #pragma fragment OutlinesFragmentPass
            ENDHLSL
        }
    }
    CustomEditor "JTRP.ShaderDrawer.LWGUI"
    FallBack "Custom RP/Unlit"
}