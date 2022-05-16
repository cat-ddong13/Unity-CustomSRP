using UnityEngine;

namespace Rendering.CustomSRP.Runtime
{
    internal static class CameraPropertyIDs
    {
        // 分离颜色缓冲与深度缓冲
        internal static readonly int colorAttachmentId = Shader.PropertyToID("_CameraColorAttachment");
        internal static readonly int depthAttachmentId = Shader.PropertyToID("_CameraDepthAttachment");
        internal static readonly int colorTextureId = Shader.PropertyToID("_CameraColorTexture");
        internal static readonly int depthTextureId = Shader.PropertyToID("_CameraDepthTexture");
        internal static readonly int sourceTextureId = Shader.PropertyToID("_SourceTexture");
        internal static readonly int srcBlendId = Shader.PropertyToID("_CameraSrcBlend");
        internal static readonly int dstBlendId = Shader.PropertyToID("_CameraDstBlend");
        internal static readonly int cameraBufferSizeId = Shader.PropertyToID("_CameraBufferSize");
    }

    internal static class LightingPropertyIDs
    {
        // 平行光数量标签
        internal static readonly int directionalLightCountId = Shader.PropertyToID("_DirectionalLightCount");

        // 平行光颜色标签
        internal static readonly int directionalLightColorsId = Shader.PropertyToID("_DirectionalLightColors");

        // 平行光方向及渲染层级掩码标签
        internal static readonly int directionalLightDirectionsAndMasksId =
            Shader.PropertyToID("_DirectionalLightDirectionsAndMasks");

        // 平行光阴影数据标签
        internal static readonly int directionalLightShadowDataId = Shader.PropertyToID("_DirectionalLightShadowDatas");

        // 非平行光(点光源、聚光灯)数量限制标签
        internal static readonly int otherLightCountId = Shader.PropertyToID("_OtherLightCount");

        // 非平行光颜色标签
        internal static readonly int otherLightColorsId = Shader.PropertyToID("_OtherLightColors");

        // 非平行光位置标签
        internal static readonly int otherLightPositionsId = Shader.PropertyToID("_OtherLightPositions");

        // 非平行光方向及渲染层级掩码标签
        internal static readonly int otherLightDirectionsAndMasksId =
            Shader.PropertyToID("_OtherLightDirectionsAndMasks");

        // 非平行光角度标签
        internal static readonly int otherLightSpotsConeId = Shader.PropertyToID("_OtherLightSpotsCone");

        // 非平行光阴影数据标签
        internal static readonly int otherLightShadowDataId = Shader.PropertyToID("_OtherLightShadowDatas");
    }

    internal static class ShadowsPropertyIDs
    {
        // 平行光阴影图集标签
        internal static readonly int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");

        // 平行光阴影纹理大小标签
        internal static readonly int shadowsAtlasSizeId = Shader.PropertyToID("_ShadowAtlasSize");

        // 平行光阴影图集矩阵标签
        internal static readonly int dirShadowMatricesId = Shader.PropertyToID("_DirectionalShadowMatrices");

        // 非平行光阴影图集标签
        internal static readonly int otherShadowAtlasId = Shader.PropertyToID("_OtherShadowAtlas");

        // 非平行光阴影图集矩阵标签
        internal static readonly int otherShadowAtlasMatricesId = Shader.PropertyToID("_OtherShadowMatrices");

        // 非平行光阴影瓦片索引标签
        internal static readonly int otherShadowTilesId = Shader.PropertyToID("_OtherShadowTiles");

        // 阴影级联数标签
        internal static readonly int cascadeCountId = Shader.PropertyToID("_CascadeCount");

        // 阴影裁剪球体标签
        internal static readonly int cascadeCullingSphereId = Shader.PropertyToID("_CascadeCullingSpheres");

        // 阴影级联数据标签
        internal static readonly int cascadeDataId = Shader.PropertyToID("_CascadeData");

        // 阴影距离过度标签
        internal static readonly int shadowDistanceFadeId = Shader.PropertyToID("_ShadowDistanceFade");

