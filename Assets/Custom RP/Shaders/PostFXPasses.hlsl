#ifndef CUSTOM_POST_FX_PASSES_INCLUDE
#define CUSTOM_POST_FX_PASSES_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

TEXTURE2D(_PostFXSource);
TEXTURE2D(_PostFXSource2);
TEXTURE2D(_ColorGradeLUT);

struct Varyings
{
    float4 positionCS:SV_POSITION;
    float2 screenUV:VAR_SCREEN_UV;
};

float4 _PostFXSource_TexelSize;

float4 GetSourceTexelSize()
{
    return _PostFXSource_TexelSize;
}

float4 GetSource(float2 screenUV)
{
    // SAMPLE_TEXTURE2D_LOD代替SAMPLE_TEXTURE2D，避免最终调用到mip相关的采样函数
    return SAMPLE_TEXTURE2D_LOD(_PostFXSource, sampler_linear_clamp, screenUV, 0);
}

float4 GetSource2(float2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD(_PostFXSource2, sampler_linear_clamp, screenUV, 0);
}

float4 GetSourceBicubic(float2 screenUV)
{
    return SampleTexture2DBicubic(
        TEXTURE2D_ARGS(_PostFXSource, sampler_linear_clamp), screenUV,
        GetSourceTexelSize().zwxy, 1.0, 0.0
    );
}

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
    return GetSource(input.screenUV);
}

float4 BloomHorizontalPassFragment(Varyings input):SV_TARGET
{
    float3 color = .0;
    float offsets[] = {
        -4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0
    };
    float weights[] = {
        0.01621622, 0.05405405, 0.12162162, 0.19459459, 0.22702703,
        0.19459459, 0.12162162, 0.05405405, 0.01621622
    };

    for (int i = 0; i < 9; i++)
    {
        float offset = offsets[i] * 2.0 * GetSourceTexelSize().x;
        color += GetSource(input.screenUV + float2(offset, .0)).rgb * weights[i];
    }

    return float4(color, 1.0);
}

float4 BloomVerticalPassFragment(Varyings input):SV_TARGET
{
    float3 color = .0;
    float offsets[] = {
        -3.23076923, -1.38461538, 0.0, 1.38461538, 3.23076923
    };
    float weights[] = {
        0.07027027, 0.31621622, 0.22702703, 0.31621622, 0.07027027
    };

    for (int i = 0; i < 5; i++)
    {
        float offset = offsets[i] * GetSourceTexelSize().y;
        color += GetSource(input.screenUV + float2(.0, offset)).rgb * weights[i];
    }

    return float4(color, 1.0);
}

// w = max(s,b - t) / max (b , 0.00001);
// s = square( min(max(0,b-t+tk),2tk) ) / 4tk + 0.0001
// b : brightness(亮度)
// t : threshold(阈值)
// k : knee(拐点形状)
// x : t
// y : -t + tk
// z : 2tk
// w : 1 / 4tk + 0.00001
float4 _BloomThreshold;

float3 ApplyBloomThreshold(float3 color)
{
    float brightness = Max3(color.r, color.g, color.b);

    float soft = brightness + _BloomThreshold.y;
    soft = clamp(soft, .0, _BloomThreshold.z);
    soft = soft * soft * _BloomThreshold.w;

    float contribution = max(soft, brightness - _BloomThreshold.x);
    contribution /= max(brightness, 0.00001);
    return color * contribution;
}

float4 BloomPrefilterPassFragment(Varyings input):SV_TARGET
{
    float3 color = ApplyBloomThreshold(GetSource(input.screenUV).rgb);
    return float4(color, 1.0);
}

// 通过更大范围的采样将bloom扩散到更大的区域范围，防止运动中产生闪烁的亮斑的
float4 BloomPrefilterFirefliesPassFragment(Varyings input):SV_TARGET
{
    float3 color = .0;
    // 采样范围的偏移
    // 2x2 => 6x6
    float2 offsets[] = {
        float2(0.0, 0.0), float2(-1.0, -1.0), float2(-1.0, 1.0), float2(1.0, -1.0), float2(1.0, 1.0)
        // 因为在预滤波pass后会执行高斯模糊pass，可以去掉重叠的部分
        // ,float2(-1.0, 0.0), float2(1.0, 0.0), float2(0.0, -1.0), float2(0.0, 1.0)
    };
    // 权重和
    float weightSum = .0;

    for (int i = 0; i < 5; i++)
    {
        float3 c = GetSource(input.screenUV + offsets[i] * GetSourceTexelSize().xy * 2.0).rgb;
        c = ApplyBloomThreshold(c);
        // 采样的权重公式是 1 / (l + 1)，l = luminance亮度
        float w = 1.0 / (Luminance(c) + 1.0);
        color += c * w;
        weightSum += w;
    }
    color /= weightSum;
    return float4(color, 1.0);
}


bool _BloomBicubicUpsampling;
float _BloomIntensity;

