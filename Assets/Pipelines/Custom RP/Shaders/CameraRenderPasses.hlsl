#ifndef CUSTOM_CAMERA_RENDER_PASSES_INCLUDE
#define CUSTOM_CAMERA_RENDER_PASSES_INCLUDE

TEXTURE2D(_SourceTexture);

struct Varyings
{
    float4 positionCS:SV_POSITION;
    float2 screenUV:VAR_SCREEN_UV;
};

Varyings DefaultPassVertex(uint vertexID :SV_VertexID)
{
    // 沿着范围[-1,1]的正方形裁剪空间坐标系的两边将之扩充两个单位为（-1,3,3）的三角形
    // 1:三角形数2->1，顶点数6->3
    // 2:消除了两个三角形重叠（对角线）区域的多次计算
    // 3:绘制一个三角形可以获得更好的本地缓存一致性
    Varyings output;
    output.positionCS = float4(vertexID <= 1 ? -1.0 : 3.0, vertexID == 1 ? 3.0 : -1.0, .0, 1.0);
    output.screenUV = float2(vertexID <= 1 ? .0 : 2.0, vertexID == 1 ? 2.0 : .0);
    if (_ProjectionParams.x < .0)
    {
        output.screenUV.y = 1 - output.screenUV.y;
    }
    return output;
}

float4 CopyPassFragment(Varyings input):SV_TARGET
{
    // SAMPLE_TEXTURE2D_LOD代替SAMPLE_TEXTURE2D，避免最终调用到mip相关的采样函数
    return SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_linear_clamp, input.screenUV, 0);
}

float CopyDepthFragment(Varyings input):SV_DEPTH
{
    return SAMPLE_DEPTH_TEXTURE_LOD(_SourceTexture, sampler_point_clamp, input.screenUV, 0);
}

#endif
