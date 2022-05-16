using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
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

        internal void Render(ref int src, ref PostFXSettings.PostOutlineSettings settings)
        {
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