#ifndef CUSTOM_FRAGMENT_INCLUDED
#define CUSTOM_FRAGMENT_INCLUDED

// 颜色缓冲纹理
TEXTURE2D(_CameraColorTexture);
// 深度缓冲纹理
TEXTURE2D(_CameraDepthTexture);
// 适应渲染比例的缓冲区大小
float4 _CameraBufferSize;

struct Fragment
{
    // screen-space
    float2 positionSS;
    float2 screenUV;
    // 深度(linear-screen-space)
    float depth;
    // 深度缓冲(linear-screen-space)
    float bufferDepth;
};

float GetBufferDepth(float2 screenUV)
{
    float bufferDepth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_linear_clamp, screenUV, 0);
    bufferDepth = IsOrthographicCamera()
                        ? DepthBufferOrthographic2Linear(bufferDepth)
                        : LinearEyeDepth(bufferDepth, _ZBufferParams);
    return bufferDepth;
}

Fragment GetFragment(float4 positionCS)
{
    Fragment f;
    f.positionSS = positionCS.xy;
    f.screenUV = f.positionSS * _CameraBufferSize.xy;
    f.depth = IsOrthographicCamera() ? DepthBufferOrthographic2Linear(positionCS.w) : positionCS.w;
    f.bufferDepth = GetBufferDepth(f.screenUV);
    return f;
}

float4 GetBufferColor(Fragment fragment, float2 uvOffset = float2(.0, .0))
{
    float2 uv = fragment.screenUV + uvOffset;
    return SAMPLE_TEXTURE2D_LOD(_CameraColorTexture, sampler_linear_clamp, uv, 0);
}

#endif
