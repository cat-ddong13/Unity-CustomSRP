Shader "Custom RP/Toon/Outlines"
{
    Properties
    {
        _OutlineWidth("Outline Width",Range(0,1)) = 0.01
        _OutlineColor("Outline Color",Color) = (0.0,0.0,0.0,1.0)
        
        [KWEnum(_,Normal,_,Tangent,_TANGENT_AS_NORMAL)]
        _OutlineNormalSource("Outline Normal Source",Float ) = 0
        
        [KWEnum(_,ShellMethods,_,ZBias,_Z_BIAS,VertexNormal,_VERTEX_NORMAL)]
        _OutlineType("Outline Type",Float) = 0
        
        [KWEnum(_,None,_,R,_VERTEX_COLOR_CHANNEL_R,G,_VERTEX_COLOR_CHANNEL_G,B,_VERTEX_COLOR_CHANNEL_B,A,_VERTEX_COLOR_CHANNEL_A)]
        _VertexColor("Outline Vertex Color Detail",Float) = 0
    }
    SubShader
    {
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
            #include "Assets/Pipelines/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Outlines.hlsl"

            #pragma shader_feature _ENABLE_OUTLINES
            #pragma shader_feature _ _OUTLINE_TANGENT_AS_NORMAL
            #pragma shader_feature _ _OUTLINE_Z_BIAS _OUTLINE_VERTEX_NORMAL
            #pragma shader_feature _OUTLINE_ZOOM_FIXED_WIDTH
            #pragma shader_feature _OUTLINE_INCLUDE_ASPECT_RATIO
            #pragma shader_feature _NORMAL_MAP
            #pragma shader_feature _ _VERTEX_COLOR_CHANNEL_R _VERTEX_COLOR_CHANNEL_G _VERTEX_COLOR_CHANNEL_B _VERTEX_COLOR_CHANNEL_A

            #pragma vertex OutlinesVertexPass
            #pragma fragment OutlinesFragmentPass
            ENDHLSL
        }
    }
    FallBack "Custom RP/Unlit"
    CustomEditor "JTRP.ShaderDrawer.LWGUI"
}