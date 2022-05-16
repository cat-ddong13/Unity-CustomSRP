#ifndef CUSTOM_FXAA_PASS_INCLUDE
#define CUSTOM_FXAA_PASS_INCLUDE

// fxaa 采样质量
#if defined(FXAA_QUALITY_LOW)
    // 采样步长
    #define EXTRA_EDGE_STEPS 3
    // 步长尺寸
    #define EDGE_STEP_SIZES 1.5,2.0,2.0
    // 没有找到端点时的猜测步长补偿
    #define LAST_EDGE_STEP_GUESS 8.0
#elif defined(FXAA_QUALITY_MEDIUM)
    #define EXTRA_EDGE_STEPS 8
    #define EDGE_STEP_SIZES 1.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0
    #define LAST_EDGE_STEP_GUESS 8.0
#else
#define EXTRA_EDGE_STEPS 10
#define EDGE_STEP_SIZES 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0
#define LAST_EDGE_STEP_GUESS 8.0
#endif

// x:阈值 y:相对阈值 z:亚像素混合强度
float4 _FXAAConfig;

static const float edgeStepSizes[EXTRA_EDGE_STEPS] = {EDGE_STEP_SIZES};

// 目标像素的临近像素
struct LumaNeighborhood
{
    // 目标像素
    float m;

    // 北东南西
    float n, e, s, w;
    // 角
    float ne, es, sw, wn;
    // 最高最低亮度值
    float highest, lowest;
    // 亮度范围
    float range;
};

struct FXAAEdge
{
    // true:水平 false:垂直
    bool direction;
    // 像素偏移
    float pixelStep;
    // 亮度梯度
    float lumaGradient;
    // 其他亮度
    float otherLuma;
};

// 获取亮度，因为人眼对绿色通道更敏感，为了减少运算，直接获取g通道即可
float GetLuma(float2 uv, float2 uvOffset = .0)
{
    uv = uv + uvOffset * GetSourceTexelSize().xy;
    #if defined(_FXAA_WITH_LUMA_IN_ALPHA)
    return GetSource(uv).a;
    #else
    return GetSource(uv).g;
    #endif
}

// 获取目标UV和临近UV的亮度值
LumaNeighborhood GetLumaNeighborhood(float2 uv)
{
    LumaNeighborhood luma;
    luma.m = GetLuma(uv);
    luma.n = GetLuma(uv, float2(.0, 1.0));
    luma.e = GetLuma(uv, float2(1.0, .0));
    luma.s = GetLuma(uv, float2(.0, -1.0));
    luma.w = GetLuma(uv, float2(-1.0, .0));

    luma.ne = GetLuma(uv, float2(1.0, 1.0));
    luma.es = GetLuma(uv, float2(1.0, -1.0));
    luma.sw = GetLuma(uv, float2(-1.0, -1.0));
    luma.wn = GetLuma(uv, float2(-1.0, 1.0));

    // 最高亮度
    luma.highest = Max3(luma.m, luma.n, Max3(luma.e, luma.s, luma.w));
    // 最低亮度
    luma.lowest = Min3(luma.m, luma.n, Min3(luma.e, luma.s, luma.w));
    // 亮度范围
    luma.range = luma.highest - luma.lowest;
    return luma;
}

// 确定亚像素混合因子
float GetSubpixelBlendFactor(LumaNeighborhood luma)
{
    float filter = (luma.n + luma.e + luma.s + luma.w) * 2.0;
    filter += luma.ne + luma.es + luma.sw + luma.wn;

    filter *= 1.0 / 12.0;
    filter = abs(filter - luma.m);
    filter = saturate(filter / luma.range);
    filter = smoothstep(0, 1, filter);

    return filter * filter * _FXAAConfig.z;
}

bool SkipFXAA(LumaNeighborhood luma)
{
    return luma.range < max(_FXAAConfig.x, _FXAAConfig.y * luma.highest);
}

// true:水平 false:垂直
bool EdgeDirection(LumaNeighborhood luma)
{
    float horizontal =
        abs(luma.n + luma.s - luma.m * 2.0) * 2.0 +
        abs(luma.ne + luma.es - luma.e * 2.0) +
        abs(luma.wn + luma.sw - luma.w * 2.0);

    float vertical =
        abs(luma.e + luma.w - luma.m * 2.0) * 2.0 +
        abs(luma.ne + luma.wn - luma.n * 2.0) +
        abs(luma.es + luma.sw - luma.s * 2.0);

    return horizontal >= vertical;
}

