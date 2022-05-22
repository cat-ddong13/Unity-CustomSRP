using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    using BloomSettings = PostFXSettings.BloomSettings;

    internal class PostFXBloom
    {
        // bloom纹理金字塔起始ID
        private int bloomPyramidId;

        private Camera camera;
        private Vector2Int bufferSize;
        private CommandBuffer buffer;
        private bool useHDR;
        private Material material;
        private int tempID;

        internal PostFXBloom()
        {
            // 请求bloom纹理金字塔的ID组
            bloomPyramidId = Shader.PropertyToID("_BloomPyramid0");
            var bloomMaxIterations = PostFXSettings.MAX_BLOOM_PYRAMID_LEVEL * 2;
            for (int i = 1; i < bloomMaxIterations; i++)
            {
                Shader.PropertyToID("_BloomPyramid" + i);
            }
        }

        internal void Setup(Camera camera, CommandBuffer buffer, Vector2Int bufferSize, Material material, bool useHDR)
        {
            this.camera = camera;
            this.buffer = buffer;
            this.useHDR = useHDR;
            this.material = material;
            this.bufferSize = bufferSize;
        }

        internal void Render(ref BloomSettings bloomSettings, ref int src)
        {
            var maxIterations = bloomSettings.MaxIterations;
            var limit = bloomSettings.DownscaleLimit;
            var intensity = bloomSettings.Intensity;

            var width = 0;
            var height = 0;

            var ignoreRenderScale = bloomSettings.IgnoreRenderScale;
            if (ignoreRenderScale)
            {
                width = camera.pixelWidth / 2;
                height = camera.pixelHeight / 2;
            }
            else
            {
                width = bufferSize.x / 2;
                height = bufferSize.y / 2;
            }

            if (maxIterations == 0 || height < limit * 2 || width < limit * 2 || intensity <= 0)
                return;

            buffer.BeginSample("Bloom");

            // w = max(s,b - t) / max (b , 0.00001);
            // s = square( min(max(0,b-t+tk),2tk) ) / 4tk + 0.0001
            // b : brightness(亮度)
            // t : threshold(阈值)
            // k : knee(拐点形状)
            // x : t
            // y : -t + tk
            // z : 2tk
            // w : 1 / 4tk + 0.00001
            var threshold = Vector4.zero;
            threshold.x = Mathf.GammaToLinearSpace(bloomSettings.Threshold);
            threshold.y = threshold.x * bloomSettings.ThresholdKnee;
            threshold.z = 2f * threshold.y;
            threshold.w = 0.25f / (threshold.y + 0.00001f);
            threshold.y -= threshold.x;
            // 设置bloom阈值        
            buffer.SetGlobalVector(PostFXPropertyIDs.bloomShresholdId, threshold);

            // 设置渲染图像的格式
            var format = useHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default;
            // 请求一个用于bloom预滤波的图，用于提取图像高亮部分
            // 因为bloom本来就是一种模糊效果，所以不必特别在意分辨率的问题，直接取原图像一半的分辨率即可
            buffer.GetTemporaryRT(PostFXPropertyIDs.bloomPrefilterId, width, height, 0, FilterMode.Bilinear, format);
            // 设置pass并绘制预滤波图
            Draw(src, PostFXPropertyIDs.bloomPrefilterId,
                bloomSettings.FadeFirefiles ? PostFXPasses.BloomPrefileterFireflies : PostFXPasses.BloomPrefilter);

            width /= 2;
            height /= 2;

            var fromId = PostFXPropertyIDs.bloomPrefilterId;
            var toId = bloomPyramidId + 1;
            int i = 0;
            // 循环降采样
            // →↓
            //  →↓
            //   →↓
            for (; i < maxIterations; i++)
            {
                if (width < limit || height < limit)
                    break;

                var mid = toId - 1;
                buffer.GetTemporaryRT(mid, width, height, 0, FilterMode.Bilinear, format);
                buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, format);
                Draw(fromId, mid, PostFXPasses.BloomHorizontal);
                Draw(mid, toId, PostFXPasses.BloomVertical);
                fromId = toId;
                toId += 2;
                width /= 2;
                height /= 2;
            }

            buffer.ReleaseTemporaryRT(PostFXPropertyIDs.bloomPrefilterId);
            // 设置强度
            buffer.SetGlobalFloat(PostFXPropertyIDs.bloomIntensityId, intensity);
            // 设置是否使用了多次上采样
            buffer.SetGlobalFloat(PostFXPropertyIDs.bloomBucibicUpsamplingId,
                bloomSettings.BicubicUpsampling ? 1f : 0f);

            // scatter模式的话需要在最后的合并时添加一个散射光补偿
            var finalIntensity = 0f;
            PostFXPasses combinePass;
            PostFXPasses finalPass;
            if (bloomSettings.BloomMode == PostFXSettings.BloomSettings.Mode.Additive)
            {
                combinePass = finalPass = PostFXPasses.BloomAdditive;
                buffer.SetGlobalFloat(PostFXPropertyIDs.bloomIntensityId, 1f);
                finalIntensity = intensity;
            }
            else
            {
                combinePass = PostFXPasses.BloomScatter;
                finalPass = PostFXPasses.BloomScatterFinal;
                buffer.SetGlobalFloat(PostFXPropertyIDs.bloomIntensityId, bloomSettings.Scatter);
                finalIntensity = Mathf.Min(intensity, 0.95f);
            }

            // 其实就是将上面的操作反向上采样合并到上一步的采样结果中
            // ↑
            //  ↑
            //   ↑
            if (i > 1)
            {
                buffer.ReleaseTemporaryRT(fromId - 1);
                toId -= 5;
                for (i -= 1; i > 0; i--)
                {
                    buffer.SetGlobalTexture(PostFXPropertyIDs.fxSourceId2, toId + 1);
                    Draw(fromId, toId, combinePass);
                    buffer.ReleaseTemporaryRT(fromId);
                    buffer.ReleaseTemporaryRT(toId + 1);
                    fromId = toId;
                    toId -= 2;
                }
            }
            else
            {
                buffer.ReleaseTemporaryRT(bloomPyramidId);
            }

            buffer.SetGlobalFloat(PostFXPropertyIDs.bloomIntensityId, finalIntensity);
            // 将最终采样结果合并到原图上并输出
            buffer.SetGlobalTexture(PostFXPropertyIDs.fxSourceId2, src);
            buffer.GetTemporaryRT(PostFXPropertyIDs.bloomResultId, bufferSize.x, bufferSize.y, 0, FilterMode.Bilinear,
                format);
            Draw(fromId, PostFXPropertyIDs.bloomResultId, finalPass);
            buffer.ReleaseTemporaryRT(fromId);
            buffer.EndSample("Bloom");
            src = PostFXPropertyIDs.bloomResultId;
        }

        private void Draw(RenderTargetIdentifier from, RenderTargetIdentifier to, PostFXPasses pass)
        {
            buffer.SetGlobalTexture(PostFXPropertyIDs.fxSourceId, from);
            buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            buffer.DrawProcedural(Matrix4x4.identity, material, (int) pass, MeshTopology.Triangles, 3);
        }
    }
}