#ifndef CUSTOM_SHADOW_CASTER_PASS_INCLUDE
#define CUSTOM_SHADOW_CASTER_PASS_INCLUDE

struct Attributes
{
    float3 positionOS:POSITION;
    float2 uv:TEXCOORD0;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS_SS:SV_POSITION;
    float2 uv:VAR_UV;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

bool _ShadowPancaking;

Varyings ShadowCasterPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS_SS = TransformWorldToHClip(positionWS);

    if (_ShadowPancaking)
    {
        // 是否反转Z
        #if UNITY_REVERSED_Z
        output.positionCS_SS.z = min(output.positionCS_SS.z, output.positionCS_SS.w * UNITY_NEAR_CLIP_VALUE);
        #else
        output.positionCS_SS.z = max(output.positionCS_SS.z,output.positionCS_SS.w * UNITY_NEAR_CLIP_VALUE);
        #endif
    }

    output.uv = TransformBaseUV(input.uv);

    return output;
}

void ShadowCasterPassFragment(Varyings input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    InputConfig ic = GetInputConfig(input.positionCS_SS, input.uv);
    ClipLOD(ic.fragment, unity_LODFade.x);
    float4 base = GetBase(ic);

    // 阴影裁剪/阴影抖动
    #if defined(_SHADOWS_CLIP)
        clip(base.a - GetCutoff(ic));
    #elif defined(_SHADOWS_DITHER)
        float dither = InterleavedGradientNoise(input.positionCS.xy,0);
        clip(base.a - dither);
    #endif
}

#endif
