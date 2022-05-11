#ifndef CUSTOM_UNLIT_PASS_INCLUDE
#define CUSTOM_UNLIT_PASS_INCLUDE

struct Attributes
{
    float3 positionOS:POSITION;

    #if defined(_VERTEX_COLORS)
    float4 color:COLOR;
    #endif

    #if defined(_FLIPBOOK_BLENDING)
    float4 uv:TEXCOORD0;
    float flipbookBlend:TEXCOORD1;
    #else
    float2 uv:TEXCOORD0;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    // 语义SV_POSITION，
    // 在vertex中为clip space坐标
    // 传递到fragment后，被转换为screen space像素坐标
    // [0, 0] - [width, height]
    // w:用于执行透视除法将3D坐标映射到屏幕上，是片元到相机XY平面的距离，不是近裁剪面
    float4 positionCS_SS:SV_POSITION;
    float2 uv:VAR_UV;

    #if defined(_VERTEX_COLORS)
    float4 color:VAR_COLOR;
    #endif

    #if defined(_FLIPBOOK_BLENDING)
    float3 flipbookUVB:VAR_FLIPBOOK;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings UnlitPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.positionCS_SS = TransformObjectToHClip(input.positionOS);
    output.uv = TransformBaseUV(input.uv.xy);

    #if defined(_FLIPBOOK_BLENDING)
    output.flipbookUVB.xy = TransformBaseUV(input.uv.zw);
    output.flipbookUVB.z = input.flipbookBlend;
    #endif

    #if defined(_VERTEX_COLORS)
    output.color = input.color;
    #endif

    return output;
}

float4 UnlitPassFragment(Varyings input):SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    InputConfig ic = GetInputConfig(input.positionCS_SS, input.uv.xy);

    #if defined(_SOFT_PARTICLES)
    ic.softParticles = true;
    #endif

    #if defined(_NEAR_FADE)
    ic.nearFade = true;
    #endif

    // 是否定义了翻页融合效果
    #if defined(_FLIPBOOK_BLENDING)
    ic.flipbookBlending = true;
    ic.flipbookUVB = input.flipbookUVB;
    #endif

    // 是否定义了顶点颜色
    #if defined(_VERTEX_COLORS)
    ic.color = input.color;
    #endif

    float4 base = GetBase(ic);

    #if defined(_CLIPPING)
    clip(base.a - GetCutoff(ic));
    #endif
    
    #if defined(_DISTORTION)
    float2 distortion = GetDistortion(ic) * base.a;
    base.rgb = lerp(
        GetBufferColor(ic.fragment, distortion).rgb,
        base.rgb,
        saturate(base.a - GetDistortionBlend(ic))
    );
    #endif

    // return float4(ic.fragment.bufferDepth.xxx / 100, 1.0);
    return float4(base.rgb, GetFinalAlpha(base.a));
}

#endif
