using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    using PostOutlineSettings = PostFXSettings.PostOutlineSettings;
    using OutlineType = PostFXSettings.PostOutlineSettings.OutlineType;

    internal class PostFXOutlines
    {
        private CommandBuffer buffer;
        private Material material;
        private Vector2Int bufferSize;

        internal PostFXOutlines()
        {
        }

        internal void Setup(CommandBuffer buffer, Vector2Int bufferSize, Material material)
        {
            this.buffer = buffer;
            this.material = material;
            this.bufferSize = bufferSize;
        }

        internal void Render(ref int src, ref PostOutlineSettings settings)
        {
            if (settings.outlineType == OutlineType.Sobel)
            {
                buffer.EnableShaderKeyword(PostFXKeywords.POST_OUTLINE_SOBEL_KEYWORDS);
            }
            else
            {
                buffer.DisableShaderKeyword(PostFXKeywords.POST_OUTLINE_SOBEL_KEYWORDS);
            }

            buffer.SetGlobalFloat(PostFXPropertyIDs.postOutlineIntensityId,settings.intensity);
            buffer.SetGlobalFloat(PostFXPropertyIDs.postOutlineWidthId,settings.outlineWidth);
            buffer.SetGlobalFloat(PostFXPropertyIDs.postOutlineThresholdId, settings.outlineThreshold);
            buffer.SetGlobalColor(PostFXPropertyIDs.postOutlineColorId, settings.outlineColor);

            buffer.GetTemporaryRT(PostFXPropertyIDs.postOutlineTexId, bufferSize.x, bufferSize.y, 0,
                FilterMode.Bilinear, RenderTextureFormat.Default);
            Draw(src, PostFXPropertyIDs.postOutlineTexId, PostFXPasses.OutlineSobel);
            buffer.ReleaseTemporaryRT(src);
            src = PostFXPropertyIDs.postOutlineTexId;
        }

        private void Draw(RenderTargetIdentifier from, RenderTargetIdentifier to, PostFXPasses pass)
        {
            buffer.SetGlobalTexture(PostFXPropertyIDs.fxSourceId, from);
            buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            buffer.DrawProcedural(Matrix4x4.identity, material, (int) pass, MeshTopology.Triangles, 3);
        }
    }
}