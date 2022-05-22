using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    internal partial class CameraRenderer
    {
        // 采集器名称
        private string SAMPLE_NAME { get; set; }

        private partial void DrawGizmosBeforeFX();
        private partial void DrawGizmosAfterFX();
        private partial void DrawUnsupportedShaders();
        private partial void PrepareForSceneView();
        private partial void PrepareBuffer();

#if UNITY_EDITOR

        private static Material errorMaterial;

        /// <summary>
        /// 绘制不支持的shader
        /// </summary>
        private partial void DrawUnsupportedShaders()
        {
            // 设置不支持的材质shader
            if (null == errorMaterial)
            {
                errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
            }

            // 设置渲染物体的排序方法-非透明
            var sortingSetting = new SortingSettings(camera)
            {
                criteria = SortingCriteria.CommonOpaque
            };

            var legacyShaderTagIds = CustomShaderTagIDs.legacyShaderTagIds;

            // 设置无光照绘制方案
            var drawSettings = new DrawingSettings(legacyShaderTagIds[0], sortingSetting)
            {
                overrideMaterial = errorMaterial
            };

            // 设置目标pass
            for (int i = 1; i < legacyShaderTagIds.Length; i++)
            {
                drawSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
            }

            // 过滤设置-非透明
            var filtering = new FilteringSettings(RenderQueueRange.opaque);
            // 绘制-非透明队列的物体
            context.DrawRenderers(cullingResults, ref drawSettings, ref filtering);

            // 设置渲染物体的排序方法-透明
            sortingSetting.criteria = SortingCriteria.CommonTransparent;
            // 过滤设置-透明
            filtering.renderQueueRange = RenderQueueRange.transparent;
            // 绘制-透明队列的物体
            context.DrawRenderers(cullingResults, ref drawSettings, ref filtering);
        }

        private partial void DrawGizmosBeforeFX()
        {
            if (!Handles.ShouldRenderGizmos())
                return;

            if (useIntermediateBuffer)
            {
                Draw(CameraPropertyIDs.depthAttachmentId, BuiltinRenderTextureType.CameraTarget,
                    CameraRenderPass.Depth);
                ExecuteBuffer();
                return;
            }

            context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
        }

        private partial void DrawGizmosAfterFX()
        {
            if (!Handles.ShouldRenderGizmos())
                return;

            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }

        /// <summary>
        /// 设置scene场景
        /// </summary>
        private partial void PrepareForSceneView()
        {
            if (camera.cameraType == CameraType.SceneView)
            {
                // 为scene场景设置世界空间中几何体数据
                ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
            }
        }

        /// <summary>
        /// 设置缓冲区
        /// </summary>
        private partial void PrepareBuffer()
        {
            Profiler.BeginSample("Editor Only");
            buffer.name = SAMPLE_NAME = camera.name;
            Profiler.EndSample();
        }
#else
    const string SAMPLE_NAME = BUFFER_NAME;
#endif
    }
}