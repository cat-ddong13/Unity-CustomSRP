using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    using FinalBlendMode = CameraSettings.FinalBlendMode;
    using BicubicRescalingMode = CameraBufferSettings.BicubicRescalingMode;

    internal partial class PostFXRenderer
    {
        private const string BUFFER_NAME = "Post FX";
        private CommandBuffer buffer = new CommandBuffer() {name = BUFFER_NAME};

        private ScriptableRenderContext context = default;
        private Camera camera = null;
        private PostFXSettings settings = default;
        private FinalBlendMode finalBlendMode;

        // 是否激活
        public bool IsActive => null != settings;

        // 缓冲区大小
        private Vector2Int bufferSize;

        // 双三次采样渲染比例模式
        private BicubicRescalingMode bicubicRescalingMode;

        // fxaa
        private CameraBufferSettings.FXAA fxaa;

        // 开启fxaa的时候是否保留alpha通道（多相机堆叠时需要保留透明通道）
        private bool keepAlpha;

        private PostFXBloom postBloom = new PostFXBloom();
        private PostFXOutlines postFXOutlines = new PostFXOutlines();
        private PostFXColorGradingTonemapping postColorGradingToneMapping = new PostFXColorGradingTonemapping();

        internal void Setup(ScriptableRenderContext context, Camera camera, Vector2Int bufferSize, bool useHDR,
            FinalBlendMode finalBlendMode, BicubicRescalingMode bicubicRescalingMode, bool keepAlpha,
            ref PostFXSettings settings, ref CameraBufferSettings.FXAA fxaa
        )
        {
            this.bicubicRescalingMode = bicubicRescalingMode;
            this.context = context;
            this.camera = camera;
            this.settings = camera.cameraType <= CameraType.SceneView ? settings : null;
            this.finalBlendMode = finalBlendMode;
            this.bufferSize = bufferSize;
            this.fxaa = fxaa;
            this.keepAlpha = keepAlpha;

            postFXOutlines.Setup(buffer, bufferSize, settings.Material);
            postBloom.Setup(camera, buffer, bufferSize, settings.Material, useHDR);
            postColorGradingToneMapping.Setup(buffer, bufferSize, settings.Material, useHDR);

            // 忽略不支持后处理的scene窗口
            ApplySceneViewState();
        }

        public void Render(int sourceID)
        {
            var src = sourceID;

          
            postBloom.Render(ref settings.bloom, ref src);
            
            if (settings.postOutlines.enabled)
            {
                postFXOutlines.Render(ref src, ref settings.postOutlines);
            }

            // other post
            // …………
            // …………
            ////////////
            ///
            ///

            // 颜色分级和色调映射
            postColorGradingToneMapping.Render(src, fxaa.enable, keepAlpha, ref settings.colorLUTResolution,
                ref settings.tonemapping, ref settings.whiteBalance, ref settings.colorAdjustments,
                ref settings.splitToning, ref settings.channelMixer, ref settings.shadowsMidtonesHighlights);

            ExecuteFinal(src);

            if (src != sourceID)
            {
                buffer.ReleaseTemporaryRT(src);
            }

            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        private void ExecuteFinal(int sourceId)
        {
            buffer.SetGlobalFloat(PostFXPropertyIDs.finalSrcBlendId, 1f);
            buffer.SetGlobalFloat(PostFXPropertyIDs.finalDstBlendId, 0f);

            // 没有调整渲染比例
            if (bufferSize.x == camera.pixelWidth)
            {
                if (fxaa.enable)
                {
                    DrawFinal(PostFXPropertyIDs.colorGradeResultId,
                        keepAlpha ? PostFXPasses.FXAA : PostFXPasses.FXAAWithLuma);
                    buffer.ReleaseTemporaryRT(PostFXPropertyIDs.colorGradeResultId);
                }
                else
                {
                    DrawFinal(sourceId, PostFXPasses.ApplyColorGrade);
                }
            }
            else
            {
                buffer.GetTemporaryRT(PostFXPropertyIDs.finalResultId, bufferSize.x, bufferSize.y, 0,
                    FilterMode.Bilinear,
                    RenderTextureFormat.Default);

                if (fxaa.enable)
                {
                    Draw(PostFXPropertyIDs.colorGradeResultId, PostFXPropertyIDs.finalResultId,
                        keepAlpha ? PostFXPasses.FXAA : PostFXPasses.FXAAWithLuma);
                    buffer.ReleaseTemporaryRT(PostFXPropertyIDs.colorGradeResultId);
                }
                else
                {
                    Draw(sourceId, PostFXPropertyIDs.finalResultId, PostFXPasses.ApplyColorGrade);
                }

                // 双三次采样
                var bicubicRescaling = bicubicRescalingMode == BicubicRescalingMode.UpscaleOnly ||
                                       bicubicRescalingMode == BicubicRescalingMode.UpAndDown &&
                                       bufferSize.x < camera.pixelWidth;
                buffer.SetGlobalFloat(PostFXPropertyIDs.copyBicubicId, bicubicRescaling ? 1f : 0f);

                DrawFinal(PostFXPropertyIDs.finalResultId, PostFXPasses.RescaleFinal);
                buffer.ReleaseTemporaryRT(PostFXPropertyIDs.finalResultId);
            }
        }

        private void Draw(RenderTargetIdentifier from, RenderTargetIdentifier to, PostFXPasses pass)
        {
            buffer.SetGlobalTexture(PostFXPropertyIDs.fxSourceId, from);
            buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            buffer.DrawProcedural(Matrix4x4.identity, settings.Material, (int) pass, MeshTopology.Triangles, 3);
        }

        /// <summary>
        /// 将最后混合后的图与原图混合
        /// </summary>
        /// <param name="from"></param>
        private void DrawFinal(RenderTargetIdentifier from, PostFXPasses pass)
        {
            // 设置最终混合模式
            buffer.SetGlobalFloat(PostFXPropertyIDs.finalSrcBlendId, (float) finalBlendMode.Src);
            buffer.SetGlobalFloat(PostFXPropertyIDs.finalDstBlendId, (float) finalBlendMode.Dst);

            buffer.SetGlobalTexture(PostFXPropertyIDs.fxSourceId, from);
            buffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget, RenderBufferLoadAction.Load,
                RenderBufferStoreAction.Store);
            // 设置多相机模式下的视口
            buffer.SetViewport(camera.pixelRect);
            buffer.DrawProcedural(Matrix4x4.identity, settings.Material, (int) pass,
                MeshTopology.Triangles, 3);
        }

        internal void Cleanup()
        {
            this.camera = null;
            this.settings = null;
        }
    }
}