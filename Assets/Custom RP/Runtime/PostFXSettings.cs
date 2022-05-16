using System;
using System.Data.SqlClient;
using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.UI;

namespace Rendering.CustomSRP.Runtime
{
    [CreateAssetMenu(menuName = "Rendering/Custom PostFX Settings")]
    [Serializable]
    public class PostFXSettings : ScriptableObject
    {
        [SerializeField] private Shader shader = default;

        [SerializeField] private bool enabled = false;
        internal bool Enabled => enabled;
        [NonSerialized] private Material material;

        internal Material Material
        {
            get
            {
                if (null == material && null != shader)
                {
                    material = new Material(shader);
                    material.hideFlags = HideFlags.HideAndDontSave;
                }

                return material;
            }
        }

        [Serializable]
        public struct BloomSettings
        {
            // Bloom模式
            internal enum Mode
            {
                // 累计
                Additive,

                // 散射
                Scattering,
            }

            [SerializeField] private Mode mode;

            // 散射程度
            [ShowIf("@mode == Mode.Scattering")] [SerializeField] [Range(0.05f, 0.95f)]
            private float scatter;

            // bloom强度
            [SerializeField] [ShowIf("@mode == Mode.Additive")] [Min(0f)]
            private float intensity;

            [SerializeField] [Range(0, MAX_BLOOM_PYRAMID_LEVEL)]
            // 循环叠加次数
            private int maxIterations;

            // 降采样最低规模
            [ShowIf("@intensity > 0  && maxIterations > 0")] [SerializeField] [Min(1f)]
            private int downscaleLimit;

            // 是否使用多重上采样
            [ShowIf("@intensity > 0  && maxIterations > 0")] [SerializeField]
            private bool bicubicUpsampling;

            // bloom阈值
            [ShowIf("@intensity > 0  && maxIterations > 0")] [SerializeField] [Min(0f)]
            private float threshold;

            // bloom阈值拐点软硬形状
            [ShowIf("@intensity > 0  && maxIterations > 0")] [SerializeField] [Range(0f, 1f)]
            private float thresholdKnee;

            // 是否淡出bloom运动时产生的光斑
            [ShowIf("@intensity > 0  && maxIterations > 0")] [SerializeField]
            private bool fadeFirefiles;

            // 是否忽略渲染比例
            [SerializeField] [ShowIf("@intensity > 0  && maxIterations > 0")]
            private bool ignoreRenderScale;

            internal Mode BloomMode => mode;
            internal float Scatter => scatter;
            internal int MaxIterations => maxIterations;
            internal int DownscaleLimit => downscaleLimit;
            internal bool BicubicUpsampling => bicubicUpsampling;
            internal float Threshold => threshold;
            internal float ThresholdKnee => thresholdKnee;
            internal bool FadeFirefiles => fadeFirefiles;
            internal float Intensity => intensity;
            internal bool IgnoreRenderScale => ignoreRenderScale;

            internal BloomSettings(float scatter)
            {
                this.mode = Mode.Additive;
                this.scatter = scatter;
                this.maxIterations = 1;
                this.intensity = 1;
                this.downscaleLimit = 1;
                this.bicubicUpsampling = false;
                this.threshold = 0.5f;
                this.thresholdKnee = 0.5f;
                this.fadeFirefiles = true;
                this.ignoreRenderScale = false;
            }
        }

        /// <summary>
        /// 色调映射
        /// </summary>
        [Serializable]
        internal struct ToneMappingSettings
        {
            // Reinhard模式(曲线)
            internal enum Mode
            {
                None,

                ACES,

                Neutral,

                Reinhard
            }

            [SerializeField] private Mode mode;

            internal Mode TMMode => mode;
        }


        /// <summary>
        /// 色彩调整
        /// </summary>
        [Serializable]
        internal struct ColorAdjustmentsSettings
        {
            // 曝光
            [SerializeField] private float postExposure;

            // 滤镜
            [ColorUsage(false, true)] [SerializeField]
            private Color colorFilter;

            // 对比度
            [Range(-100f, 100f)] [SerializeField] private float contrast;

            // 色相偏移
            [Range(-180, 180f)] [SerializeField] private float hueShift;

            // 饱和度
            [Range(-100f, 100f)] [SerializeField] private float saturation;

            internal Color ColorFilter => colorFilter;

            internal float PostExposure => postExposure;
            internal float Contrast => contrast;
            internal float HueShift => hueShift;
            internal float Saturation => saturation;


