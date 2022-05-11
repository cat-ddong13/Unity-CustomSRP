using System;
using UnityEngine;

namespace Rendering.CustomSRP.Runtime
{
    [Serializable]
    internal struct CameraBufferSettings
    {
        /// <summary>
        /// 双 三次采样重调整渲染比例模式
        /// </summary>
        internal enum BicubicRescalingMode
        {
            Off,
            UpscaleOnly,
            UpAndDown,
        }

        [Serializable]
        internal struct FXAA
        {
            [SerializeField] public bool enable;

            // fxaa阈值
            // Trims the algorithm from processing darks.
            //   0.0833 - upper limit (default, the start of visible unfiltered edges)
            //   0.0625 - high quality (faster)
            //   0.0312 - visible limit (slower)
            [Range(0.0312f, 0.0833f)] [SerializeField]
            private float threshold;

            internal float Threshold => threshold;

            // 相对阈值
            // The minimum amount of local contrast required to apply algorithm.
            //   0.333 - too little (faster)
            //   0.250 - low quality
            //   0.166 - default
            //   0.125 - high quality 
            //   0.063 - overkill (slower)
            [Range(0.0833f, 0.166f)] [SerializeField]
            private float relativeThreshold;

            internal float RelativeThreshold => relativeThreshold;

            // 亚像素混合强度
            // Choose the amount of sub-pixel aliasing removal.
            // This can effect sharpness.
            //   1.00 - upper limit (softer)
            //   0.75 - default amount of filtering
            //   0.50 - lower limit (sharper, less sub-pixel aliasing removal)
            //   0.25 - almost off
            //   0.00 - completely off
            [Range(0f, 1f)] [SerializeField] private float subpixelBlending;

            internal float SubpixelBlending => subpixelBlending;

            // fxaa 采样质量
            internal enum Quality
            {
                Low,
                Medium,
                High
            }

            [SerializeField] private Quality quality;

            internal Quality FXAAQuality => quality;

            internal FXAA(float threshold, float relativeThreshold)
            {
                this.enable = false;
                this.threshold = threshold;
                this.relativeThreshold = relativeThreshold;
                this.subpixelBlending = 0.75f;
                this.quality = Quality.Low;
            }
        }

        [SerializeField] private bool allowHDR, copyColor, copyColorReflections, copyPath, copyDepthReflections;

        // 渲染比例
        [SerializeField] [Range(CameraRenderer.RENDER_SCALE_MIN, CameraRenderer.RENDER_SCALE_MAX)]
        private float renderScale;

        // 双 三次采样 调整渲染比例
        [SerializeField] private BicubicRescalingMode bicubicRescalling;

        [SerializeField] private FXAA fxaa;
        internal FXAA FxAA => fxaa;

        internal bool AllowHDR => allowHDR;
        internal bool CopyColor => copyColor;
        internal bool CopyColorReflections => copyColorReflections;
        internal bool CopyPath => copyPath;
        internal bool CopyDepthReflections => copyDepthReflections;
        internal float RenderScale => renderScale;
        internal BicubicRescalingMode BicubicRescalling => bicubicRescalling;

        internal CameraBufferSettings(bool copyColor, bool copyPath)
        {
            this.allowHDR = false;
            this.copyColor = copyColor;
            this.copyColorReflections = false;
            this.copyPath = copyPath;
            this.copyDepthReflections = false;
            this.renderScale = 1f;
            this.bicubicRescalling = BicubicRescalingMode.Off;
            this.fxaa = new FXAA(0.0833f, 0.166f);
        }
    }
}