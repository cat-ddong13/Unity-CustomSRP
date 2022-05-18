Shader "Custom RP/Toon/Toon"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white"{}
        [HDR]_BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)

        [Main(DiffuseGroup,_,2)]_DiffuseGroup("Diffuse",Float) = 0
        _DiffuseRange("Diffuse Range",Range(0,1)) = 0.5
        _SurfaceShadowSmooth("Surface Shadow Smooth",Range(0,1)) = 0
        _SurfaceShadowColor("Surface Shadow Color",Color) = (0.0,.0,.0,1.0)

        [Main(SpecMapGroup,_SPEC_MASK_MAP)]_SpecMapToggle("Specular",Float) = 0
        [Sub(SpecMapGroup)][NoScaleOffset]_SpecMaskMap("Spec Mask Map",2D) = "white"{}
        [Sub(SpecMapGroup)]_SpecColor("SpecColor",Color) = (1.0,1.0,1.0,1.0)
        [Sub(SpecMapGroup)]_SpecRange("Spec Range",Range(0,1)) = 0.1
        [Sub(SpecMapGroup)]_SpecTexRotate("Spec Tex Rotate",Range(0,180)) = 0

        [Main(RimLightingGroup,_RIM_LIGHTING)]_RimLightingToggle("Rim Lighting",Float) = 0
        [Sub(RimLightingGroup)]_RimColor("Rim Color",Color) = (1.0,1.0,1.0,1.0)
        [Sub(RimLightingGroup)]_RimThreshold("Rim Threshold",Float) = 0.5
        [Sub(RimLightingGroup)]_RimPower("Rim Power",Float) = 2

        [Main(NormalMapGroup,_NORMAL_MAP)]_NormalMapToggle("Normal Map",Float) = 0
        [Sub(NormalMapGroup)][NoScaleOffset]_NormalMap("Normals",2D) = "bump"{}
        [Sub(NormalMapGroup)]_NormalScale("Normal Scale",Range(0,1)) = 1

        [Main(OutlineGroup,_ENABLE_OUTLINES)]_OutlineGroup("Outlines",Float) = 0

        [Sub(OutlineGroup)]_OutlineWidth("Outline Width",Range(0,1)) = 0.01
        [Sub(OutlineGroup)]_OutlineColor("Outline Color",Color) = (0.0,0.0,0.0,1.0)

        [KWEnum(OutlineGroup,ShellMethods,_,ZBias,_OUTLINE_Z_BIAS,VertexNormal,_OUTLINE_VERTEX_NORMAL)]
        _OutlineType("Outline Type",Float) = 2

        [SubToggle(OutlineGroup_OUTLINE_VERTEX_NORMAL,_OUTLINE_ZOOM_FIXED_WIDTH)]
        _ZoomFixedWidth("Fixed Width When Zoom",Float) = 1
        [SubToggle(OutlineGroup_OUTLINE_VERTEX_NORMAL,_OUTLINE_INCLUDE_ASPECT_RATIO)]
        _IncludeAspectRatio("Include Aspect-Radio",Float) = 1

        [KWEnum(OutlineGroup,None,_,R,_VERTEX_COLOR_CHANNEL_R,G,_VERTEX_COLOR_CHANNEL_G,B,_VERTEX_COLOR_CHANNEL_B,A,_VERTEX_COLOR_CHANNEL_A)]
        _VertexColor("Outline Vertex Color Detail",Float) = 0
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
            #pragma shader_feature _NORMAL_MAP
            #pragma shader_feature _SPEC_MASK_MAP
            #pragma shader_feature _RIM_LIGHTING

            #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
            #include "Assets/Custom RP/Shaders/LitInput.hlsl"
            #include "ToonPasses.hlsl"

            #pragma vertex ToonPassVertex
            #pragma fragment ToonPassFragment
            ENDHLSL
        }
        UsePass "Custom RP/Lit/CUSTOM SHADOWCASTER"
        UsePass "Custom RP/Lit/CUSTOM META"
    }
    FallBack "Custom RP/Lit/CustomLit"
    CustomEditor "JTRP.ShaderDrawer.LWGUI"
}