        // 阴影平坠标签
        internal static readonly int shadowPancakingId = Shader.PropertyToID("_ShadowPancaking");
    }

    internal static class PostFXPropertyIDs
    {
        // 纹理1
        internal static readonly int fxSourceId = Shader.PropertyToID("_PostFXSource");

        // 纹理2
        internal static readonly int fxSourceId2 = Shader.PropertyToID("_PostFXSource2");

        // bloom多次上采样
        internal static int bloomBucibicUpsamplingId = Shader.PropertyToID("_BloomBicubicUpsampling");

        // bloom预滤波
        internal static int bloomPrefilterId = Shader.PropertyToID("_BloomPrefilter");

        // bloom阈值
        internal static int bloomShresholdId = Shader.PropertyToID("_BloomThreshold");

        // bloom强度
        internal static int bloomIntensityId = Shader.PropertyToID("_BloomIntensity");

        // bloom结果纹理
        internal static int bloomResultId = Shader.PropertyToID("_BloomResultId");

        // 色彩调整参数ID
        internal static readonly int colorAdjustmentsId = Shader.PropertyToID("_ColorAdjustments");

        // 颜色滤镜ID
        internal static readonly int colorFilterId = Shader.PropertyToID("_ColorFilter");

        // 白平衡ID
        internal static readonly int whiteBalanceId = Shader.PropertyToID("_WhiteBalance");

        // 色调分离阴影ID
        internal static readonly int splitToningShadowsId = Shader.PropertyToID("_SplitToningShadows");

        // 色调分离高光ID
        internal static readonly int splitToningHighlightsId = Shader.PropertyToID("_SplitToningHighlights");

        // 色彩通道融合
        internal static readonly int channelMixerRedId = Shader.PropertyToID("_ChannelMixerRed");
        internal static readonly int channelMixerGreenId = Shader.PropertyToID("_ChannelMixerGreen");
        internal static readonly int channelMixerBlueId = Shader.PropertyToID("_ChannelMixerBlue");

        // 阴影-中间-高光区域之间的过渡
        internal static readonly int smhShadowsId = Shader.PropertyToID("_SMHShadows");
        internal static readonly int smhMidtonesId = Shader.PropertyToID("_SMHMidtones");
        internal static readonly int smhHighlightsId = Shader.PropertyToID("_SMHHighlights");
        internal static readonly int smhRngId = Shader.PropertyToID("_SMHRange");

        // LUT
        internal static readonly int colorGradeLUTId = Shader.PropertyToID("_ColorGradeLUT");
        internal static readonly int colorGradeLUTParametersId = Shader.PropertyToID("_ColorGradeLUTParameters");
        internal static readonly int colorGradeLUTInLogCId = Shader.PropertyToID("_ColorGradeLUTInLogC");

        // 混合模式
        internal static readonly int finalSrcBlendId = Shader.PropertyToID("_FinalSrcBlend");
        internal static readonly int finalDstBlendId = Shader.PropertyToID("_FinalDstBlend");
        internal static readonly int finalResultId = Shader.PropertyToID("_FinalResult");

        internal static readonly int copyBicubicId = Shader.PropertyToID("_CopyBicubic");

        // 色调映射结果纹理
        internal static readonly int colorGradeResultId = Shader.PropertyToID("_ColorGradeResult");

        // fxaa
        internal static readonly int fxaaConfigId = Shader.PropertyToID("_FXAAConfig");

        // postFX outline
        internal static readonly int postOutlineTexId = Shader.PropertyToID("_PostOutlineTex");
        internal static readonly int postOutlineThresholdId = Shader.PropertyToID("_PostOutlineThreshold");
        internal static readonly int postOutlineColorId = Shader.PropertyToID("_PostOutlineColor");
        internal static readonly int postOutlineWidthId = Shader.PropertyToID("_PostOutlineWidth");
        internal static readonly int postOutlineIntensityId = Shader.PropertyToID("_PostOutlineIntensity");
    }
}