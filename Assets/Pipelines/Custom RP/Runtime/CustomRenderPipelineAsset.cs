using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    /// <summary>
    /// 自定义渲染管线资源
    /// </summary>
    [CreateAssetMenu(menuName = "Rendering/Custom Render Pipeline")]
    public partial class CustomRenderPipelineAsset : RenderPipelineAsset
    {
        [Serializable]
        internal struct CustomRenderPipelineSettings
        {
            // 动态合批
            [SerializeField] private bool enableDynamicBatching;

            // GPU-Instancing
            [SerializeField] private bool enableInstancing;

            // SRP合批
            [SerializeField] private bool enableSRPBathing;

            // 灯光使用线性空间
            [SerializeField] private bool lightsUseLinearIntensity;

            // 是否使用per-object逐对象光照
            [SerializeField] private bool useLightsPerObject;

            // LOD过度动画时长
            [SerializeField] private float crossFadeAniDuration;

            // 阴影设置
            [SerializeField] private ShadowSettings shadowSettings;

            internal bool EnableDynamicBatching => enableDynamicBatching;
            internal bool EnableInstancing => enableInstancing;
            internal bool EnableSRPBathing => enableSRPBathing;

            internal bool LightsUseLinearIntensity => lightsUseLinearIntensity;

            internal bool UseLightsPerObject => useLightsPerObject;
            internal float CrossFadeAniDuration => crossFadeAniDuration;

            internal ShadowSettings ShadowSettings => shadowSettings;

            internal CustomRenderPipelineSettings(float crossFadeAniDuration)
            {
                this.crossFadeAniDuration = crossFadeAniDuration;
                this.enableDynamicBatching = false;
                this.enableInstancing = true;
                this.enableSRPBathing = true;
                this.lightsUseLinearIntensity = true;
                this.useLightsPerObject = false;
                this.shadowSettings = default;
            }
        }

        [SerializeField] private CustomRenderPipelineSettings customRenderPipelineSetting =
            new (0.5f);

        [SerializeField] private PostFXSettings postFXSettings = default;

        [SerializeField] private Shader cameraRenderShader = default;

        [SerializeField] private CameraBufferSettings cameraBufferSettings = new CameraBufferSettings();

        protected override RenderPipeline CreatePipeline()
        {
            return new CustomRenderPipeline(ref customRenderPipelineSetting, ref postFXSettings,
                ref cameraBufferSettings,
                cameraRenderShader);
        }
    }
}