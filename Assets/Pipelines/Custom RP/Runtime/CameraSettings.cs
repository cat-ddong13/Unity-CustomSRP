using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    [Serializable]
    internal class CameraSettings
    {
        [Serializable]
        internal struct FinalBlendMode
        {
            [SerializeField] private BlendMode src, dst;

            public BlendMode Src => src;
            public BlendMode Dst => dst;

            public FinalBlendMode(BlendMode src, BlendMode dst)
            {
                this.src = src;
                this.dst = dst;
            }
        }

        [SerializeField] private FinalBlendMode blendMode =
            new FinalBlendMode(UnityEngine.Rendering.BlendMode.One, UnityEngine.Rendering.BlendMode.Zero);

        internal FinalBlendMode BlendMode => blendMode;

        [SerializeField] private bool overridePostFXSettings;
        internal bool OverridePostFXSettings => overridePostFXSettings;
        [SerializeField] private PostFXSettings postFXSettings;
        internal PostFXSettings PostFXSettings => postFXSettings;

        [RenderingLayerMaskField] [SerializeField]
        internal int renderingLayerMask = -1;

        internal int RenderingLayerMask => renderingLayerMask;

        [SerializeField] private bool maskLights = false;
        internal bool MaskLights => maskLights;

        [SerializeField] private bool copyColor = true;
        internal bool CopyColor => copyColor;

        [SerializeField] private bool copyDepth = true;
        internal bool CopyDepth => copyDepth;

        // 渲染比例模式(相对于全局)
        internal enum RenderScaleMode
        {
            // 继承
            Inherit,

            // 相乘
            Multiply,

            // 覆盖
            Override,
        }

        [SerializeField] private RenderScaleMode renderScaleMode;

        [SerializeField] [Range(CameraRenderer.RENDER_SCALE_MIN, CameraRenderer.RENDER_SCALE_MAX)]
        private float renderScale;

        [SerializeField] private bool enableFxaa = false;
        internal bool EnableFxaa => enableFxaa;
        [SerializeField] private bool keepAlpha = false;
        internal bool KeepAlpha => keepAlpha;

        internal float GetCameraRenderScale(float value)
        {
            switch (renderScaleMode)
            {
                case RenderScaleMode.Inherit:
                    return value;
                case RenderScaleMode.Multiply:
                    return value * renderScale;
                case RenderScaleMode.Override:
                    return renderScale;
            }

            return 1;
        }
    }
}