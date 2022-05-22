using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    using CustomRenderPipelineSettings = CustomRenderPipelineAsset.CustomRenderPipelineSettings;

    /// <summary>
    /// 自定义渲染管线
    /// </summary>
    internal partial class CustomRenderPipeline : RenderPipeline
    {
        private CameraRenderer cameraRenderer;

        private PostFXSettings postFXSettings = default;

        private CustomRenderPipelineSettings crpSettings = default;

        private CameraBufferSettings cameraBufferSettings = default;

        internal CustomRenderPipeline(ref CustomRenderPipelineSettings renderPipelineSettings,
            ref PostFXSettings postFXSettings, ref CameraBufferSettings cameraBufferSettings, Shader cameraRenderShader)
        {
            this.crpSettings = renderPipelineSettings;

            this.cameraBufferSettings = cameraBufferSettings;

            // 设置SRP合批
            GraphicsSettings.useScriptableRenderPipelineBatching = renderPipelineSettings.EnableSRPBathing;
            // 设置线性空间
            GraphicsSettings.lightsUseLinearIntensity = renderPipelineSettings.LightsUseLinearIntensity;
            // 设置LOD融合过度动画时长
            LODGroup.crossFadeAnimationDuration = renderPipelineSettings.CrossFadeAniDuration;
            this.postFXSettings = postFXSettings;

            InitializeForEditor();

            cameraRenderer = new CameraRenderer(cameraRenderShader);
        }

        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            // 设置渲染数据
            foreach (var camera in cameras)
            {
                // 相机渲染
                cameraRenderer.Render(camera, context, postFXSettings, ref crpSettings, ref cameraBufferSettings);
            }
        }


        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);

            DisposeForEditor();
            cameraRenderer.Dispose();
        }
    }
}