Shader "Custom RP/Toon/Toon"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white"{}
        [HDR]_BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        [Space(10)]
        [Main(OutlineGroup,_ENABLE_OUTLINES)]_OutlineGroup("Outline Group",Float) = 0
        
        [Sub(OutlineGroup)]_OutlineWidth("Outline Width",Range(0,1)) = 0.01
        [Sub(OutlineGroup)]_OutlineColor("Outline Color",Color) = (0.0,0.0,0.0,1.0)
        
        [KWEnum(OutlineGroup,ShellMethods,_,ZBias,_OUTLINE_Z_BIAS,VertexNormal,_OUTLINE_VERTEX_NORMAL)]
        _OutlineType("Outline Type",Float) = 2
        
        [KWEnum(OutlineGroup_OUTLINE_VERTEX_NORMAL#_,Normal,_,Tangent,_OUTLINE_TANGENT_AS_NORMAL)]
        _OutlineNormalSource("Outline Normal Source",Float ) = 0
        
        [SubToggle(OutlineGroup_OUTLINE_VERTEX_NORMAL,_OUTLINE_ZOOM_FIXED_WIDTH)]
        _ZoomFixedWidth("Fixed Width When Zoom",Float) = 1
        [SubToggle(OutlineGroup_OUTLINE_VERTEX_NORMAL,_OUTLINE_INCLUDE_ASPECT_RATIO)]
        _IncludeAspectRatio("Include Aspect-Radio",Float) = 1
    }
    SubShader
    {
        UsePass "Custom RP/Toon/Outlines/OUTLINES TEST"
        Pass
        {
            Name "Toon Lit"
            Tags
            {
                "LightMode" = "CustomLit"
            }
            Cull Back
            HLSLPROGRAM
            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Assets/Custom RP/Shaders/LitInput.hlsl"
            #include "ToonPasses.hlsl"

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            ENDHLSL
        }
        UsePass "Custom RP/Lit/CUSTOM SHADOWCASTER"
        UsePass "Custom RP/Lit/CUSTOM META"
    }
    FallBack "Custom RP/Lit/CustomLit"
    CustomEditor "JTRP.ShaderDrawer.LWGUI"
}