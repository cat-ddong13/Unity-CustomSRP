using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.CusomSRP.Editor
{
    internal class CustomShaderGUI : ShaderGUI
    {
        public enum ShadowMode
        {
            On,
            Clip,
            Dither,
            Off
        }

        private MaterialEditor editor;
        private Object[] materials;
        private MaterialProperty[] properties;
        private bool showPresets = false;

        private bool HasProperty(string name) =>
            FindProperty(name, properties, false) != null;

        private bool HasPremultiplyAlpha => HasProperty("_PremultiplyAlpha");

        private bool Clipping
        {
            set => SetProperty("_Clipping", "_CLIPPING", value);
        }

        private bool PremultiplyAlpha
        {
            set => SetProperty("_PremultiplyAlpha", "_PREMULTIPLY_ALPHA", value);
        }

        private BlendMode SrcBlend
        {
            set => SetProperty("_SrcBlend", (float) value);
        }

        private BlendMode DstBlend
        {
            set => SetProperty("_DstBlend", (float) value);
        }

        private bool ZWrite
        {
            set => SetProperty("_ZWrite", value ? 1f : 0f);
        }

        private ShadowMode Shadows
        {
            set
            {
                if (SetProperty("_Shadows", (float) value))
                {
                    SetKeyword("_SHADOWS_CLIP", value == ShadowMode.Clip);
                    SetKeyword("_SHADOWS_DITHER", value == ShadowMode.Dither);
                }
            }
        }

        private RenderQueue RenderQueue
        {
            set
            {
                foreach (Material material in materials)
                {
                    material.renderQueue = (int) value;
                }
            }
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            EditorGUI.BeginChangeCheck();
            // materialEditor.PropertiesDefaultGUI(properties);

            base.OnGUI(materialEditor, properties);
            this.editor = materialEditor;
            this.materials = editor.targets;
            this.properties = properties;

            BakedEmission();

            EditorGUILayout.Space();
            showPresets = EditorGUILayout.Foldout(showPresets, "Presets", true);
            if (showPresets)
            {
                OpaquePreset();
                ClipPreset();
                FadePreset();
                TransparentPreset();
            }

            if (EditorGUI.EndChangeCheck())
            {
                SetShadowCasterPass();
                CopyLightingMappingProperties();
            }
        }

        private bool SetProperty(string name, float value)
        {
            var property = FindProperty(name, properties, false);
            if (null != property)
            {
                property.floatValue = value;
                return true;
            }

            return false;
        }

        private void SetProperty(string name, string keyword, bool enabled)
        {
            if (SetProperty(name, enabled ? 1f : 0f))
            {
                SetKeyword(keyword, enabled);
            }
        }

        private void SetKeyword(string keyword, bool enabled)
        {
            if (enabled)
            {
                foreach (Material material in materials)
                {
                    material.EnableKeyword(keyword);
                }
            }
            else
            {
                foreach (Material material in materials)
                {
                    material.DisableKeyword(keyword);
                }
            }
        }


        private bool PresetButton(string name)
        {
            if (GUILayout.Button(name))
            {
                editor.RegisterPropertyChangeUndo(name);
                return true;
            }

            return false;
        }

        private void OpaquePreset()
        {
            if (PresetButton("Opaque"))
            {
                Clipping = false;
                PremultiplyAlpha = false;
                SrcBlend = BlendMode.One;
                DstBlend = BlendMode.Zero;
                ZWrite = true;
                RenderQueue = RenderQueue.Geometry;
            }
        }

        private void ClipPreset()
        {
            if (PresetButton("Clip"))
            {
                Clipping = true;
                PremultiplyAlpha = false;
                SrcBlend = BlendMode.One;
                DstBlend = BlendMode.Zero;
                ZWrite = true;
                RenderQueue = RenderQueue.AlphaTest;
            }
        }

        private void FadePreset()
        {
            if (PresetButton("Fade"))
            {
                Clipping = false;
                PremultiplyAlpha = false;
                SrcBlend = BlendMode.SrcAlpha;
                DstBlend = BlendMode.OneMinusSrcAlpha;
                ZWrite = false;
                RenderQueue = RenderQueue.Transparent;
            }
        }

        private void TransparentPreset()
        {
            if (HasPremultiplyAlpha && PresetButton("Transparent"))
            {
                Clipping = false;
                PremultiplyAlpha = true;
                SrcBlend = BlendMode.One;
                DstBlend = BlendMode.OneMinusSrcAlpha;
                ZWrite = false;
                RenderQueue = RenderQueue.Transparent;
            }
        }

        private void SetShadowCasterPass()
        {
            var shadows = FindProperty("_Shadows", properties, false);
            if (null == shadows || shadows.hasMixedValue)
                return;

            var enabled = shadows.floatValue < (float) ShadowMode.Off;
            foreach (Material material in materials)
            {
                material.SetShaderPassEnabled("ShadowCaster", enabled);
            }
        }

        private void BakedEmission()
        {
            EditorGUI.BeginChangeCheck();
            editor.LightmapEmissionProperty();
            if (EditorGUI.EndChangeCheck())
            {
                foreach (Material material in materials)
                {
                    material.globalIlluminationFlags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                }
            }
        }

        private void CopyLightingMappingProperties()
        {
            var mainTex = FindProperty("_MainTex", properties, false);
            var baseMap = FindProperty("_BaseMap", properties, false);
            if (null != mainTex && null != baseMap)
            {
                mainTex.textureValue = baseMap.textureValue;
                mainTex.textureScaleAndOffset = baseMap.textureScaleAndOffset;
            }

            var color = FindProperty("_Color", properties, false);
            var baseColor = FindProperty("_BaseColor", properties, false);
            if (null != color && null != baseColor)
            {
                color.colorValue = baseColor.colorValue;
            }
        }
    }
}