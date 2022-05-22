using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    internal static class CustomShaderTagIDs
    {
        internal static readonly ShaderTagId[] legacyShaderTagIds =
        {
            new("Always"),
            new("ForwardBase"),
            new("PrepassBase"),
            new("Vertex"),
            new("VertexLMRGBM"),
            new("VertexLM")
        };

        // 非照明shader标签id
        internal static readonly ShaderTagId unlitShaderTagId = new("SRPDefaultUnlit");

        // 照明shader标签id
        internal static readonly ShaderTagId litShaderTagId = new("CustomLit");
    }
}