FXAAEdge GetEdge(LumaNeighborhood luma)
{
    FXAAEdge edge;
    edge.direction = EdgeDirection(luma);
    float lumaPositive, lumaNegative;
    if (edge.direction)
    {
        edge.pixelStep = GetSourceTexelSize().y;
        lumaPositive = luma.n;
        lumaNegative = luma.s;
    }
    else
    {
        edge.pixelStep = GetSourceTexelSize().x;
        lumaPositive = luma.e;
        lumaNegative = luma.w;
    }

    // 确定亮度的梯度方向
    float gradientPostive = abs(lumaPositive - luma.m);
    float gradientNegative = abs(lumaNegative - luma.m);
    if (gradientPostive < gradientNegative)
    {
        edge.pixelStep = -edge.pixelStep;
        // 亮度梯度值
        edge.lumaGradient = gradientNegative;
        // 另一侧的亮度
        edge.otherLuma = lumaNegative;
    }
    else
    {
        edge.lumaGradient = gradientPostive;
        edge.otherLuma = lumaPositive;
    }

    return edge;
}

// 计算边缘混合因子
float GetEdgeBlendFactor(LumaNeighborhood luma, FXAAEdge edge, float2 uv)
{
    float2 edgeUV = uv;
    float2 uvStep = .0;
    if (edge.direction)
    {
        // 边缘UV坐标
        edgeUV.y += edge.pixelStep * 0.5;
        uvStep.x = GetSourceTexelSize().x;
    }
    else
    {
        edgeUV.x += edge.pixelStep * 0.5;
        uvStep.y = GetSourceTexelSize().y;
    }

    // 在目标像素的亮度及亮度梯度更大的方向的像素的亮度中间取一个平均值，用于确定边缘亮度
    float edgeLuma = (luma.m + edge.otherLuma) * 0.5;
    // 边缘梯度阈值
    float gradientThreshold = edge.lumaGradient * 0.25;

    // 正方向上的UV偏移
    float2 uvPositive = edgeUV + uvStep;
    // 正方向的亮度增量
    float lumaDeltaPositive = GetLuma(uvPositive) - edgeLuma;
    // 正方向上的边缘端点
    bool atEndPositive = abs(lumaDeltaPositive) >= gradientThreshold;

    for (int i = 0; i < EXTRA_EDGE_STEPS && !atEndPositive; i++)
    {
        uvPositive += uvStep * edgeStepSizes[i];
        lumaDeltaPositive = GetLuma(uvPositive) - edgeLuma;
        atEndPositive = abs(lumaDeltaPositive) >= gradientThreshold;
    }

    if (!atEndPositive)
    {
        uvPositive += uvStep * LAST_EDGE_STEP_GUESS;
    }

    // 反方向上的uv偏移
    float2 uvNegative = edgeUV - uvStep;
    // 反方向上的亮度增量
    float lumaDeltaNegative = GetLuma(uvNegative) - edgeLuma;
    // 反方向上的端点
    bool atEndNegative = abs(lumaDeltaNegative) >= gradientThreshold;

    for (int j = 0; j < EXTRA_EDGE_STEPS && !atEndNegative; j++)
    {
        uvNegative -= uvStep * edgeStepSizes[j];
        lumaDeltaNegative = GetLuma(uvNegative) - edgeLuma;
        atEndNegative = abs(lumaDeltaNegative) >= gradientThreshold;
    }

    if (!atEndNegative)
    {
        uvNegative -= uvStep * EXTRA_EDGE_STEPS;
    }

    // 目标到正、反方向的端点距离
    float distance2EndPositive, distance2EndNegative;
    if (edge.direction)
    {
        distance2EndPositive = uvPositive.x - uv.x;
        distance2EndNegative = uv.x - uvNegative.x;
    }
    else
    {
        distance2EndPositive = uvPositive.y - uv.y;
        distance2EndNegative = uv.y - uvNegative.y;
    }

    // 目标到最近的端点距离
    float distance2NearestEnd;
    // 增量符号
    bool deltaSign;
    // 判断最近的方向以及增量符号的正负
    if (distance2EndPositive <= distance2EndNegative)
    {
        distance2NearestEnd = distance2EndPositive;
        deltaSign = lumaDeltaPositive >= 0;
    }
    else
    {
        distance2NearestEnd = distance2EndNegative;
        deltaSign = lumaDeltaNegative >= 0;
    }

    bool originalEdgeSign = luma.m - edgeLuma >= 0;
    if (deltaSign == originalEdgeSign)
    {
        return .0;
    }

    return 0.5 - distance2NearestEnd / (distance2EndPositive + distance2EndNegative);
}

float4 FXAAPassFragment(Varyings input):SV_TARGET
{
    LumaNeighborhood luma = GetLumaNeighborhood(input.screenUV);
    if (SkipFXAA(luma))
        return GetSource(input.screenUV);

    FXAAEdge edge = GetEdge(luma);

    float blendFactor = max(GetSubpixelBlendFactor(luma), GetEdgeBlendFactor(luma, edge, input.screenUV));
    float2 blendUV = input.screenUV;
    if (edge.direction)
    {
        blendUV.y += blendFactor * edge.pixelStep;
    }
    else
    {
        blendUV.x += blendFactor * edge.pixelStep;
    }

    return GetSource(blendUV);
}



#endif
