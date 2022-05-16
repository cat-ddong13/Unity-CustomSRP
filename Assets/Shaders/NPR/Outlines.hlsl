#ifndef OUTLINES_INCLUDE
#define OUTLINES_INCLUDE

struct Attributes
{
    float3 positionOS:POSITION;

    #if defined(_OUTLINE_TANGENT_AS_NORMAL)
    float4 normalOS:TANGENT;
    #else
    float3 normalOS:NORMAL;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS:SV_POSITION;
    float3 positionWS:VAR_POSITION;
    float3 normalWS:VAR_NORMAL;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

UNITY_DEFINE_INSTANCED_PROP(float, _OutlineWidth)
UNITY_DEFINE_INSTANCED_PROP(float4, _OutlineColor)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

// 顶点沿法线扩张
void ShellMethodsVertexPass(Attributes input, out Varyings output)
{
    output = (Varyings)0;
    float3 positionOS = input.positionOS + input.normalOS * _OutlineWidth * 0.05;
    output.positionCS = TransformObjectToHClip(positionOS);
}

// 向前移动Z值
void ZBiasVertexPass(Attributes input, out Varyings output)
{
    output = (Varyings)0;

    float3 worldPos = TransformObjectToWorld(input.positionOS);
    float3 viewPos = TransformWorldToView(worldPos);
    viewPos.z += _OutlineWidth * 0.1;
    output.positionCS = TransformWViewToHClip(viewPos);
}

// 裁剪空间中，将顶点沿法线方向在xy平面上偏移
void VertexNormalVertexPass(Attributes input, out Varyings output)
{
    output = (Varyings)0;

    float4 positionCS = TransformObjectToHClip(input.positionOS);
    float3 normalCS = mul((float3x3)UNITY_MATRIX_VP, mul((float3x3)UNITY_MATRIX_M, input.normalOS));
    float2 offset = normalize(normalCS.xy) * _OutlineWidth;

    // 固定宽度
    #if defined(_OUTLINE_ZOOM_FIXED_WIDTH)
    offset *= positionCS.w;
    #endif

    // 使用zw-1代替xy省了除法操作   offset/_ScreenParams.xy => offset * (_ScreenParams.zw - 1)
    // 后边的乘以10或者0.1只是为了面板上调节比较平缓
    #if defined(_OUTLINE_INCLUDE_ASPECT_RATIO)
    offset = offset * (_ScreenParams.zw - 1) * 2 * 10;
    #else
    offset *= 0.1;
    #endif
    
    positionCS.xy += offset;

    output.positionCS = positionCS;
}

void GetVertexOutput(Attributes input, out Varyings output)
{
    #if defined(_OUTLINE_Z_BIAS)
    ZBiasVertexPass(input,output);
    #elif defined(_OUTLINE_VERTEX_NORMAL)
    VertexNormalVertexPass(input,output);
    #else
    ShellMethodsVertexPass(input, output);
    #endif
}

Varyings OutlinesVertexPass(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input)
    UNITY_TRANSFER_INSTANCE_ID(input, output)

    #if defined(_ENABLE_OUTLINES)
    GetVertexOutput(input, output);
    #endif

    return output;
}

float4 OutlinesFragmentPass(Varyings input):SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    #if defined(_ENABLE_OUTLINES)

    return _OutlineColor;
    #endif

    return float4(1, 1, 1, 1);
}

#endif
