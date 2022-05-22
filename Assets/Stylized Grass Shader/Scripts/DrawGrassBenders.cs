//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;
#if URP
using UnityEngine.Rendering.Universal;
#endif

namespace StylizedGrass
{
#if URP
    public class DrawGrassBenders : ScriptableRendererFeature
    {
        public DrawGrassBendersPass m_ScriptablePass;
        public static string AssetName = "GrassBendRenderer";

        public class DrawGrassBendersPass : ScriptableRenderPass
        {
            private const string profilerTag = "Draw Grass Benders";
            private ProfilingSampler profilerSampler;
            MaterialPropertyBlock props;

            public static RenderTargetIdentifier bendVectorRT;
            private int bendVectorID = Shader.PropertyToID(StylizedGrassRenderer.VECTOR_MAP_PARAM);
            private int bendMapInputID = Shader.PropertyToID("_BendMapInput");
            private int paramsID = Shader.PropertyToID("_Params");

            private Plane[] frustrumPlanes = new Plane[6];

            private Material m_MaskMat;
            private const string MASK_SHADER_NAME = "Hidden/Nature/Grass BendRenderer";
            
            private bool enableEdgeMasking;
            private bool trailEnabled;

            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                if (!m_MaskMat) m_MaskMat = new Material(Shader.Find(MASK_SHADER_NAME));
                
                enableEdgeMasking = false;
                if (StylizedGrassRenderer.Instance)
                {
                    enableEdgeMasking = StylizedGrassRenderer.Instance.maskEdges;
                }

                if (enableEdgeMasking)
                {
                    cmd.GetTemporaryRT(bendVectorID, cameraTextureDescriptor);
                    cmd.SetGlobalTexture(bendVectorID, bendVectorID);
                }

                //Note: may conflict with existing property blocks but this is an edge case
                if (props == null) props = new MaterialPropertyBlock();
                if(profilerSampler == null) profilerSampler = new ProfilingSampler(profilerTag);
            }

            private MeshRenderer m_MeshRenderer;
            private TrailRenderer m_TrailRenderer;
            private LineRenderer m_LineRenderer;
            private ParticleSystemRenderer m_ParticleRenderer;
            public ParticleSystem.ColorOverLifetimeModule m_ParticleRendererGrad;
            
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                var cmd = CommandBufferPool.Get(profilerSampler.name);

                GeometryUtility.CalculateFrustumPlanes(StylizedGrassRenderer.Instance.renderCam, frustrumPlanes);

