//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
#if URP
using UnityEngine.Rendering.Universal;

#if UNITY_2021_2_OR_NEWER
using ForwardRendererData = UnityEngine.Rendering.Universal.UniversalRendererData;
#endif
#endif
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace StylizedGrass
{
    public static class PipelineUtilities
    {
        private const string renderDataListFieldName = "m_RendererDataList";
        
#if URP
        /// <summary>
        /// Retrieves a ForwardRenderer asset in the project, based on name
        /// </summary>
        /// <param name="assetName"></param>
        /// <returns></returns>
        public static ForwardRendererData GetRenderer(string assetName)
        {
#if UNITY_EDITOR
            string[] GUIDs = AssetDatabase.FindAssets(assetName + " t:ForwardRendererData");

            if (GUIDs.Length == 0)
            {
                Debug.LogError("The <i>" + assetName + "</i> asset could not be found in the project. Was it renamed or not imported?");
                return null;
            }

            string assetPath = AssetDatabase.GUIDToAssetPath(GUIDs[0]);

            ForwardRendererData data = (ForwardRendererData)AssetDatabase.LoadAssetAtPath(assetPath, typeof(ForwardRendererData));

            return data;
#else
            Debug.LogError("StylizedGrass.PipelineUtilities.GetRenderer() cannot be called in a build, it requires AssetDatabase. References to renderers should be saved beforehand!");
            return null;
#endif
        }
        
        /// <summary>
        /// Checks if a ForwardRenderer has been assigned to the pipeline asset, if not it is added
        /// </summary>
        /// <param name="pass"></param>
        public static void ValidatePipelineRenderers(ScriptableRendererData pass)
        {
            if (pass == null)
            {
                Debug.LogError("Pass is null");
                return;
            }
            
            BindingFlags bindings = System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance;

            ScriptableRendererData[] m_rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).GetValue(UniversalRenderPipeline.asset);
            bool isPresent = false;
            
            for (int i = 0; i < m_rendererDataList.Length; i++)
            {
                if (m_rendererDataList[i] == pass) isPresent = true;
            }

            if (!isPresent)
            {
                AddRendererToPipeline(pass);
            }
            else
            {
                //Debug.Log("The " + AssetName + " ScriptableRendererFeature is assigned to the pipeline asset");
            }
        }
        
        private static void AddRendererToPipeline(ScriptableRendererData pass)
        {
            if (pass == null) return;

            BindingFlags bindings = System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance;

            ScriptableRendererData[] m_rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).GetValue(UniversalRenderPipeline.asset);
            List<ScriptableRendererData> rendererDataList = new List<ScriptableRendererData>();

            for (int i = 0; i < m_rendererDataList.Length; i++)
            {
                rendererDataList.Add(m_rendererDataList[i]);
            }
            rendererDataList.Add(pass);

            typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).SetValue(UniversalRenderPipeline.asset, rendererDataList.ToArray());

            //Debug.Log("The <i>" + DrawGrassBenders.AssetName + "</i> renderer is required and was automatically added to the \"" + UniversalRenderPipeline.asset.name + "\" pipeline asset");
        }

        public static void RemoveRendererFromPipeline(ScriptableRendererData pass)
        {
            if (pass == null) return;
            
            BindingFlags bindings = System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance;

            ScriptableRendererData[] m_rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).GetValue(UniversalRenderPipeline.asset);
            List<ScriptableRendererData> rendererDataList = new List<ScriptableRendererData>(m_rendererDataList);
            
            if(rendererDataList.Contains(pass)) rendererDataList.Remove((pass));
            
            typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).SetValue(UniversalRenderPipeline.asset, rendererDataList.ToArray());
        }

        public static void AssignRendererToCamera(UniversalAdditionalCameraData camData, ScriptableRendererData pass)
        {
            if (UniversalRenderPipeline.asset)
            {
                if (pass)
                {
                    //list is internal, so perform reflection workaround
                    ScriptableRendererData[] rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance).GetValue(UniversalRenderPipeline.asset);

                    for (int i = 0; i < rendererDataList.Length; i++)
                    {
                        if (rendererDataList[i] == pass) camData.SetRenderer(i);
                    }
                }
            }
            else
            {
                Debug.LogError("[StylizedGrassRenderer] No Universal Render Pipeline is currently active.");
            }
        }
#endif
    }
}
