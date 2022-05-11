using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CustomSRP.Runtime
{
    internal class DrawGizmos : MonoBehaviour
    {
        internal MeshRenderer[] meshs = new MeshRenderer[4];
        internal MaterialPropertyBlock block;
        private static int baseColorId = Shader.PropertyToID("_BaseColor");

        private Vector4[] cullingSpheres = null;
        private bool show = true;

        [Button("显示/隐藏主相机阴影裁剪球体(CullingSpheres)")]
        internal void Show()
        {
            show = !show;
        }

        internal void DrawSphere()
        {
            if (!show)
            {
                for (int i = 0; i < meshs.Length; i++)
                {
                    meshs[i].gameObject.SetActive(false);
                }

                return;
            }

            cullingSpheres = Shadows.CascadeCullingSpheres;
            if (null == block)
                block = new MaterialPropertyBlock();

            for (int i = 0; i < cullingSpheres.Length; i++)
            {
                var cullingSphere = cullingSpheres[i];
                var mesh = meshs[i];
                if (cullingSphere.Equals(Vector4.zero))
                {
                    mesh.gameObject.SetActive(false);
                    continue;
                }

                if (i == 0)
                {
                    block.SetColor(baseColorId, new Color(0f, 1f, 0f, 0.2f));
                }
                else if (i == 1)
                {
                    block.SetColor(baseColorId, new Color(1f, 1f, 0f, 0.2f));
                }
                else if (i == 2)
                {
                    block.SetColor(baseColorId, new Color(1f, 0.5f, 1f, 0.2f));
                }
                else if (i == 3)
                {
                    block.SetColor(baseColorId, new Color(0f, 1f, 1f, 0.2f));
                }

                block.SetInt("_ZWrite", 0);
                // block.SetFloat("_CLIPPING", 0f);
                // block.SetFloat("_PremultiplyAlpha", 1f);
                // block.SetFloat("_Matellic", 0f);
                // block.SetFloat("_Smoothness", 0f);
                block.SetFloat("_SrcBlend", (float) BlendMode.SrcAlpha);
                block.SetFloat("_DstBlend", (float) BlendMode.OneMinusSrcAlpha);

                var position = new Vector3(cullingSphere.x, cullingSphere.y, cullingSphere.z);
                var scale = cullingSphere.w;
                scale = Mathf.Sqrt(scale);
                mesh.SetPropertyBlock(block);
                mesh.transform.localScale = Vector3.one * scale * 2;
                mesh.transform.position = position;
                mesh.gameObject.name = position + "_" + scale;
                mesh.gameObject.SetActive(true);
            }
        }
    }
}