using System;
using UnityEngine;

namespace Rendering.CustomSRP.Runtime
{
    [Serializable]
    internal class ShadowSettings
    {
        /// <summary>
        /// 阴影纹理大小
        /// </summary>
        internal enum AtlasSize
        {
            _64 = 64,
            _128 = 128,
            _256 = 256,
            _512 = 512,
            _1024 = 1024,
            _2048 = 2048,
            _4096 = 4096,
            _8192 = 8192
        }

        /// <summary>
        /// 滤波器方式
        /// </summary>
        internal enum FilterMode
        {
            PCF2X2,
            PCF3X3,
            PCF5X5,
            PCF7X7,
        }

        /// <summary>
        /// 级联融合模式
        /// </summary>
        internal enum CascadeBlendMode
        {
            Hard,
            Soft,
            Dither,
        }

        [Serializable]
        internal struct Directional
        {
            // 纹理大小
            [SerializeField] private AtlasSize atlasSize;

            internal AtlasSize AtlasSize => atlasSize;

            // 滤波模式
            [SerializeField] private FilterMode filterMode;

            public FilterMode FilterMode => filterMode;

            // 级联融合模式
            [SerializeField] private CascadeBlendMode blendMode;

            public CascadeBlendMode BlendMode => blendMode;

            // 级联数量
            [SerializeField] [Range(1, 4)] private int cascadeCount;

            public int CascadeCount => cascadeCount;

            // 1级级联比率
            [SerializeField] [Range(0f, 1f)] private float cascadeRatio1;

            // 2级级联比率
            [SerializeField] [Range(0f, 1f)] private float cascadeRatio2;

            // 3级级联比率
            [SerializeField] [Range(0f, 1f)] private float cascadeRatio3;

            // 级联比率
            public Vector3 CascadeRatios => new Vector3(cascadeRatio1, cascadeRatio2, cascadeRatio3);

            // 级联过度比率
            [SerializeField] [Range(0.001f, 1f)] private float cascadeFadeRitio;

            public float CascadeFadeRatio => cascadeFadeRitio;

            public Directional(AtlasSize atlasSize = AtlasSize._1024, FilterMode filterMode = FilterMode.PCF2X2,
                CascadeBlendMode blendMode = CascadeBlendMode.Hard,
                int cascadeCount = 1, float cascadeRatio1 = 0.1f,
                float cascadeRatio2 = 0.25f, float cascadeRatio3 = 0.5f, float cascadeFadeRitio = 0.1f)
            {
                this.atlasSize = atlasSize;
                this.filterMode = filterMode;
                this.blendMode = blendMode;
                this.cascadeCount = cascadeCount;
                this.cascadeRatio1 = cascadeRatio1;
                this.cascadeRatio2 = cascadeRatio2;
                this.cascadeRatio3 = cascadeRatio3;
                this.cascadeFadeRitio = cascadeFadeRitio;
            }
        }

        [Serializable]
        internal struct Other
        {
            [SerializeField] private AtlasSize atlasSize;

            public AtlasSize AtlasSize => atlasSize;

            [SerializeField] private FilterMode filterMode;

            public FilterMode FilterMode => filterMode;

            public Other(AtlasSize atlasSize = AtlasSize._1024, FilterMode filterMode = FilterMode.PCF2X2)
            {
                this.atlasSize = atlasSize;
                this.filterMode = filterMode;
            }
        }

        // 产生阴影的最大距离
        [SerializeField] [Min(0.001f)] private float maxDistance = 100f;

        internal float MaxDistance => maxDistance;

        // 距离过度比率
        [SerializeField] [Range(0.001f, 1f)] private float distanceFadeRitio = 0.1f;
        internal float DistanceFadeRatio => distanceFadeRitio;

        [SerializeField] private Directional diractional = new(AtlasSize._1024);
        internal Directional Directionals => diractional;

        [SerializeField]
        private Other other = new(AtlasSize._1024);
        internal Other Others => other;
    }
}