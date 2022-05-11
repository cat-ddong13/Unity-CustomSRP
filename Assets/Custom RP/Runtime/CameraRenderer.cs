using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    using CustomRenderPipelineSettings = CustomRenderPipelineAsset.CustomRenderPipelineSettings;

    internal partial class CameraRenderer
    {
        // 最小渲染比例
        internal const float RENDER_SCALE_MIN = 0.1f;

        // 最大渲染比例
        internal const float RENDER_SCALE_MAX = 2f;

        // 缓冲区名称
        private const string BUFFER_NAME = "Render Camera";

        // 命令缓冲区
        private CommandBuffer buffer = new CommandBuffer {name = BUFFER_NAME};

        // 分离颜色和深度
        private bool useColorTexture = false;
        private bool useDepthTexture = false;
        private bool useIntermediateBuffer = false;

        // 渲染内容(定义渲染状态和渲染命令)
        private ScriptableRenderContext context;

        // 目标相机
        private Camera camera;

        // 灯光
        private Lighting lighting = new Lighting();

        // 裁剪结果
        private CullingResults cullingResults;

        // 后处理
        private PostFXRenderer postFXRenderer = new PostFXRenderer();

        private CameraSettings defaultCameraSettings = new CameraSettings();

        private Material material;

        // 在没有使用depthtex时，为了防止采样结果不一致，用一个固定的tex显示错误采样
        private Texture2D missingTex;

        // 是否支持拷贝纹理(WebGl2.0不支持)
        private static bool isCopyTexSupported = SystemInfo.copyTextureSupport > CopyTextureSupport.None;

        private bool useHDR = false;

        private Vector2Int bufferSize = Vector2Int.zero;
        private bool useScaledRendering;

        internal CameraRenderer(Shader shader)
        {
            if (null != shader)
            {
                this.material = CoreUtils.CreateEngineMaterial(shader);
            }

            this.missingTex = new Texture2D(1, 1)
            {
                hideFlags = HideFlags.HideAndDontSave,
                name = "Missing Tex"
            };
            this.missingTex.SetPixel(0, 0, Color.white * 0.5f);
            this.missingTex.Apply(true, true);
        }

        internal void Render(Camera camera, ScriptableRenderContext context, PostFXSettings postFXSettings,
            ref CustomRenderPipelineSettings crpSettings, ref CameraBufferSettings cameraBufferSettings)
        {
            this.context = context;
            this.camera = camera;

            // 准备缓冲区
            PrepareBuffer();
            // 设置scene场景
            PrepareForSceneView();

            // 相机裁剪
            if (!Cull(crpSettings.ShadowSettings.MaxDistance))
                return;

            buffer.BeginSample(SAMPLE_NAME);

            var crpCamera = camera.GetComponent<CustomRenderPipelineCamera>();
            var cameraSettings = crpCamera ? crpCamera.Settings : defaultCameraSettings;
            if (cameraSettings.OverridePostFXSettings && null != cameraSettings.PostFXSettings)
            {
                postFXSettings = cameraSettings.PostFXSettings;
            }

            // 分离颜色和深度
            if (camera.cameraType == CameraType.Reflection)
            {
                useColorTexture = cameraBufferSettings.CopyColorReflections;
                useDepthTexture = cameraBufferSettings.CopyDepthReflections;
            }
            else
            {
                useColorTexture = cameraBufferSettings.CopyColor && cameraSettings.CopyColor;
                useDepthTexture = cameraBufferSettings.CopyPath && cameraSettings.CopyDepth;
            }

            // 获取相机的渲染比例
            var renderScale = cameraSettings.GetCameraRenderScale(cameraBufferSettings.RenderScale);
            useScaledRendering = Mathf.Abs(renderScale - 1) >= 0.01f;
            if (useScaledRendering)
            {
                // 将渲染比例限制在0.1-2之间
                renderScale = Mathf.Clamp(renderScale, RENDER_SCALE_MIN, RENDER_SCALE_MAX);
                bufferSize.x = (int) (camera.pixelWidth * renderScale);
                bufferSize.y = (int) (camera.pixelHeight * renderScale);
            }
            else
            {
                bufferSize.x = camera.pixelWidth;
                bufferSize.y = camera.pixelHeight;
            }

            buffer.SetGlobalVector(CameraPropertyIDs.cameraBufferSizeId,
                new Vector4(1f / bufferSize.x, 1f / bufferSize.y, bufferSize.x, bufferSize.y));

            ExecuteBuffer();

            // 设置灯光
            lighting.Setup(context, cullingResults, crpSettings.ShadowSettings, crpSettings.UseLightsPerObject,
                cameraSettings.MaskLights ? cameraSettings.RenderingLayerMask : -1);

            useHDR = cameraBufferSettings.AllowHDR && camera.allowHDR;
            if (postFXSettings.Enabled)
            {
                var fxaa = cameraBufferSettings.FxAA;
                fxaa.enable &= cameraSettings.EnableFxaa;
                postFXRenderer.Setup(context, camera, bufferSize, useHDR, cameraSettings.BlendMode,
                    cameraBufferSettings.BicubicRescalling, cameraSettings.KeepAlpha, ref postFXSettings, ref fxaa);
            }

            buffer.EndSample(SAMPLE_NAME);

            // 设置相机
            Setup();

            // 绘制可见几何数据
            DrawVisibleGeometry(crpSettings.EnableDynamicBatching, crpSettings.EnableInstancing,
                crpSettings.UseLightsPerObject, cameraSettings.RenderingLayerMask);
            // 绘制不支持的shader
            DrawUnsupportedShaders();

            // 绘制线框
            DrawGizmosBeforeFX();

            if (postFXRenderer.IsActive)
            {
                postFXRenderer.Render(CameraPropertyIDs.colorAttachmentId);
            }
            else if (useIntermediateBuffer)
            {
                // 因为目标被渲染到纹理上，如果没有后处理需要手动绘制到相机目标
                DrawFinal(cameraSettings.BlendMode);

                ExecuteBuffer();
            }

            DrawGizmosAfterFX();

            // 显示裁剪球体
            if (camera.cameraType == CameraType.Game)
            {
                var component = camera.GetComponent<DrawGizmos>();
                if (null != component)
                {
                    component.DrawSphere();
                }
            }

            Cleanup();
            Submit();
        }

        /// <summary>
        /// 设置相机
        /// </summary>
        private void Setup()
        {
            // 设置相机属性
            context.SetupCameraProperties(camera);

            // 设置清除渲染目标命令
            var clearFlags = camera.clearFlags;
            // 是否使用中间缓冲区
            useIntermediateBuffer = useColorTexture || useDepthTexture || postFXRenderer.IsActive;

            if (useIntermediateBuffer)
            {
                if (clearFlags > CameraClearFlags.Color)
                {
                    clearFlags = CameraClearFlags.Color;
                }

                // 分离颜色缓冲与深度缓冲的获取与设置
                buffer.GetTemporaryRT(CameraPropertyIDs.colorAttachmentId, bufferSize.x, bufferSize.y, 0,
                    FilterMode.Bilinear,
                    useHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);

                buffer.GetTemporaryRT(CameraPropertyIDs.depthAttachmentId, bufferSize.x, bufferSize.y, 32,
                    FilterMode.Point,
                    RenderTextureFormat.Depth);

                buffer.SetRenderTarget(CameraPropertyIDs.colorAttachmentId, RenderBufferLoadAction.DontCare,
                    RenderBufferStoreAction.Store,
                    CameraPropertyIDs.depthAttachmentId, RenderBufferLoadAction.DontCare,
                    RenderBufferStoreAction.Store);
            }

            buffer.ClearRenderTarget(clearFlags <= CameraClearFlags.Depth, clearFlags == CameraClearFlags.Color,
                clearFlags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear);
            buffer.BeginSample(SAMPLE_NAME);

            buffer.SetGlobalTexture(CameraPropertyIDs.colorTextureId, missingTex);
            buffer.SetGlobalTexture(CameraPropertyIDs.depthTextureId, missingTex);

            // 执行缓冲区命令
            ExecuteBuffer();
        }

        /// <summary>
        /// 绘制可见几何数据
        /// </summary>
        private void DrawVisibleGeometry(bool enableDynamicBatching, bool enableInstancing, bool useLightsPerObject,
            int renderingLayerMask)
        {
            // 设置是否使用 per-obj 光照
            var lightsPerObjectFlags = useLightsPerObject
                ? PerObjectData.LightData | PerObjectData.LightIndices
                : PerObjectData.None;

            // 设置渲染物体的排序方法-非透明
            var sortingSettings = new SortingSettings(camera)
            {
                criteria = SortingCriteria.CommonOpaque
            };

            // 设置无光照绘制方案
            var drawingSettings = new DrawingSettings(CustomShaderTagIDs.unlitShaderTagId, sortingSettings)
            {
                // 是否开启动态合批
                enableDynamicBatching = enableDynamicBatching,
                // GPU-Instancing
                enableInstancing = enableInstancing,
                // 设置对象数据类型
                perObjectData = PerObjectData.Lightmaps |
                                PerObjectData.LightProbe |
                                PerObjectData.LightProbeProxyVolume |
                                PerObjectData.ShadowMask |
                                PerObjectData.OcclusionProbe |
                                PerObjectData.OcclusionProbeProxyVolume |
                                PerObjectData.ReflectionProbes |
                                lightsPerObjectFlags
            };

            // 设置有光照的Pass
            drawingSettings.SetShaderPassName(1, CustomShaderTagIDs.litShaderTagId);

            // 过滤设置-非透明
            var filteringSettings =
                new FilteringSettings(RenderQueueRange.opaque, renderingLayerMask, (uint) renderingLayerMask);

            // 绘制-非透明队列的物体
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

            // 绘制天空盒
            context.DrawSkybox(camera);

            // 是否拷贝帧缓冲附件
            if (useColorTexture || useDepthTexture)
            {
                CopyAttachments();
            }

            // 设置渲染物体的排序方法-透明
            sortingSettings.criteria = SortingCriteria.CommonTransparent;
            drawingSettings.sortingSettings = sortingSettings;
            // 过滤设置-透明
            filteringSettings.renderQueueRange = RenderQueueRange.transparent;
            // 绘制-透明队列的物体
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        }

        /// <summary>
        /// 拷贝帧缓冲附件
        /// </summary>
        private void CopyAttachments()
        {
            if (useColorTexture)
            {
                buffer.GetTemporaryRT(CameraPropertyIDs.colorTextureId, bufferSize.x, bufferSize.y, 0,
                    FilterMode.Bilinear,
                    useHDR ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);

                if (isCopyTexSupported)
                {
                    buffer.CopyTexture(CameraPropertyIDs.colorAttachmentId, CameraPropertyIDs.colorTextureId);
                }
                else
                {
                    // 如果不支持拷贝纹理，直接将深度缓冲绘制到深度贴图
                    Draw(CameraPropertyIDs.colorAttachmentId, CameraPropertyIDs.colorTextureId, CameraRenderPass.Base);
                }
            }

            if (useDepthTexture)
            {
                buffer.GetTemporaryRT(CameraPropertyIDs.depthTextureId, bufferSize.x, bufferSize.y, 32,
                    FilterMode.Point,
                    RenderTextureFormat.Depth);

                if (isCopyTexSupported)
                {
                    buffer.CopyTexture(CameraPropertyIDs.depthAttachmentId, CameraPropertyIDs.depthTextureId);
                }
                else
                {
                    // 如果不支持拷贝纹理，直接将深度缓冲绘制到深度贴图
                    Draw(CameraPropertyIDs.depthAttachmentId, CameraPropertyIDs.depthTextureId, CameraRenderPass.Depth);
                }
            }

            if (!isCopyTexSupported)
            {
                buffer.SetRenderTarget(CameraPropertyIDs.colorAttachmentId, RenderBufferLoadAction.Load,
                    RenderBufferStoreAction.Store,
                    CameraPropertyIDs.depthAttachmentId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store);
            }

            ExecuteBuffer();
        }

        /// <summary>
        /// 执行缓冲
        /// </summary>
        private void ExecuteBuffer()
        {
            // 执行缓冲区命令
            context.ExecuteCommandBuffer(buffer);
            // 清除缓冲区
            buffer.Clear();
        }

        private bool Cull(float shadowMaskDistance)
        {
            // 获取相机的裁剪参数
            if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
            {
                // 设置阴影距离--在 阴影设置的最大阴影距离 和 相机远裁剪面 取一个最小值
                p.shadowDistance = Mathf.Min(shadowMaskDistance, camera.farClipPlane);
                // 裁剪并存储结果
                cullingResults = context.Cull(ref p);
                return true;
            }

            return false;
        }

        private void Draw(RenderTargetIdentifier from, RenderTargetIdentifier to, CameraRenderPass pass)
        {
            buffer.SetGlobalTexture(CameraPropertyIDs.sourceTextureId, from);
            buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            buffer.DrawProcedural(Matrix4x4.identity, material, (int) pass, MeshTopology.Triangles, 3);
        }

        private void DrawFinal(CameraSettings.FinalBlendMode finalBlendMode)
        {
            buffer.SetGlobalFloat(CameraPropertyIDs.srcBlendId, (float) finalBlendMode.Src);
            buffer.SetGlobalFloat(CameraPropertyIDs.dstBlendId, (float) finalBlendMode.Dst);
            buffer.SetGlobalTexture(CameraPropertyIDs.sourceTextureId, CameraPropertyIDs.colorAttachmentId);
            buffer.SetRenderTarget(
                BuiltinRenderTextureType.CameraTarget,
                finalBlendMode.Dst == BlendMode.Zero ? RenderBufferLoadAction.DontCare : RenderBufferLoadAction.Load,
                RenderBufferStoreAction.Store
            );
            buffer.SetViewport(camera.pixelRect);
            buffer.DrawProcedural(
                Matrix4x4.identity, material, 0, MeshTopology.Triangles, 3
            );

            buffer.SetGlobalFloat(CameraPropertyIDs.srcBlendId, 1f);
            buffer.SetGlobalFloat(CameraPropertyIDs.dstBlendId, 0f);
        }

        /// <summary>
        /// 提交
        /// </summary>
        private void Submit()
        {
            buffer.EndSample(SAMPLE_NAME);
            // 执行缓冲
            ExecuteBuffer();
            // 提交准备好的命令到渲染循环中执行
            context.Submit();
        }

        private void Cleanup()
        {
            // 清除灯光方面的缓存
            lighting.Cleanup();

            if (useIntermediateBuffer)
            {
                // 释放临时的渲染纹理
                buffer.ReleaseTemporaryRT(CameraPropertyIDs.colorAttachmentId);
                buffer.ReleaseTemporaryRT(CameraPropertyIDs.depthAttachmentId);

                if (useColorTexture)
                {
                    buffer.ReleaseTemporaryRT(CameraPropertyIDs.colorTextureId);
                }

                if (useDepthTexture)
                {
                    buffer.ReleaseTemporaryRT(CameraPropertyIDs.depthTextureId);
                }
            }

            if (postFXRenderer.IsActive)
            {
                postFXRenderer.Cleanup();
            }
        }

        internal void Dispose()
        {
            CoreUtils.Destroy(material);
            CoreUtils.Destroy(missingTex);
        }
    }
}