// 通过对低分辨率采样后的结果进行强度设置，与原图像合并
float4 BloomAdditivePassFragment(Varyings input):SV_TARGET
{
    float3 low;
    if (_BloomBicubicUpsampling)
    {
        low = GetSourceBicubic(input.screenUV).rgb;
    }
    else
    {
        low = GetSource(input.screenUV).rgb;
    }

    // 使用原图像的alpha通道参与合并
    float4 high = GetSource2(input.screenUV);
    return float4(low * _BloomIntensity + high.rgb, high.a);
}

// 在低分辨率采样后的结果和原图像中进行插值处理
float4 BloomScatterPassFragment(Varyings input):SV_TARGET
{
    float3 low;
    if (_BloomBicubicUpsampling)
    {
        low = GetSourceBicubic(input.screenUV).rgb;
    }
    else
    {
        low = GetSource(input.screenUV).rgb;
    }

    float3 high = GetSource2(input.screenUV).rgb;
    return float4(lerp(high, low, _BloomIntensity), 1.0);
}

// scatter模式的散射光补偿通道
float4 BloomScatterFinalPassFragment(Varyings input):SV_TARGET
{
    float3 low;
    if (_BloomBicubicUpsampling)
    {
        low = GetSourceBicubic(input.screenUV).rgb;
    }
    else
    {
        low = GetSource(input.screenUV).rgb;
    }

    // 使用原图像的alpha通道参与合并
    float4 high = GetSource2(input.screenUV);
    low = low + high.rgb - ApplyBloomThreshold(high.rgb);
    return float4(lerp(high.rgb, low, _BloomIntensity), high.a);
}


// x:曝光度，2的n次方
// y:对比度，0-2
// z:色相偏移，-0.5-0.5
// w:饱和度，0-2
float4 _ColorAdjustments;

// 滤镜
float4 _ColorFilter;

// 白平衡
float4 _WhiteBalance;

// 色调分离
float4 _SplitToningShadows;
float4 _SplitToningHighlights;

// 通道混合
float4 _ChannelMixerRed;
float4 _ChannelMixerGreen;
float4 _ChannelMixerBlue;

// 阴影-中间-高光区域之间的过渡
float4 _SMHShadows;
float4 _SMHMidtones;
float4 _SMHHighlights;
// x:shadow start y:shadow end z:highlight start w:highlight end
float4 _SMHRange;
// LUT
// when get lut:  x:lutHeight y:0.5f / lutWidth z:0.5f / lutHeight w:lutHeight / (lutHeight - 1f)
// when apply lut: x:1f / lutWidth y:1f / lutHeight z:lutHeight - 1)
float4 _ColorGradeLUTParameters;
bool _ColorGradeLUTInLogC;

float Luminance(float3 color, bool useACES)
{
    return useACES ? AcesLuminance(color) : Luminance(color);
}

// 调整曝光度
float3 ColorGradePostExposure(float3 color)
{
    return color * _ColorAdjustments.x;
}

// 调整白平衡色温色调
float3 ColorGradeWhiteBalance(float3 color)
{
    // LMS人眼视锥细胞感光空间
    color = LinearToLMS(color);
    color *= _WhiteBalance.rgb;
    return LMSToLinear(color);
}

// 调整对比度 c=(c-midgray) * contrast + midgray
// 在logc空间处理对比度，之后再转到linear空间
float3 ColorGradeContrast(float3 color, bool useACES)
{
    color = useACES ? ACES_to_ACEScc(unity_to_ACES(color)) : LinearToLogC(color);
    color = (color - ACEScc_MIDGRAY) * _ColorAdjustments.y + ACEScc_MIDGRAY;
    color = useACES ? ACES_to_ACEScg(ACEScc_to_ACES(color)) : LogCToLinear(color);

    return color;
}

// 滤镜
float3 ColorGradeColorFilter(float3 color)
{
    return color * _ColorFilter.rgb;
}

// 色相偏移
// 从RGB空间到-HSV空间(hue,saturation,value)
// 之后再转回RGB
float3 ColorGradeHueShift(float3 color)
{
    color = RgbToHsv(color);
    float hue = color.x + _ColorAdjustments.z;
    color.x = RotateHue(hue, .0, 1.0);
    return HsvToRgb(color);
}

// 调整饱和度
// 提取颜色和亮度的差，然后合并饱和度后再加上亮度
float3 ColorGradeSaturation(float3 color, bool useACES)
{
    float luminance = Luminance(color, useACES);
    return (color - luminance) * _ColorAdjustments.w + luminance;
}

// 分离阴影和高光的色调调整
// 在gamma空间中计算，最后返回linear
float3 ColorGradeSplitToning(float3 color, bool useACES)
{
    color = LinearToGamma22(color);

    float balance = saturate(Luminance(saturate(color), useACES) + _SplitToningShadows.w);

    float3 shadows = lerp(0.5, _SplitToningShadows.rgb, 1.0 - balance);
    float3 highlights = lerp(0.5, _SplitToningHighlights.rgb, balance);

    color = SoftLight(color, shadows);
    color = SoftLight(color, highlights);

    return Gamma22ToLinear(color);
}

