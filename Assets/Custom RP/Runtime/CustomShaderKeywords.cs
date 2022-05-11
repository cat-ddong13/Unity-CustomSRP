namespace Rendering.CustomSRP.Runtime
{
    internal class CustomShaderKeywords
    {
        // 逐对象光照关键字
        internal const string lightsPerObjectKeyword = "_LIGHTS_PER_OBJECT";

        // 平行光阴影滤波器关键字
        internal static readonly string[] directionalFilterKeywords =
        {
            "_DIRECTIONAL_PCF3", "_DIRECTIONAL_PCF5", "_DIRECTIONAL_PCF7"
        };

        internal static readonly string[] otherFilterKeywords = {"_OTHER_PCF3", "_OTHER_PCF5", "_OTHER_PCF7"};

        // 阴影级联融合关键词
        internal static readonly string[] cascadeBlendKeyWords = {"_CASCADE_BLEND_SOFT", "_CASCADE_BLEND_DITHER"};

        // 阴影遮罩关键词，两种ShadowMask模式
        internal static readonly string[] shadowMaskKeywords = {"_SHADOW_MASK_ALWAYS", "_SHADOW_MASK_DISTANCE"};
    }
}