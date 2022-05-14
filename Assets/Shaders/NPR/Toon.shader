Shader "Custom RP/Toon/Toon"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white"{}
        [HDR]_BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        //# ========================================================
        [TCP2HeaderToggle]_UserOutlines("Use Outlines",Float) = 0
        //=# IF_PROPERTY _UserOutlines > 0
        _Outline("Outline Width",Range(0,1)) = 0.05
        _OutlineColor("Outline Color",Color) = (1.0,1.0,1.0,1.0)
        //# END_IF
    }
    SubShader
    {
        Tags
        {
            "LightMode" = "CustomLit"
        }
        HLSLINCLUDE
        #include "Assets/Custom RP/ShaderLibrary/Common.hlsl"
        ENDHLSL
        UsePass "Custom RP/Toon/Outlines/OUTLINES TEST"
        Pass
        {
            Cull Back
            HLSLPROGRAM
            #include "Assets/Custom RP/Shaders/LitInput.hlsl"
            #include "ToonPasses.hlsl"
            #define shader_feature _ _USE
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            ENDHLSL
        }
        UsePass "Custom RP/Lit/CUSTOM SHADOWCASTER"
        UsePass "Custom RP/Lit/CUSTOM META"
    }
    FallBack "Custom RP/Lit/CustomLit"
    CustomEditor "ToonyColorsPro.ShaderGenerator.MaterialInspector_Hybrid"
}