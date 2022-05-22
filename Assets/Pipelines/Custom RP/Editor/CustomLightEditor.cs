using UnityEditor;
using UnityEngine;
using Rendering.CusomSRP.Editor;
using Rendering.CustomSRP.Runtime;

namespace Rendering.CustomSRP.Editor
{
    [CanEditMultipleObjects]
    [CustomEditorForRenderPipeline(typeof(Light), typeof(CustomRenderPipelineAsset))]
    internal class CustomLightEditor : LightEditor
    {
        private static GUIContent renderingLayerMaskLabel =
            new GUIContent("Rendering Layer Mask", "Functional version of above property.");

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            RenderingLayerMaskDrawer.Draw(settings.renderingLayerMask, renderingLayerMaskLabel);

            if (!settings.lightType.hasMultipleDifferentValues &&
                (LightType) settings.lightType.enumValueIndex == LightType.Spot)
            {
                settings.DrawInnerAndOuterSpotAngle();
                settings.ApplyModifiedProperties();
            }

            settings.ApplyModifiedProperties();

            var light = target as Light;
            if (light.cullingMask != -1)
            {
                EditorGUILayout.HelpBox(
                    light.type == LightType.Directional
                        ? "Directional Light's Culling Mask only affects shadows."
                        : "Non-Directional Light's Culling Mask only affects shadow unless Use Lights Per Objects is on.",
                    MessageType.Info
                );
            }
        }
    }
}