// 通道混合
// 实质是用3x3的RGB矩阵左乘原色，从而混合原色
float3 ColorGradeChannelMixer(float3 color)
{
    return mul(float3x3(_ChannelMixerRed.rgb, _ChannelMixerGreen.rgb, _ChannelMixerBlue.rgb), color);
}

// 阴影-中间-高光区域之间的过度
float3 ColorGradeShadowsMidtonesHighlights(float3 color, bool useACES)
{
    float luminance = Luminance(color, useACES);

    // 阴影权重随着亮度增加从1->0
    float shadowsWeight = 1.0 - smoothstep(_SMHRange.x, _SMHRange.y, luminance);
    // 高光权重随着亮度从0->1
    float highlightsWeight = smoothstep(_SMHRange.z, _SMHRange.w, luminance);
    // 中间区域权重
    float midWeight = 1.0 - shadowsWeight - highlightsWeight;

    color = color * shadowsWeight * _SMHShadows.rgb +
        color * highlightsWeight * _SMHHighlights.rgb +
        color * midWeight * _SMHMidtones.rgb;

    return color;
}

// 色彩分级
float3 ColorGrade(float3 color, bool useACES = false)
{
    // 调整曝光度
    color = ColorGradePostExposure(color);
    // 调整白平衡
    color = ColorGradeWhiteBalance(color);
    // 调整对比度
    color = ColorGradeContrast(color, useACES);
    // 调整滤镜
    color = ColorGradeColorFilter(color);
    color = max(color, .0);
    // 调整色调分离
    color = ColorGradeSplitToning(color, useACES);
    // 通道混合
    color = ColorGradeChannelMixer(color);
    color = max(color, .0);
    // 阴影-中间-高光过渡
    color = ColorGradeShadowsMidtonesHighlights(color, useACES);
    // 调整色相偏移
    color = ColorGradeHueShift(color);
    // 调整饱和度
    color = ColorGradeSaturation(color, useACES);
    color = max(useACES ? ACEScg_to_ACES(color) : color, .0f);
    return color;
}

// 获取LUT
float3 GetColorGradeLUT(float2 uv, bool useACES = false)
{
    // LUT矩阵位于linear空间中，范围仅覆盖0-1，可以将color解释为logc空间扩大范围
    // 又因为logc空间为暗点增加了分辨率范围，在不需要时还是用linear空间，需要时比如用了HDR，再用logc
    float3 color = GetLutStripValue(uv, _ColorGradeLUTParameters);
    color = ColorGrade(_ColorGradeLUTInLogC ? LogCToLinear(color) : color, useACES);
    return color;
}

// 无色彩分级
float3 ColorGradeNonePassFragment(Varyings input):SV_TARGET
{
    float3 color = GetColorGradeLUT(input.screenUV);
    return color;
}

// Reinhard 
// c / 1.0+ c
float4 ColorGradeReinhardPassFragment(Varyings input):SV_TARGET
{
    float3 color = GetColorGradeLUT(input.screenUV);
    // 限制可能出现的极大值，实际上超出一定值以后的曲线增长已经肉眼难辨了，将其限制60以下即可
    color /= (color + 1.0);
    return float4(color, 1.0);
}

// Neutral 
float4 ColorGradeNeutralPassFragment(Varyings input):SV_TARGET
{
    float3 color = GetColorGradeLUT(input.screenUV);
    color = NeutralTonemap(color);
    return float4(color, 1.0);
}

// Neutral 
float4 ColorGradeACESPassFragment(Varyings input):SV_TARGET
{
    float3 color = GetColorGradeLUT(input.screenUV);
    color = AcesTonemap(color.rgb);
    return float4(color, 1.0);
}

// 应用LUT
float3 ApplyColorGradingLUT(float3 color)
{
    return ApplyLut2D(TEXTURE2D_ARGS(_ColorGradeLUT, sampler_linear_clamp),
                      saturate(_ColorGradeLUTInLogC ? LogCToLinear(color) : color),
                      _ColorGradeLUTParameters.xyz);
}

// 颜色分级最后的pass
float4 ApplyColorGradePassFragment(Varyings input):SV_TARGET
{
    float4 color = GetSource(input.screenUV);
    color.rgb = ApplyColorGradingLUT(color.rgb);
    return color;
}

// 颜色分级最后的pass，在开启fxaa的情况下，存储亮度到a通道，供fxaa使用
float4 ApplyColorGradeWithLumaPassFragment(Varyings input):SV_TARGET
{
    float4 color = GetSource(input.screenUV);
    color.rgb = ApplyColorGradingLUT(color.rgb);
    color.a = Luminance(color.rgb);
    return color;
}

// 是否使用双 三次采样 拷贝纹理
bool _CopyBicubic;

float4 FinalPassFragmentRescale(Varyings input):SV_TARGET
{
    if (_CopyBicubic)
    {
        return GetSourceBicubic(input.screenUV);
    }
    else
    {
        return GetSource(input.screenUV);
    }
}

#endif