                using (new ProfilingScope(cmd, profilerSampler))
                {
                    foreach (KeyValuePair<int, List<GrassBender>> layer in StylizedGrassRenderer.GrassBenders)
                    {
                        foreach (GrassBender b in layer.Value)
                        {
                            if (b.enabled == false) continue;

                            props.SetVector(paramsID, new Vector4(b.strength, b.heightOffset, b.pushStrength, b.scaleMultiplier));

                            if (b.benderType == GrassBenderBase.BenderType.Trail)
                            {
                                if (!b.trailRenderer) continue;

                                if (!b.trailRenderer.emitting) continue;

                                if (!GeometryUtility.TestPlanesAABB(frustrumPlanes, b.trailRenderer.bounds)) continue;

                                m_TrailRenderer = b.trailRenderer;
                                m_TrailRenderer.SetPropertyBlock(props);

                                //Trail
                                m_TrailRenderer.emitting = b.gameObject.activeInHierarchy;
                                m_TrailRenderer.generateLightingData = true;
                                m_TrailRenderer.widthMultiplier = b.trailRadius;
                                m_TrailRenderer.time = b.trailLifetime;
                                m_TrailRenderer.minVertexDistance = b.trailAccuracy;
                                m_TrailRenderer.widthCurve = b.widthOverLifetime;
                                m_TrailRenderer.colorGradient = GrassBenderBase.GetGradient(b.strengthOverLifetime);

                                //If disabled, temporarly enable in order to bake mesh
                                trailEnabled = m_TrailRenderer.enabled ? true : false;
                                if (!trailEnabled) m_TrailRenderer.enabled = true;

                                if (b.bakedMesh == null) b.bakedMesh = new Mesh();
                                m_TrailRenderer.BakeMesh(b.bakedMesh, renderingData.cameraData.camera, false);

                                cmd.DrawMesh(b.bakedMesh, Matrix4x4.identity, GrassBenderBase.TrailMaterial, 0, b.alphaBlending ? 1 : 0, props);

                                //Note: Faster, but crashed when trails are disabled (Case 1200430)
                                //cmd.DrawRenderer(m_TrailRenderer, GrassBenderBase.TrailMaterial, 0, 0);

                                if (!trailEnabled) m_TrailRenderer.enabled = false;

                                //trailMesh.Clear();
                            }
                            if (b.benderType == GrassBenderBase.BenderType.ParticleSystem)
                            {
                                if (!b.particleSystem) continue;

                                if (!GeometryUtility.TestPlanesAABB(frustrumPlanes, b.particleRenderer.bounds)) continue;

                                m_ParticleRenderer = b.particleRenderer;
                                m_ParticleRenderer.SetPropertyBlock(props);

                                var grad = b.particleSystem.colorOverLifetime;
                                grad.enabled = true;
                                grad.color = GrassBenderBase.GetGradient(b.strengthOverLifetime);
                                bool localSpace = b.particleSystem.main.simulationSpace == ParticleSystemSimulationSpace.Local;

                                //Note: DrawRenderes with particle systems appear to be broken. Only renders to scene cam when it redraws. Bake the mesh down and render it instead.
                                //Todo: Create repo project and file bug report. 
                                //cmd.DrawRenderer(m_ParticleRenderer, m_Material, 0, 0);
                                if (!b.bakedMesh) b.bakedMesh = new Mesh();
                                m_ParticleRenderer.BakeMesh(b.bakedMesh, renderingData.cameraData.camera);

                                cmd.DrawMesh(b.bakedMesh, localSpace ? m_ParticleRenderer.localToWorldMatrix : Matrix4x4.identity, GrassBenderBase.MeshMaterial, 0, b.alphaBlending ? 1 : 0, props);

                                //Also draw particle trails
                                if (b.hasParticleTrails)
                                {
                                    if (!b.particleTrailMesh) b.particleTrailMesh = new Mesh();

                                    m_ParticleRenderer.BakeTrailsMesh(b.particleTrailMesh, renderingData.cameraData.camera);
                                    cmd.DrawMesh(b.particleTrailMesh, localSpace ? m_ParticleRenderer.localToWorldMatrix : Matrix4x4.identity, GrassBenderBase.TrailMaterial, 1, b.alphaBlending ? 1 : 0, props);
                                    //cmd.DrawRenderer(m_ParticleRenderer, GrassBenderBase.TrailMaterial, 1, 0);
                                }
                            }
                            if (b.benderType == GrassBenderBase.BenderType.Mesh)
                            {
                                if (!b.meshRenderer) continue;

                                if (!GeometryUtility.TestPlanesAABB(frustrumPlanes, b.meshRenderer.bounds)) continue;

                                m_MeshRenderer = b.meshRenderer;
                                m_MeshRenderer.SetPropertyBlock(props);

                                cmd.DrawRenderer(m_MeshRenderer, GrassBenderBase.MeshMaterial, 0, b.alphaBlending ? 1 : 0);

                            }

                            if (b.benderType == GrassBenderBase.BenderType.Line)
                            {
                                if(b.lineRenderer == null) continue;
                                
                                if (!GeometryUtility.TestPlanesAABB(frustrumPlanes, b.lineRenderer.bounds)) continue;

                                m_LineRenderer = b.lineRenderer;
                                m_LineRenderer.SetPropertyBlock(props);
                                
                                if (b.bakedMesh == null) b.bakedMesh = new Mesh();
                                m_LineRenderer.BakeMesh(b.bakedMesh, renderingData.cameraData.camera, false);

                                cmd.DrawMesh(b.bakedMesh, m_LineRenderer.useWorldSpace ? Matrix4x4.identity : m_LineRenderer.transform.localToWorldMatrix, GrassBenderBase.TrailMaterial, 0, b.alphaBlending ? 1 : 0, props);
                                
                                //Again, flickers in scene view
                                //cmd.DrawRenderer(b.lineRenderer, GrassBenderBase.TrailMaterial, 0, 0);
                            }
                        }
                    }

                    //Mask edges of bend area, avoids streaking at edges
                    if (enableEdgeMasking)
                    {
                        cmd.SetGlobalTexture(bendMapInputID, BuiltinRenderTextureType.CurrentActive);
                        cmd.Blit(BuiltinRenderTextureType.CurrentActive, bendVectorID, m_MaskMat);
                        
                    }
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            /// Cleanup any allocated resources that were created during the execution of this render pass.
#if URP_9_0
            public override void OnCameraCleanup(CommandBuffer cmd)
#else
            public override void FrameCleanup(CommandBuffer cmd)
#endif
            {
                cmd.ReleaseTemporaryRT(bendVectorID);
            }
        }
        
        public override void Create()
        {
            m_ScriptablePass = new DrawGrassBendersPass();

            // Configures where the render pass should be injected.
            m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRendering;
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }
#endif
        }