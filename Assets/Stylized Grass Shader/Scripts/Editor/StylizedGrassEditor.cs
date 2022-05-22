using UnityEditor;
using UnityEngine;
#if URP
using UnityEngine.Rendering.Universal;
#endif

namespace StylizedGrass
{
    public class StylizedGrassEditor : Editor
    {
        [MenuItem("GameObject/Effects/Grass Bender")]
        public static void CreateGrassBender()
        {
            GrassBender gb = new GameObject().AddComponent<GrassBender>();
            gb.gameObject.name = "Grass Bender";

            Selection.activeGameObject = gb.gameObject;
            EditorApplication.ExecuteMenuItem("GameObject/Move To View");
        }

        #region Context menus
        [MenuItem("CONTEXT/MeshFilter/Attach grass bender")]
        public static void ConvertMeshToBender(MenuCommand cmd)
        {
            MeshFilter mf = (MeshFilter)cmd.context;
            MeshRenderer mr = mf.gameObject.GetComponent<MeshRenderer>();

            if (!mf.gameObject.GetComponent<GrassBender>())
            {
                GrassBender bender = mf.gameObject.AddComponent<GrassBender>();

                bender.benderType = GrassBenderBase.BenderType.Mesh;
                bender.meshFilter = mf;
                bender.meshRenderer = mr;

            }
        }

        [MenuItem("CONTEXT/TrailRenderer/Attach grass bender")]
        public static void ConvertTrailToBender(MenuCommand cmd)
        {
            TrailRenderer t = (TrailRenderer)cmd.context;

            if (!t.gameObject.GetComponent<GrassBender>())
            {
                GrassBender bender = t.gameObject.AddComponent<GrassBender>();

                bender.benderType = GrassBenderBase.BenderType.Trail;
                bender.trailRenderer = t;
            }
        }

        [MenuItem("CONTEXT/ParticleSystem/Attach grass bender")]
        public static void ConvertParticleToBender(MenuCommand cmd)
        {
            ParticleSystem ps = (ParticleSystem)cmd.context;

            if (!ps.gameObject.GetComponent<GrassBender>())
            {
                GrassBender bender = ps.gameObject.AddComponent<GrassBender>();

                bender.benderType = GrassBenderBase.BenderType.ParticleSystem;
                bender.particleSystem = ps.GetComponent<ParticleSystem>();

                GrassBenderBase.ValidateParticleSystem(bender);
            }

        }
        
        [MenuItem("CONTEXT/LineRenderer/Attach grass bender")]
        public static void ConvertLineToBender(MenuCommand cmd)
        {
            LineRenderer line = (LineRenderer)cmd.context;

            if (!line.gameObject.GetComponent<GrassBender>())
            {
                GrassBender bender = line.gameObject.AddComponent<GrassBender>();

                bender.benderType = GrassBenderBase.BenderType.Line;
                bender.lineRenderer = line.GetComponent<LineRenderer>();

                GrassBenderBase.ValidateParticleSystem(bender);
            }

        }
        #endregion
    }
}