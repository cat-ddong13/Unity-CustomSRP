#ifndef UNIVERSAL_UNLIT_META_PASS_INCLUDED
#define UNIVERSAL_UNLIT_META_PASS_INCLUDED

#include "Assets/Pipelines/URP/ShaderLibrary/UniversalMetaPass.hlsl"

half4 UniversalFragmentMetaUnlit(Varyings input) : SV_Target
{
    MetaInput metaInput = (MetaInput)0;
    metaInput.Albedo = _BaseColor.rgb * SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb;

    return UniversalFragmentMeta(input, metaInput);
}
#endif