            public ColorAdjustmentsSettings(Color colorFilter)
            {
                this.colorFilter = colorFilter;
                this.postExposure = 0f;
                this.contrast = 0f;
                this.hueShift = 0f;
                this.saturation = 0f;
            }
        }

        /// <summary>
        /// 白平衡，用于调整色温色调
        /// </summary>
        [Serializable]
        internal struct WhiteBalanceSettings
        {
            // 色温
            [Range(-100f, 100f)] [SerializeField] private float temperature;

            // 色调
            [Range(-100f, 100f)] [SerializeField] private float tint;

            internal float Temperature => temperature;
            internal float Tint => tint;
        }

        /// <summary>
        /// 色调分离，用于分离阴影和高光的色调调整
        /// </summary>
        [Serializable]
        internal struct SplitToningSettings
        {
            [ColorUsage(false)] [SerializeField] private Color shadows;
            [ColorUsage(false)] [SerializeField] private Color highLights;
            [Range(-100f, 100f)] [SerializeField] private float balance;

            internal Color Shadows => shadows;
            internal Color HighLights => highLights;
            internal float Balance => balance;

            internal SplitToningSettings(Color shadows, Color highLights)
            {
                this.shadows = shadows;
                this.highLights = highLights;
                this.balance = 0f;
            }
        }

        /// <summary>
        /// 颜色通道混合设置
        /// </summary>
        [Serializable]
        internal struct ChannelMixerSettings
        {
            [SerializeField] private Vector3 r, g, b;
            public Vector3 R => r;
            public Vector3 G => g;
            public Vector3 B => b;

            public ChannelMixerSettings(Vector3 r, Vector3 g, Vector3 b)
            {
                this.r = r;
                this.g = g;
                this.b = b;
            }
        }

        /// <summary>
        /// 阴影-中间-高光区域的过渡
        /// </summary>
        [Serializable]
        internal struct ShadowsMidtonesHighlightsSettings
        {
            [ColorUsage(false, true)] [SerializeField]
            private Color shadows, midtones, highlights;

            [SerializeField] [Range(0f, 2f)] private float shadowsStart, shadowsEnd, highlightsStart, highlightsEnd;

            internal Color Shadows => shadows;
            internal Color Midtones => midtones;
            internal Color Highlights => highlights;
            internal float ShadowsStart => shadowsStart;
            internal float ShadowsEnd => shadowsEnd;
            internal float HighlightsStart => highlightsStart;
            internal float HighlightsEnd => highlightsEnd;

            internal ShadowsMidtonesHighlightsSettings(Color initColor, float shadowsEnd, float highlightsStart,
                float highlightsEnd)
            {
                this.shadows = initColor;
                this.midtones = initColor;
                this.highlights = initColor;

                this.shadowsStart = 0f;
                this.shadowsEnd = shadowsEnd;
                this.highlightsStart = highlightsStart;
                this.highlightsEnd = highlightsEnd;
            }
        }

        internal enum ColorLUTResolution
        {
            _16 = 16,
            _32 = 32,
            _64 = 64
        }

        [Serializable]
        internal struct PostOutlineSettings
        {
            internal enum OutlineType
            {
                Sobel,
                Depth,
            }

            [SerializeField] internal bool enabled;
            [SerializeField] internal OutlineType outlineType;

            [SerializeField] internal Color outlineColor;

            [SerializeField] [Range(0f, 1f)] internal float outlineThreshold;
        }

        internal const int MAX_BLOOM_PYRAMID_LEVEL = 16;

        [SerializeField] internal BloomSettings bloom = new BloomSettings(0.7f);

        [SerializeField] internal ToneMappingSettings tonemapping = default;

        [SerializeField] internal ColorAdjustmentsSettings colorAdjustments = new ColorAdjustmentsSettings(Color.white);

        [SerializeField] internal WhiteBalanceSettings whiteBalance;

        [SerializeField] internal SplitToningSettings splitToning = new SplitToningSettings(Color.gray, Color.gray);

        [SerializeField] internal ChannelMixerSettings channelMixer =
            new ChannelMixerSettings(Vector3.right, Vector3.up, Vector3.forward);

        [SerializeField] internal ShadowsMidtonesHighlightsSettings shadowsMidtonesHighlights =
            new ShadowsMidtonesHighlightsSettings(Color.white, 0.3f, 0.55f, 1f);

        [SerializeField] internal ColorLUTResolution colorLUTResolution = ColorLUTResolution._32;

        [SerializeField] internal PostOutlineSettings postOutlines = new PostOutlineSettings();
    }
}