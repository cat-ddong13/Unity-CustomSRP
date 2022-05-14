#ifndef OUTLINES_INCLUDE
#define OUTLINES_INCLUDE

struct Attributes
{
    float4 positionOS:POSITION;
    float3 normalOS:NORMAL;
    float4 normalOS_Tangent:TANGENT;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varings
{
    float4 positionCS:SV_POSITION;
    float3 positionWS:VAR_POSITION;
    float3 normalWS:VAR_NORMAL;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

UNITY_DEFINE_INSTANCED_PROP(float, _Outline)
UNITY_DEFINE_INSTANCED_PROP(float4, _OutlineColor)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

Varings DefaultVertexPass(Attributes input)
{
    Varings output;
    UNITY_SETUP_INSTANCE_ID(input)
    UNITY_TRANSFER_INSTANCE_ID(input, output)
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.positionWS = TransformObjectToWorld(input.positionOS);

    return output;
}

Varings ShellMethodsVertexPass(Attributes input)
{
    Varings output;
    UNITY_SETUP_INSTANCE_ID(input)
    UNITY_TRANSFER_INSTANCE_ID(input, output)

    float3 positionOS = input.positionOS + input.normalOS * _Outline * 0.01;
    output.positionCS = TransformObjectToHClip(positionOS);
    return output;
}

Varings ZBiasVertexPass(Attributes input)
{
    Varings output;
    UNITY_SETUP_INSTANCE_ID(input)
    UNITY_TRANSFER_INSTANCE_ID(input, output)

    float3 worldPos = TransformObjectToWorld(input.positionOS);
    float3 viewPos = TransformWorldToView(worldPos);
    viewPos.z += _Outline;
    output.positionCS = TransformWViewToHClip(viewPos);
    return output;
}

Varings VertexNormal1VertexPass(Attributes input)
{
    Varings output;
    UNITY_SETUP_INSTANCE_ID(input)
    UNITY_TRANSFER_INSTANCE_ID(input, output)

    // float3 positionWS = TransformObjectToWorld(input.positionOS);
    float3 normalVS = TransformObject2ViewNormal(input.normalOS_Tangent);
    float2 offset = TransformView2HClip(normalVS.xy);
    float4 positionCS = TransformObjectToHClip(input.positionOS);
    positionCS.xy += offset * positionCS.z * _Outline;

    output.positionCS = positionCS;

    return output;
}

Varings VertexNormal2VertexPass(Attributes input)
{
    Varings output;
    UNITY_SETUP_INSTANCE_ID(input)
    UNITY_TRANSFER_INSTANCE_ID(input, output)

    float3 positionVS = TransformObject2ViewPos(input.positionOS);
    float3 normalVS = TransformObject2ViewNormal(input.normalOS, false);
    normalVS.z = -1;
    // 
    positionVS += normalize(normalVS) * _Outline;
    // 
    float4 positionCS = TransformWViewToHClip(positionVS);
    // 
    output.positionCS = positionCS;

    return output;
}

Varings SmoothVertexNormalVertexPass(Attributes input)
{
    Varings output;
    UNITY_SETUP_INSTANCE_ID(input)
    UNITY_TRANSFER_INSTANCE_ID(input, output)

    float3 positionOS = input.positionOS + input.normalOS_Tangent.xyz * _Outline * 0.01;
    output.positionCS = TransformObjectToHClip(positionOS);

    return output;
}

float4 DefaultFragmentPass(Varings input):SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);

    return float4(_OutlineColor);
}

#endif
