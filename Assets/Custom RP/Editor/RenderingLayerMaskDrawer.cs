using Rendering.CustomSRP.Runtime;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CusomSRP.Editor
{
    [CustomPropertyDrawer(typeof(RenderingLayerMaskFieldAttribute))]
    internal class RenderingLayerMaskDrawer : PropertyDrawer
    {
        public override void OnGUI(
            Rect position, SerializedProperty property, GUIContent label
        )
        {
            Draw(position, property, label);
        }

        internal static void Draw(SerializedProperty property, GUIContent label)
        {
            Draw(EditorGUILayout.GetControlRect(), property, label);
        }

        internal static void Draw(Rect position, SerializedProperty property, GUIContent label)
        {
            EditorGUI.showMixedValue = property.hasMultipleDifferentValues;
            EditorGUI.BeginChangeCheck();
            var mask = property.intValue;
            var isUInt = property.type == "uint";
            if (isUInt && mask == int.MaxValue)
                mask = -1;
            mask = EditorGUI.MaskField(position, label, mask,
                GraphicsSettings.currentRenderPipeline?.renderingLayerMaskNames);

            if (EditorGUI.EndChangeCheck())
            {
                property.intValue = isUInt && mask == -1 ? int.MaxValue : mask;
            }

            EditorGUI.showMixedValue = false;
        }
    }
}