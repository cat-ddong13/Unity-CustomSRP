namespace Rendering.CustomSRP.Runtime
{
    internal enum CameraRenderPass
    {
        Base,
        Depth
    }

    internal enum PostFXPasses
    {
        // 拷贝
        Copy,

        // 水平采样
        BloomHorizontal,

        // 垂直采样
        BloomVertical,

        // 累加模式
        BloomAdditive,

        // 散射模式
        BloomScatter,

        // 预滤波        
        BloomPrefilter,

        // 预滤波-淡出光斑
        BloomPrefileterFireflies,

        // 用于补偿scatter模式下丢失的散射光
        BloomScatterFinal,

        // ACES色调映射
        ColorGradeNone,
        ColorGradeACES,
        ColorGradeNeutral,
        ColorGradeReinhard,

        // 色调调整结束
        ApplyColorGrade,

        // 将色彩映射结果的a通道存储luma亮度值
        ApplyColorGradeWithLuma,

        // 重新调整渲染比例
        RescaleFinal,

        // FXAA
        FXAA,
        FXAAWithLuma,
    }
}