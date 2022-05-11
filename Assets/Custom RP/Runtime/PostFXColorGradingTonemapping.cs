using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    using ToneMappingSettings = PostFXSettings.ToneMappingSettings;
    using ColorLUTResolution = PostFXSettings.ColorLUTResolution;
    using WhiteBalanceSettings = PostFXSettings.WhiteBalanceSettings;
    using ColorAdjustmentsSettings = PostFXSettings.ColorAdjustmentsSettings;
    using SplitToningSettings = PostFXSettings.SplitToningSettings;
    using ChannelMixerSettings = PostFXSettings.ChannelMixerSettings;
    using ShadowsMidtonesHighlightsSettings = PostFXSettings.ShadowsMidtonesHighlightsSettings;
    
    internal class PostFXColorGradingTonemapping
    {
        private CommandBuffer buffer;
        private Material material;
        private Vector2Int bufferSize;
        private Camera camera;
        private bool useHDR;

        internal void Setup(Camera camera, CommandBuffer buffer, Vector2Int bufferSize, Material material)
        {
            this.camera = camera;
            this.buffer = buffer;
            this.material = material;
            this.bufferSize = bufferSize;
        }

        /// <summary>
        /// 执行颜色分级和色调映射
        /// </summary>
        /// <param name="sourceId"></param>
        internal void Render(int src, bool useTemp, bool keepAlpha, ref ColorLUTResolution colorLutResolution,
            ref ToneMappingSettings toneMappingSettings,
            ref WhiteBalanceSettings whiteBalanceSettings, ref ColorAdjustmentsSettings colorAdjustmentsSettings,
            ref SplitToningSettings splitToningSettings,
            ref ChannelMixerSettings channelMixerSettings,
            ref ShadowsMidtonesHighlightsSettings shadowsMidtonesHighlightsSettings)
        {
            // 配置色彩调整
            ConfigureColorAdjustments(ref colorAdjustmentsSettings);
            // 配置白平衡
            ConfigureWhiteBalance(ref whiteBalanceSettings);
            // 配置色调分离
            ConfigureSplitToning(ref splitToningSettings);
            // 配置通道混合
            ConfigureChannelMixer(ref channelMixerSettings);
            // 配置阴影到高光的过度
            ConfigureSMH(ref shadowsMidtonesHighlightsSettings);

            // LUT是一个3D纹理，size = r * r * r
            // 将其平铺为2D，即高为r，宽为r * r
            var lutResolution = (int) colorLutResolution;
            var lutHeight = lutResolution;
            var lutWidth = lutHeight * lutHeight;
            buffer.GetTemporaryRT(PostFXPropertyIDs.colorGradeLUTId, lutWidth, lutHeight, 0, FilterMode.Bilinear,
                useHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);

            // Color.hlsl.GetLutStripValue()获取LUT需要的参数
            buffer.SetGlobalVector(PostFXPropertyIDs.colorGradeLUTParametersId,
                new Vector4(lutHeight, 0.5f / lutWidth, 0.5f / lutHeight, lutHeight / (lutHeight - 1f)));

            var mode = toneMappingSettings.TMMode;
            var pass = PostFXPasses.ColorGradeNone + (int) mode;
            buffer.SetGlobalFloat(PostFXPropertyIDs.colorGradeLUTInLogCId,
                useHDR && pass != PostFXPasses.ColorGradeNone ? 1f : 0f);
            Draw(src, PostFXPropertyIDs.colorGradeLUTId, pass);
            buffer.ReleaseTemporaryRT(PostFXPropertyIDs.colorGradeLUTId);

            // LUT采样并合并原图像
            // LUT采样解释为2D图需要用到的参数
            buffer.SetGlobalVector(PostFXPropertyIDs.colorGradeLUTParametersId,
                new Vector4(1f / lutWidth, 1f / lutHeight, lutHeight - 1, 0f));

            buffer.SetGlobalFloat(PostFXPropertyIDs.finalSrcBlendId, 1f);
            buffer.SetGlobalFloat(PostFXPropertyIDs.finalDstBlendId, 0f);

            // 如果开启了fxaa，先将色调映射的最终图像存储下来
            if (useTemp)
            {
                buffer.GetTemporaryRT(PostFXPropertyIDs.colorGradeResultId, bufferSize.x, bufferSize.y, 0,
                    FilterMode.Bilinear,
                    useHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);

                Draw(src, PostFXPropertyIDs.colorGradeResultId,
                    keepAlpha ? PostFXPasses.ApplyColorGrade : PostFXPasses.ApplyColorGradeWithLuma);
            }
        }

        /// <summary>
        /// 配置色彩调整
        /// </summary>
        private void ConfigureColorAdjustments(ref ColorAdjustmentsSettings colorAdjustmentsSettings)
        {
            // x:曝光度，2的n次方
            // y:对比度，0-2
            // z:色相偏移，-0.5-0.5
            // w:饱和度，0-2
            buffer.SetGlobalVector(PostFXPropertyIDs.colorAdjustmentsId, new Vector4(
                Mathf.Pow(2, colorAdjustmentsSettings.PostExposure),
                colorAdjustmentsSettings.Contrast * 0.01f + 1,
                colorAdjustmentsSettings.HueShift * (1f / 360f),
                colorAdjustmentsSettings.Saturation * 0.01f + 1
            ));
            buffer.SetGlobalColor(PostFXPropertyIDs.colorFilterId, colorAdjustmentsSettings.ColorFilter);
        }

        /// <summary>
        /// 调整色温
        /// </summary>
        private void ConfigureWhiteBalance(ref WhiteBalanceSettings whiteBalanceSettings)
        {
            buffer.SetGlobalVector(PostFXPropertyIDs.whiteBalanceId,
                ColorUtils.ColorBalanceToLMSCoeffs(whiteBalanceSettings.Temperature, whiteBalanceSettings.Tint)
            );
        }

        /// <summary>
        /// 配置色调分离
        /// </summary>
        private void ConfigureSplitToning(ref SplitToningSettings splitToningSettings)
        {
            var shadows = splitToningSettings.Shadows;
            shadows.a = splitToningSettings.Balance * 0.01f;
            buffer.SetGlobalVector(PostFXPropertyIDs.splitToningShadowsId, shadows);
            buffer.SetGlobalVector(PostFXPropertyIDs.splitToningHighlightsId, splitToningSettings.HighLights);
        }

        /// <summary>
        /// 配置通道混合
        /// </summary>
        private void ConfigureChannelMixer(ref ChannelMixerSettings channelMixerSettings)
        {
            buffer.SetGlobalVector(PostFXPropertyIDs.channelMixerRedId, channelMixerSettings.R);
            buffer.SetGlobalVector(PostFXPropertyIDs.channelMixerGreenId, channelMixerSettings.G);
            buffer.SetGlobalVector(PostFXPropertyIDs.channelMixerBlueId, channelMixerSettings.B);
        }

        /// <summary>
        /// 配置阴影-中间-高光区域之间的过渡
        /// </summary>
        private void ConfigureSMH(ref ShadowsMidtonesHighlightsSettings shadowsMidtonesHighlightsSettings)
        {
            buffer.SetGlobalVector(PostFXPropertyIDs.smhShadowsId, shadowsMidtonesHighlightsSettings.Shadows.linear);
            buffer.SetGlobalVector(PostFXPropertyIDs.smhMidtonesId, shadowsMidtonesHighlightsSettings.Midtones.linear);
            buffer.SetGlobalVector(PostFXPropertyIDs.smhHighlightsId,
                shadowsMidtonesHighlightsSettings.Highlights.linear);
            buffer.SetGlobalVector(PostFXPropertyIDs.smhRngId,
                new Vector4(shadowsMidtonesHighlightsSettings.ShadowsStart,
                    shadowsMidtonesHighlightsSettings.ShadowsEnd,
                    shadowsMidtonesHighlightsSettings.HighlightsStart,
                    shadowsMidtonesHighlightsSettings.HighlightsEnd));
        }

        private void Draw(RenderTargetIdentifier from, RenderTargetIdentifier to, PostFXPasses pass)
        {
            buffer.SetGlobalTexture(PostFXPropertyIDs.fxSourceId, from);
            buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            buffer.DrawProcedural(Matrix4x4.identity, material, (int) pass, MeshTopology.Triangles, 3);
        }
    }
}