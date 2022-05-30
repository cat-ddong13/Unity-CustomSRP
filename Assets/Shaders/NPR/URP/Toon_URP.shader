Shader "Toon/Toon_URP"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white"{}
        [HDR]_BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _DiffuseRange("Diffuse Range",Range(0,1)) = 0.5

        [Main(SurfaceShadow,_,2)]_DiffuseGroup("SurfaceShadow",Float) = 0
        [Sub(SurfaceShadow)]_SurfaceShadowSmooth("Surface Shadow Smooth",Range(0,1)) = 0
        [Sub(SurfaceShadow)]_SurfaceShadowColor("Surface Shadow Color",Color) = (0.0,.0,.0,1.0)
        [SubToggle(SurfaceShadow,_SURFACE_SHADOW_MASK)]_UseSurfaceShadowMask("Use Surface Shadow Mask",Float) = 0
        [Sub(SurfaceShadow_SURFACE_SHADOW_MASK)][NoScaleOffset]_SurfaceShadowMask("Surface Shadow Mask",2D) = "white"{}
        [SubToggle(SurfaceShadow,_SURFACE_SHADOW_RAMP)]_UseSurfaceShadowRamp("Use Surface Shadow Ramp",Float) = 0
        [Sub(SurfaceShadow_SURFACE_SHADOW_RAMP)][NoScaleOffset]_SurfaceShadowRamp("Surface Shadow Ramp",2D) = "white"{}

        [Main(SpecMapGroup,_SPEC_MASK_MAP)]_SpecMapToggle("Specular",Float) = 0
        [Sub(SpecMapGroup)][NoScaleOffset]_SpecMaskMap("Spec Mask Map",2D) = "white"{}
        [Sub(SpecMapGroup)]_SpecColor("SpecColor",Color) = (1.0,1.0,1.0,1.0)
        [Sub(SpecMapGroup)]_SpecRange("Spec Range",Range(0,1)) = 0.1
        [Sub(SpecMapGroup)]_SpecTexRotate("Spec Tex Rotate",Range(0,180)) = 0
        [SubToggle(SpecMapGroup,_SPEC_FLIP_BOOK)]_SpecFlipBookToggle("Spec Flip Book Toggle",Float) = 0
        [Sub(SpecMapGroup_SPEC_FLIP_BOOK)][NoScaleOffset]_SpecFlipBook("Spec Flip Book",2D) = "white"{}
        [SubToggle(SpecMapGroup_SPEC_FLIP_BOOK,_SPEC_FLIP_BOOK_BLEND)]_SpecFlipBookBlend("Spec Flip Book Blend",Float) = 0
        [Sub(SpecMapGroup_SPEC_FLIP_BOOK_BLEND)]_SpecFlipBookBlendRatio("Spec Flip Book Blend Radio",Range(0,1)) = 0.5
        [Sub(SpecMapGroup_SPEC_FLIP_BOOK)]_SpecFlipBookColor("Spec Flip Book Color",Color) = (1.0,1.0,1.0,1.0)

        [Main(RimLightingGroup,_RIM_LIGHTING)]_RimLightingToggle("Rim Lighting",Float) = 0
        [Sub(RimLightingGroup)]_RimColor("Rim Color",Color) = (1.0,1.0,1.0,1.0)
        [Sub(RimLightingGroup)]_RimThreshold("Rim Threshold",Range(0,1)) = 0.5
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

        [Main(EyeballFocusCamera,_EYEBALL_FOCUS_CAMERA)]_RefractionToggle("Eyeball Focus Camera",Float) = 0
        [Sub(EyeballFocusCamera)]_EyeballSize("Eyeball Size",Vector) = (0.05259,0.02881,0.0,0.0)
        [Sub(EyeballFocusCamera)]_FocusSpeed("Focus Speed",Float) = 15
        [Sub(EyeballFocusCamera)]_FrontNormal("Eyeball Size",Vector) = (0.05259,0.02881,0.0,0.0)
        [ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0

        [Main(MatcapGroup,_USE_MATCAP)]_MatcapToggle("Matcap",Float) = 0
        [Sub(MatcapGroup)][NoScaleOffset]_MatcapMap("Matcap Map",2D) = "white"{}
        [Sub(MatcapGroup)]_MapcapColor("SpecColor",Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "AlphaTest"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "NatureRendererInstancing" = "True"
        }
        UsePass "Toon/Outlines_URP/OUTLINES"
        Pass
        {
            Name "URP Toon"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull Back
            HLSLPROGRAM
            #pragma target 3.5

            // 开启d3d11调试，加此命令后相关的名称与代码不会被剔除，便于在调试工具(如RenderDoc)中进行查看分析
            #pragma enable_d3d11_debug_symbols
            //
            // 法线贴图
            #pragma shader_feature _NORMAL_MAP
            // // 裁剪
            // #pragma shader_feature _CLIPPING
            // // diffuse *= alpha
            // #pragma shader_feature _PREMULTIPLY_ALPHA
            // // 接收阴影
            #pragma shader_feature _RECEIVE_SHADOWS
            //
            // // 光照贴图模式
            // #pragma multi_compile _ LIGHTMAP_ON
            // // gpu-instancing
            // #pragma multi_compile_instancing
            // // 方向光阴影采样级别
            // #pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            // // 非平行光阴影采样级别
            // #pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
            // // 阴影级联融合方式
            // #pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
            // // 阴影遮罩
            // #pragma multi_compile _ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE
            // // LOD淡入淡出
            // #pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma shader_feature_local _SPEC_MASK_MAP
            #pragma shader_feature_local _RIM_LIGHTING
            #pragma shader_feature_local _SURFACE_SHADOW_MASK
            #pragma shader_feature_local _SURFACE_SHADOW_RAMP
            #pragma shader_feature_local _USE_EYE_LIGHTING
            #pragma shader_feature_local _EYEBALL_FOCUS_CAMERA
            #pragma shader_feature_local _SPEC_FLIP_BOOK
            #pragma shader_feature_local _SPEC_FLIP_BOOK_BLEND
            #pragma shader_feature_local _USE_MATCAP

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "Assets/Pipelines/URP/ShaderLibrary/Core.hlsl"
            #include "Assets/Pipelines/URP/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            #include "Common_URP.hlsl"
            #include "ToonInput_URP.hlsl"
            #include "ToonPasses_URP.hlsl"

            #pragma vertex ToonPassVertex
            #pragma fragment ToonPassFragment
            ENDHLSL
        }

        //        UsePass "Universal Render Pipeline/Lit/SHADOWCASTER"
        //        UsePass "Universal Render Pipeline/Lit/META"
    }
    FallBack "Custom RP/Lit/CustomLit"
    CustomEditor "JTRP.ShaderDrawer.LWGUI"
}