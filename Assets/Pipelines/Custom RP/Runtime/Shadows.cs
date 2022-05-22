using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    internal class Shadows
    {
        /// <summary>
        /// 平行光阴影数据
        /// </summary>
        private struct ShadowedDirectionalLight
        {
            // 可见光索引
            public int visibleLightIndex;

            // 用于阴影的深度偏移
            public float slopeBias;

            // 相机近裁剪面偏移
            public float nearPlaneOffset;
        }

        /// <summary>
        /// 其余光源阴影数据
        /// </summary>
        private struct ShadowedOtherLight
        {
            // 可见光索引
            public int visibleLightIndex;

            // 用于阴影的深度偏移
            public float slopeBias;

            // 法线偏移
            public float normalBias;

            // 光源类型
            public LightType lightType;
        }

        // 阴影的缓冲区名
        private const string BUFFER_NAME = "Shadows";

        // 最大平行光阴影数
        private const int MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT = 4;

        // 最大其余光源阴影数
        private const int MAX_SHADOWED_OTHER_LIGHT_COUNT = 16;

        // 最大阴影级联数
        private const int MAX_SHADOW_CASCADES = 4;

        // 命令缓冲区
        private CommandBuffer buffer = new CommandBuffer() {name = BUFFER_NAME};

        // 渲染内容(定义渲染状态和渲染命令)
        private ScriptableRenderContext context = default;

        // 裁剪结果
        private CullingResults cullingResults = default;
        
        // 平行光阴影数据
        private ShadowedDirectionalLight[] shadowedDirectionalLights =
            new ShadowedDirectionalLight[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT];

        // 其余光源阴影数据
        private ShadowedOtherLight[] shadowedOtherLights = new ShadowedOtherLight[MAX_SHADOWED_OTHER_LIGHT_COUNT];

        // 非平行光阴影瓦片索引
        private Vector4[] otherShadowTiles = new Vector4[MAX_SHADOWED_OTHER_LIGHT_COUNT];

        // 阴影级联数据
        private static Vector4[] cascadeData = new Vector4[MAX_SHADOW_CASCADES];

        // 平行光阴影空间矩阵
        private static Matrix4x4[] dirShadowMatrices =
            new Matrix4x4[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_SHADOW_CASCADES];

        private static Matrix4x4[] otherShadowMatrices = new Matrix4x4[MAX_SHADOWED_OTHER_LIGHT_COUNT];

        // 阴影级联裁剪球体
        private static Vector4[] cascadeCullingSphere = new Vector4[MAX_SHADOW_CASCADES];

        internal static Vector4[] CascadeCullingSpheres
        {
            get => cascadeCullingSphere;
        }

        // 阴影遮罩开关
        private bool enableShadowMask = false;

        // 阴影设置
        private ShadowSettings shadowSettings = default;
        private int shadowedDirectionalLightCount = 0;
        private int shadowedOtherLightCount = 0;
        private Vector4 shadowsAtlasSize = Vector4.zero;

        internal void Setup(ScriptableRenderContext context, CullingResults cullingResults,
            ShadowSettings shadowSettings)
        {
            this.context = context;
            this.cullingResults = cullingResults;
            this.shadowSettings = shadowSettings;
            this.shadowedDirectionalLightCount = 0;
            this.shadowedOtherLightCount = 0;
            this.enableShadowMask = false;
            this.shadowsAtlasSize = Vector4.zero;
        }

        /// <summary>
        /// 存储平行光阴影数据
        /// </summary>
        /// <param name="light"></param>
        /// <param name="visibleLightIndex"></param>
        /// <returns></returns>
        internal Vector4 ReserveDirectionalShadows(Light light, int visibleLightIndex)
        {
            // 屏蔽超过数量的
            if (shadowedDirectionalLightCount >= MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT)
                return new Vector4(0f, 0f, 0f, -1);

            // 屏蔽无阴影的平行光
            if (light.shadows == LightShadows.None || light.shadowStrength <= 0)
                return new Vector4(0f, 0f, 0f, -1);

            var maskChannel = -1;

            // 判断是否开启阴影遮罩
            var lightBaking = light.bakingOutput;
            if (lightBaking.lightmapBakeType == LightmapBakeType.Mixed &&
                lightBaking.mixedLightingMode == MixedLightingMode.Shadowmask)
            {
                enableShadowMask = true;
                maskChannel = lightBaking.occlusionMaskChannel;
            }

            // 如果可见光不影响物体，则依旧返回可见光强度（用于烘焙阴影的强度设置）
            if (!cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds bounds))
            {
                // 当可见光并不影响物体，但阴影强度>0时，shader中依旧会去采样阴影贴图
                // 为了避免这一步的消耗，将强度设为负值传递(我们可以在计算烘焙阴影使用它时再还原)
                return new Vector4(-light.shadowStrength, 0f, 0f, maskChannel);
            }

            // 存储当前平行光阴影相关数据
            shadowedDirectionalLights[shadowedDirectionalLightCount] = new ShadowedDirectionalLight()
            {
                visibleLightIndex = visibleLightIndex,
                slopeBias = light.shadowBias,
                nearPlaneOffset = light.shadowNearPlane,
            };

            // x:光的阴影强度 y:使用的阴影贴图的索引级别 z:阴影法线偏移 w:阴影遮罩通道
            return new Vector4(
                light.shadowStrength,
                shadowSettings.Directionals.CascadeCount * shadowedDirectionalLightCount++,
                light.shadowNormalBias,
                maskChannel);
        }

        /// <summary>
        /// 存储其他灯光数据
        /// </summary>
        /// <param name="light"></param>
        /// <param name="visibleLightIndex"></param>
        /// <returns></returns>
        internal Vector4 ReserveOtherShadows(Light light, int visibleLightIndex)
        {
            if (light.shadows == LightShadows.None || light.shadowStrength <= 0)
                return new Vector4(0f, 0f, 0f, -1f);

            var maskChannel = -1;
            var lightBaking = light.bakingOutput;
            // 判断是否需要开启非平行光的阴影遮罩
            if (lightBaking.lightmapBakeType == LightmapBakeType.Mixed &&
                lightBaking.mixedLightingMode == MixedLightingMode.Shadowmask)
            {
                maskChannel = lightBaking.occlusionMaskChannel;
                enableShadowMask = true;
            }

            var newLightCount = shadowedOtherLightCount + (light.type == LightType.Point ? 6 : 1);

            if (newLightCount > MAX_SHADOWED_OTHER_LIGHT_COUNT ||
                !cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b))
            {
                // 当可见光并不影响物体，但阴影强度>0时，shader中依旧会去采样阴影贴图
                // 为了避免这一步的消耗，将强度设为负值传递(我们可以在计算烘焙阴影使用它时再还原)
                return new Vector4(-light.shadowStrength, 0f, 0f, maskChannel);
            }

            shadowedOtherLights[shadowedOtherLightCount] = new ShadowedOtherLight()
            {
                visibleLightIndex = visibleLightIndex,
                slopeBias = light.shadowBias,
                normalBias = light.shadowNormalBias,
                lightType = light.type
            };

            var shadowData = new Vector4(light.shadowStrength, shadowedOtherLightCount,
                light.type == LightType.Point ? 1f : 0f, maskChannel);
            shadowedOtherLightCount = newLightCount;
            return shadowData;
        }

        internal void Render()
        {
            //Note:
            //https://catlikecoding.com/unity/tutorials/custom-srp/directional-shadows
            //
            //However, not claiming a texture will lead to problems for WebGL 2.0
            //because it binds textures and samplers together.
            //When a material with our shader is loaded while a texture is missing it will fail,
            //because it'll get a default texture which won't be compatible with a shadow sampler.
            //We could avoid this by introducing a shader keyword to
            //generate shader variants that omit the shadow sampling code.
            //An alternative approach is to instead get a 1×1 dummy texture
            //when no shadows are needed, avoiding extra shader variants.
            if (shadowedDirectionalLightCount > 0)
            {
                RenderDirectionalShadows();
            }
            else
            {
                // 获取临时的render texture
                buffer.GetTemporaryRT(ShadowsPropertyIDs.dirShadowAtlasId, 1, 1, 32, FilterMode.Bilinear,
                    RenderTextureFormat.Shadowmap);
            }

            if (shadowedOtherLightCount > 0)
            {
                RenderOtherShadows();
            }
            else
            {
                // 简单的取用dir的图集
                buffer.SetGlobalTexture(ShadowsPropertyIDs.otherShadowAtlasId, ShadowsPropertyIDs.dirShadowAtlasId);
            }

            buffer.BeginSample(BUFFER_NAME);

            var directional = shadowSettings.Directionals;

            // 设置全局阴影级联数
            // 当没有平行光阴影时，将级联设置为0，防止无平行光但有其余光源的情况去计算级联
            buffer.SetGlobalInt(ShadowsPropertyIDs.cascadeCountId, shadowedDirectionalLightCount > 0 ? directional.CascadeCount : 0);

            // 设置全局阴影过度比率（随距离）
            var f = 1f - directional.CascadeFadeRatio;
            buffer.SetGlobalVector(ShadowsPropertyIDs.shadowDistanceFadeId,
                new Vector4(1f / shadowSettings.MaxDistance, 1f / shadowSettings.DistanceFadeRatio
                    , 1f / (1f - f * f)));

            // 设置阴影图集大小
            buffer.SetGlobalVector(ShadowsPropertyIDs.shadowsAtlasSizeId, shadowsAtlasSize);
            SetKeywords(CustomShaderKeywords.shadowMaskKeywords,
                enableShadowMask ? QualitySettings.shadowmaskMode == ShadowmaskMode.Shadowmask ? 0 : 1 : -1);

            buffer.EndSample(BUFFER_NAME);
            ExecuteBuffer();
        }

        private void RenderDirectionalShadows()
        {
            var directional = shadowSettings.Directionals;
            var atlasSize = (int) directional.AtlasSize;
            // 将阴影图集大小的xy设置为平行光阴影图集大小
            shadowsAtlasSize.x = atlasSize;
            shadowsAtlasSize.y = 1f / atlasSize;

            // 获取临时的rendertexture
            buffer.GetTemporaryRT(ShadowsPropertyIDs.dirShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear,
                RenderTextureFormat.Shadowmap);
            // 设置渲染目标到渲染纹理
            buffer.SetRenderTarget(ShadowsPropertyIDs.dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            // 清除渲染目标的深度缓冲
            buffer.ClearRenderTarget(true, false, Color.clear);
            // 启用阴影平坠
            buffer.SetGlobalFloat(ShadowsPropertyIDs.shadowPancakingId, 1f);
            buffer.BeginSample(BUFFER_NAME);
            ExecuteBuffer();

            // 瓦片数量=产生阴影的平行光数*阴影级联数 
            var tiles = shadowedDirectionalLightCount * directional.CascadeCount;
            // 根据tiles数量划分行列
            var split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4;
            // 瓦片尺寸 = 纹理尺寸 / 行列数
            var tileSize = atlasSize / split;

            // 循环渲染平行光阴影 
            for (int i = 0; i < shadowedDirectionalLightCount; i++)
            {
                RenderDirectionalShadow(i, split, tileSize);
            }

            // 设置全局阴影空间矩阵
            buffer.SetGlobalMatrixArray(ShadowsPropertyIDs.dirShadowMatricesId, dirShadowMatrices);
            // 设置全局阴影级联裁剪球体
            buffer.SetGlobalVectorArray(ShadowsPropertyIDs.cascadeCullingSphereId, cascadeCullingSphere);
            // 设置全局阴影级联数据
            buffer.SetGlobalVectorArray(ShadowsPropertyIDs.cascadeDataId, cascadeData);

            // 设置级联融合数据
            SetKeywords(CustomShaderKeywords.cascadeBlendKeyWords, (int) (directional.BlendMode - 1));
            // 设置平行光滤波器数据
            SetKeywords(CustomShaderKeywords.directionalFilterKeywords, (int) (directional.FilterMode - 1));

            buffer.EndSample(BUFFER_NAME);
            ExecuteBuffer();
        }

        /// <summary>
        /// 渲染平行光阴影
        /// </summary>
        /// <param name="index"></param>
        /// <param name="split"></param>
        /// <param name="tileSize"></param>
        private void RenderDirectionalShadow(int index, int split, int tileSize)
        {
            var directional = shadowSettings.Directionals;
            // 根据索引获取上一步设置好的平行光阴影数据
            var light = shadowedDirectionalLights[index];
            // 创建阴影绘制设置
            var shadowDrawingSettings = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex)
            {
                useRenderingLayerMaskTest = true
            };
            // 获取各级联比率
            var cascadeRatios = directional.CascadeRatios;
            // 获取级联数量
            var cascadeCount = directional.CascadeCount;
            // 瓦片偏移量
            var tileOffset = index * cascadeCount;
            // 阴影级联融合的裁剪因子
            var cullingFactor = Mathf.Max(0f, 0.8f - directional.CascadeFadeRatio);
            var scale = 1f / split;

            // 循环设置级联相关 
            for (int i = 0; i < cascadeCount; i++)
            {
                // 计算平行光阴影空间矩阵和裁剪图元
                cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives
                (light.visibleLightIndex, i, cascadeCount, cascadeRatios, tileSize, light.nearPlaneOffset,
                    out Matrix4x4 viewMatrix,
                    out Matrix4x4 projMatrix, out ShadowSplitData shadowSplitData);

                // 设置阴影级联融合裁剪因子
                shadowSplitData.shadowCascadeBlendCullingFactor = cullingFactor;
                // 设置分割后的阴影数据
                shadowDrawingSettings.splitData = shadowSplitData;
                // 设置级联数据
                if (index == 0)
                {
                    SetCascadeData(i, shadowSplitData.cullingSphere, tileSize);
                }

                var tileIndex = tileOffset + i;
                dirShadowMatrices[tileIndex] =
                    ConvertToAtlasMatrix(projMatrix * viewMatrix, SetTileViewport(tileIndex, split, tileSize), scale);

                buffer.SetViewProjectionMatrices(viewMatrix, projMatrix);
                buffer.SetGlobalDepthBias(0, light.slopeBias);

                ExecuteBuffer();

                context.DrawShadows(ref shadowDrawingSettings);
                buffer.SetGlobalDepthBias(0f, 0f);
            }
        }

        /// <summary>
        /// 渲染非平行光阴影
        /// </summary>
        private void RenderOtherShadows()
        {
            var other = shadowSettings.Others;
            var atlasSize = (int) other.AtlasSize;
            // 将阴影图集大小的z设置为非平行光源阴影图集大小
            // w 设置为纹素大小
            shadowsAtlasSize.z = atlasSize;
            shadowsAtlasSize.w = 1f / atlasSize;
            buffer.GetTemporaryRT(ShadowsPropertyIDs.otherShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear,
                RenderTextureFormat.Shadowmap);
            buffer.SetRenderTarget(ShadowsPropertyIDs.otherShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            buffer.ClearRenderTarget(true, false, Color.clear);
            // 关闭阴影平坠
            buffer.SetGlobalFloat(ShadowsPropertyIDs.shadowPancakingId, 0f);
            buffer.BeginSample(BUFFER_NAME);
            ExecuteBuffer();

            var tiles = shadowedOtherLightCount;
            var split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4;
            var tileSize = atlasSize / split;

            for (int i = 0; i < shadowedOtherLightCount;)
            {
                if (shadowedOtherLights[i].lightType == LightType.Point)
                {
                    RenderPointShadow(i, split, tileSize);
                    i += 6;
                }
                else
                {
                    RenderSpotShadow(i, split, tileSize);
                    i += 1;
                }
            }

            // 传递非平行光的阴影图集矩阵
            buffer.SetGlobalMatrixArray(ShadowsPropertyIDs.otherShadowAtlasMatricesId, otherShadowMatrices);
            // 传递非平行光的阴影图集瓦片索引
            buffer.SetGlobalVectorArray(ShadowsPropertyIDs.otherShadowTilesId, otherShadowTiles);

            SetKeywords(CustomShaderKeywords.otherFilterKeywords, (int) other.FilterMode - 1);
            buffer.EndSample(BUFFER_NAME);
            ExecuteBuffer();
        }

        /// <summary>
        /// 渲染点光源
        /// (点光源被划分为6个光源空间)
        /// (可以简单的将点光源想象为立方体六个面对应方向上视角90°的聚光灯)
        /// </summary>
        /// <param name="index"></param>
        /// <param name="split"></param>
        /// <param name="tileSize"></param>
        private void RenderPointShadow(int index, int split, int tileSize)
        {
            var light = shadowedOtherLights[index];
            var shadowDrawingSettings = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex)
            {
                useRenderingLayerMaskTest = true
            };
            var other = shadowSettings.Others;

            var tileScale = 1f / split;
            var texelSize = 2f / tileSize;
            var filterSize = texelSize * (float) (other.FilterMode + 1);
            var bias = light.normalBias * filterSize * 1.4142136f;
            var fovBias = Mathf.Atan(1f + bias + filterSize) * Mathf.Rad2Deg * 2f - 90f;
            for (int i = 0; i < 6; i++)
            {
                cullingResults.ComputePointShadowMatricesAndCullingPrimitives(light.visibleLightIndex, (CubemapFace) i,
                    fovBias,
                    out Matrix4x4 viewMatrix,
                    out Matrix4x4 projMatrix, out ShadowSplitData shadowSplitData);

                // 点光源绘制三角形顶点的顺序是反向的，需要反转一下
                viewMatrix.m11 = -viewMatrix.m11;
                viewMatrix.m12 = -viewMatrix.m12;
                viewMatrix.m13 = -viewMatrix.m13;

                shadowDrawingSettings.splitData = shadowSplitData;

                var tileIndex = index + i;

                var offset = SetTileViewport(tileIndex, split, tileSize);

                SetOtherShadowTileData(tileIndex, bias, tileScale, offset);
                otherShadowMatrices[tileIndex] =
                    ConvertToAtlasMatrix(projMatrix * viewMatrix, offset, tileScale);
                buffer.SetViewProjectionMatrices(viewMatrix, projMatrix);
                buffer.SetGlobalDepthBias(0f, light.slopeBias);
                ExecuteBuffer();
                context.DrawShadows(ref shadowDrawingSettings);
                buffer.SetGlobalDepthBias(0f, 0f);
            }
        }

        private void RenderSpotShadow(int index, int split, int tileSize)
        {
            var light = shadowedOtherLights[index];
            var shadowDrawingSettings = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex)
            {
                useRenderingLayerMaskTest = true
            };
            var other = shadowSettings.Others;

            cullingResults.ComputeSpotShadowMatricesAndCullingPrimitives(light.visibleLightIndex,
                out Matrix4x4 viewMatrix,
                out Matrix4x4 projMatrix, out ShadowSplitData shadowSplitData);

            var texelSize = 2f / (tileSize * projMatrix.m00);
            var filterSize = texelSize * (float) (other.FilterMode + 1);
            var bias = light.normalBias * filterSize * 1.4142136f;

            var offset = SetTileViewport(index, split, tileSize);
            var tileScale = 1f / split;

            SetOtherShadowTileData(index, bias, tileScale, offset);

            shadowDrawingSettings.splitData = shadowSplitData;
            otherShadowMatrices[index] =
                ConvertToAtlasMatrix(projMatrix * viewMatrix, offset, tileScale);
            buffer.SetViewProjectionMatrices(viewMatrix, projMatrix);
            buffer.SetGlobalDepthBias(0f, light.slopeBias);
            ExecuteBuffer();
            context.DrawShadows(ref shadowDrawingSettings);
            buffer.SetGlobalDepthBias(0f, 0f);
        }

        private void SetKeywords(string[] keyWords, int enabledIndex)
        {
            for (int i = 0; i < keyWords.Length; i++)
            {
                if (i == enabledIndex)
                {
                    buffer.EnableShaderKeyword(keyWords[i]);
                }
                else
                {
                    buffer.DisableShaderKeyword(keyWords[i]);
                }
            }
        }

        /// <summary>
        /// 设置级联数据
        /// </summary>
        /// <param name="index"></param>
        /// <param name="cullingSphere"></param>
        /// <param name="tileSize"></param>
        private void SetCascadeData(int index, Vector4 cullingSphere, float tileSize)
        {
            // 纹素大小
            var texelSize = 2f * cullingSphere.w / tileSize;
            // 增加滤波器采样级别(FilterMode)会采样到原本不是阴影的地方从而导致阴影痤疮(shadow acne)再次出现
            // 因此需要在增强滤波器采样级别的同时，增强表面法线偏移量(沿表面法线‘扩张’)
            // (额外的)沿法线的偏移量 = 纹素大小 * 滤波级别
            var extraNormalBiasByFilterSize = texelSize * ((float) shadowSettings.Directionals.FilterMode + 1);
            // 从裁剪球体的直径上剔去除偏移量，防止未被覆盖的区域也被采集到
            cullingSphere.w -= extraNormalBiasByFilterSize;
            // 存储直径的平方，防止在shader中计算
            // (因为只需要比较距离，所以直接使用平方进行比较可以避免消耗较大的开方操作)
            cullingSphere.w *= cullingSphere.w;
            // 存储阴影级联裁剪球体
            cascadeCullingSphere[index] = cullingSphere;
            // 最坏情况下，使用正方形的对角线尺度（*根号2）
            extraNormalBiasByFilterSize *= 1.4142136f;
            // 存储级联数据
            cascadeData[index] = new Vector4(1f / cullingSphere.w, extraNormalBiasByFilterSize);
        }

        /// <summary>
        /// 设置分割后的阴影瓦片的视口参数
        /// </summary>
        /// <param name="index"></param>
        /// <param name="split"></param>
        /// <param name="tileSize"></param>
        /// <returns></returns>
        private Vector2 SetTileViewport(int index, int split, int tileSize)
        {
            if (split <= 0)
            {
                Debug.LogError("split of shadow is invalid!");
                return Vector2.zero;
            }

            // 偏移量
            var offset = new Vector2(index % split, index / split);
            // 设置视口
            buffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
            return offset;
        }

        private void SetOtherShadowTileData(int index, float bias, float scale, Vector2 offset)
        {
            var border = shadowsAtlasSize.w * 0.5f;
            var data = Vector4.zero;
            data.x = offset.x * scale + border;
            data.y = offset.y * scale + border;
            data.z = scale - border - border;
            data.w = bias;
            otherShadowTiles[index] = data;
        }

        /// <summary>
        /// 将光源空间矩阵转为阴影贴图空间矩阵
        /// </summary>
        /// <param name="matrix"></param>
        /// <param name="offset"></param>
        /// <param name="split"></param>
        /// <returns></returns>
        private Matrix4x4 ConvertToAtlasMatrix(Matrix4x4 matrix, Vector2 offset, float scale)
        {
            // 存在Z反转
            if (SystemInfo.usesReversedZBuffer)
            {
                matrix.m20 = -matrix.m20;
                matrix.m21 = -matrix.m21;
                matrix.m22 = -matrix.m22;
                matrix.m23 = -matrix.m23;
            }

            matrix.m00 = (0.5f * (matrix.m00 + matrix.m30) + offset.x * matrix.m30) * scale;
            matrix.m01 = (0.5f * (matrix.m01 + matrix.m31) + offset.x * matrix.m31) * scale;
            matrix.m02 = (0.5f * (matrix.m02 + matrix.m32) + offset.x * matrix.m32) * scale;
            matrix.m03 = (0.5f * (matrix.m03 + matrix.m33) + offset.x * matrix.m33) * scale;

            matrix.m10 = (0.5f * (matrix.m10 + matrix.m30) + offset.y * matrix.m30) * scale;
            matrix.m11 = (0.5f * (matrix.m11 + matrix.m31) + offset.y * matrix.m31) * scale;
            matrix.m12 = (0.5f * (matrix.m12 + matrix.m32) + offset.y * matrix.m32) * scale;
            matrix.m13 = (0.5f * (matrix.m13 + matrix.m33) + offset.y * matrix.m33) * scale;

            matrix.m20 = 0.5f * (matrix.m20 + matrix.m30);
            matrix.m21 = 0.5f * (matrix.m21 + matrix.m31);
            matrix.m22 = 0.5f * (matrix.m22 + matrix.m32);
            matrix.m23 = 0.5f * (matrix.m23 + matrix.m33);

            return matrix;
        }

        private void ExecuteBuffer()
        {
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        internal void Cleanup()
        {
            // 释放缓存render texture
            buffer.ReleaseTemporaryRT(ShadowsPropertyIDs.dirShadowAtlasId);
            if (ShadowsPropertyIDs.otherShadowAtlasId > 0)
            {
                buffer.ReleaseTemporaryRT(ShadowsPropertyIDs.otherShadowAtlasId);
            }

            ExecuteBuffer();
        }
    }
}