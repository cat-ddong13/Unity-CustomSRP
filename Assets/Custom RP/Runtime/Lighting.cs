using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    internal class Lighting
    {
        // 缓冲区名称
        private const string BUFFER_NAME = "Lighting";

        // 最大平行光数量限制
        private const int MAX_DIRECTIONAL_LIGHT_COUNT = 4;

        // 最大其余光源(点光源、聚光灯)数量限制
        private const int MAX_OTHER_LIGHT_COUNT = 64;

        // 准备好固定大小的平行光颜色数据
        private static Vector4[] directionalLightColors = new Vector4[MAX_DIRECTIONAL_LIGHT_COUNT];

        // 准备好固定大小的平行光方向数据
        private static Vector4[] directionalLightDirectionsAndMasks = new Vector4[MAX_DIRECTIONAL_LIGHT_COUNT];

        // 准备好固定大小的平行光阴影数据数组
        private static Vector4[] directionalLightShadowDatas = new Vector4[MAX_DIRECTIONAL_LIGHT_COUNT];

        // 非平行光(点光源、聚光灯)颜色数据
        private static Vector4[] otherLightColors = new Vector4[MAX_OTHER_LIGHT_COUNT];

        // 非平行光(点光源、聚光灯)位置数据
        private static Vector4[] otherLightPositions = new Vector4[MAX_OTHER_LIGHT_COUNT];

        // 非平行光(聚光灯)方向数据
        private static Vector4[] otherLightDirectionsAndMasks = new Vector4[MAX_OTHER_LIGHT_COUNT];

        // 非平行光(聚光灯)光锥范围计算相关，用于shader中计算衰减
        private static Vector4[] otherLightSpotsCone = new Vector4[MAX_OTHER_LIGHT_COUNT];

        // 非平行光(点光源、聚光灯)阴影数据
        private static Vector4[] otherLightShadowData = new Vector4[MAX_OTHER_LIGHT_COUNT];

        // 命令缓冲
        private CommandBuffer buffer = new CommandBuffer() {name = BUFFER_NAME};

        // 裁剪结果数据
        private CullingResults cullingResults;

        // 阴影
        private Shadows shadows = new Shadows();

        internal void Setup(ScriptableRenderContext context, CullingResults cullingResults,
            ShadowSettings shadowSettings,
            bool useLightsPerObject, int renderingLayerMask)
        {
            this.cullingResults = cullingResults;
            buffer.BeginSample(BUFFER_NAME);

            // 设置阴影
            shadows.Setup(context, cullingResults, shadowSettings);
            // 设置灯光
            Setup(useLightsPerObject, renderingLayerMask);
            // 绘制阴影
            shadows.Render();

            buffer.EndSample(BUFFER_NAME);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        /// <summary>
        /// 设置灯光
        /// </summary>
        private void Setup(bool useLightsPerObject, int renderingLayerMask)
        {
            var indexMap = useLightsPerObject ? cullingResults.GetLightIndexMap(Allocator.Temp) : default;

            // 获取可见光列表
            var visibleLights = cullingResults.visibleLights;

            var visibleDirLightCount = 0;
            var visibleOtherLightCount = 0;
            // 遍历可见光
            var i = 0;
            for (; i < visibleLights.Length; i++)
            {
                var visibleLight = visibleLights[i];
                var light = visibleLight.light;
                var newIndex = -1;

                if ((light.renderingLayerMask & renderingLayerMask) != 0)
                {
                    switch (visibleLight.lightType)
                    {
                        case LightType.Directional:
                        {
                            if (visibleDirLightCount < MAX_DIRECTIONAL_LIGHT_COUNT)
                            {
                                SetupDirectionalLight(visibleDirLightCount++, i, ref visibleLight);
                            }

                            break;
                        }

                        case LightType.Point:
                        {
                            if (visibleOtherLightCount < MAX_OTHER_LIGHT_COUNT)
                            {
                                newIndex = visibleOtherLightCount;
                                SetupPointLight(visibleOtherLightCount++, i, ref visibleLight);
                            }

                            break;
                        }

                        case LightType.Spot:
                        {
                            if (visibleOtherLightCount < MAX_OTHER_LIGHT_COUNT)
                            {
                                newIndex = visibleOtherLightCount;
                                SetupSpotLight(visibleOtherLightCount++, i, ref visibleLight);
                            }

                            break;
                        }
                    }
                }

                if (useLightsPerObject)
                {
                    indexMap[i] = newIndex;
                }
            }

            if (useLightsPerObject)
            {
                for (; i < indexMap.Length; i++)
                {
                    indexMap[i] = -1;
                }

                // 重建光照索引
                cullingResults.SetLightIndexMap(indexMap);
                indexMap.Dispose();

                Shader.EnableKeyword(CustomShaderKeywords.lightsPerObjectKeyword);
            }
            else
            {
                Shader.DisableKeyword(CustomShaderKeywords.lightsPerObjectKeyword);
            }

            // 设置全局平行光数量
            buffer.SetGlobalInt(LightingPropertyIDs.directionalLightCountId, visibleDirLightCount);
            if (visibleDirLightCount > 0)
            {
                // 设置全局平行光颜色
                buffer.SetGlobalVectorArray(LightingPropertyIDs.directionalLightColorsId, directionalLightColors);
                // 设置全局平行光方向
                buffer.SetGlobalVectorArray(LightingPropertyIDs.directionalLightDirectionsAndMasksId,
                    directionalLightDirectionsAndMasks);
                // 设置全局平行光阴影数据
                buffer.SetGlobalVectorArray(LightingPropertyIDs.directionalLightShadowDataId,
                    directionalLightShadowDatas);
            }

            // 设置全局非平行光(点光源、聚光灯)数量
            buffer.SetGlobalInt(LightingPropertyIDs.otherLightCountId, visibleOtherLightCount);
            if (visibleOtherLightCount > 0)
            {
                // 设置全局非平行光(点光源、聚光灯)颜色数据
                buffer.SetGlobalVectorArray(LightingPropertyIDs.otherLightColorsId, otherLightColors);
                // 设置全局非平行光(点光源、聚光灯)位置数据
                buffer.SetGlobalVectorArray(LightingPropertyIDs.otherLightPositionsId, otherLightPositions);
                // 设置全局非平行光(聚光灯)方向数据
                buffer.SetGlobalVectorArray(LightingPropertyIDs.otherLightDirectionsAndMasksId,
                    otherLightDirectionsAndMasks);
                // 设置全局非平行光(聚光灯)锥体数据
                buffer.SetGlobalVectorArray(LightingPropertyIDs.otherLightSpotsConeId, otherLightSpotsCone);
                // 设置全局非平行光(点光源、聚光灯)阴影数据
                buffer.SetGlobalVectorArray(LightingPropertyIDs.otherLightShadowDataId, otherLightShadowData);
            }
        }

        /// <summary>
        /// 设置平行光属性
        /// </summary>
        /// <param name="index"></param>
        /// <param name="visibleLight"></param>
        private void SetupDirectionalLight(int index, int visibleLightIndex, ref VisibleLight visibleLight)
        {
            // 设置平行光颜色
            directionalLightColors[index] = visibleLight.finalColor;

            var light = visibleLight.light;
            // 设置平行光的阴影数据
            directionalLightShadowDatas[index] = shadows.ReserveDirectionalShadows(light, visibleLightIndex);

            var dirAndMask = -visibleLight.localToWorldMatrix.GetColumn(2);
            dirAndMask.w = light.renderingLayerMask.ReinterpreaAsFloat();

            // 设置平行光方向
            directionalLightDirectionsAndMasks[index] = dirAndMask;
        }

        /// <summary>
        /// 设置点光源属性
        /// </summary>
        /// <param name="index"></param>
        /// <param name="visibleLight"></param>
        private void SetupPointLight(int index, int visibleLightIndex, ref VisibleLight visibleLight)
        {
            otherLightColors[index] = visibleLight.finalColor;

            Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
            // attenuation = max(0 , sqrt(1 - sqrt(sqrt(d)/sqrt(r))));
            // 在这里计算并存储片元不相关的步骤 1 / sqrt(r);
            position.w = 1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
            otherLightPositions[index] = position;

            // 给一个默认值1，防止shader中计算spot衰减为0，导致点光源强度为0
            otherLightSpotsCone[index] = new Vector4(0f, 1f);

            var light = visibleLight.light;
            // 存储点光源阴影数据
            otherLightShadowData[index] = shadows.ReserveOtherShadows(light, visibleLightIndex);

            var dirAndMask = Vector4.zero;
            dirAndMask.w = light.renderingLayerMask.ReinterpreaAsFloat();
            otherLightDirectionsAndMasks[index] = dirAndMask;
        }

        /// <summary>
        /// 设置聚光灯属性
        /// </summary>
        /// <param name="index"></param>
        /// <param name="visibleLight"></param>
        private void SetupSpotLight(int index, int visibleLightIndex, ref VisibleLight visibleLight)
        {
            otherLightColors[index] = visibleLight.finalColor;

            Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
            // attenuation = max(0 , sqrt(1 - sqrt(sqrt(d)/sqrt(r))));
            // 在这里计算并存储片元不相关的步骤 1 / sqrt(r);
            position.w = 1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
            otherLightPositions[index] = position;

            // 光锥范围计算相关，用于shader中计算衰减
            // Square(saturate(d*a+b))
            // d:dot(lightDir,lightDir2Frag)
            // a:1 / (cos(ri/2) - cos(ro/2))
            // b:-cos(ro/2)*a
            var light = visibleLight.light;
            var innerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.innerSpotAngle);
            var outerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * visibleLight.spotAngle);
            var angleRngInv = 1f / Mathf.Max(innerCos - outerCos, 0.001f);
            otherLightSpotsCone[index] = new Vector4(angleRngInv, -outerCos * angleRngInv);
            // 存储聚光灯阴影数据
            otherLightShadowData[index] = shadows.ReserveOtherShadows(light, visibleLightIndex);

            // 获取渲染层级掩码
            var dirAndMask = -visibleLight.localToWorldMatrix.GetColumn(2);
            dirAndMask.w = light.renderingLayerMask.ReinterpreaAsFloat();
            otherLightDirectionsAndMasks[index] = dirAndMask;
        }

        internal void Cleanup()
        {
            shadows.Cleanup();
        }
    }
}