using System;
using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.Rendering;
using Random = UnityEngine.Random;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    private static int baseColorId = Shader.PropertyToID("_BaseColor");
    private static int cutoffId = Shader.PropertyToID("_Cutoff");
    private static int matellicId = Shader.PropertyToID("_Matellic");
    private static int smoothnessId = Shader.PropertyToID("_Smoothness");
    private static int emissionColorId = Shader.PropertyToID("_EmissionColor");

    [OnValueChanged("UpdateShow")] [SerializeField]
    private Color baseColor = Color.white;

    [OnValueChanged("UpdateShow")] [SerializeField]
    private Color emissionColor1 = Color.black;

    [OnValueChanged("UpdateShow")] [SerializeField] [Range(0, 1)]
    private float cutoff = 0.5f;

    [OnValueChanged("UpdateShow")] [SerializeField] [Range(0, 1)]
    private float matellic = 0.5f;

    [OnValueChanged("UpdateShow")] [SerializeField] [Range(0, 1)]
    private float smoothness = 0.5f;


    private static MaterialPropertyBlock block;

    [ExecuteAlways]
    private void Awake()
    {
        UpdateShow();
    }

    private void OnValidate()
    {
        UpdateShow();
    }

    public void UpdateShow()
    {
        if (null == block)
        {
            block = new MaterialPropertyBlock();
        }

        block.SetFloat(matellicId, matellic);
        block.SetFloat(smoothnessId, smoothness);
        block.SetColor(baseColorId, baseColor);
        block.SetFloat(cutoffId, cutoff);
        block.SetColor(emissionColorId, emissionColor1);

        // this.transform.localScale = Vector3.one;
        GetComponent<Renderer>().SetPropertyBlock(block);
    }

    public void RdmValue()
    {
        var r = Random.Range(0, 256) / 255f;
        var g = Random.Range(0, 256) / 255f;
        var b = Random.Range(0, 256) / 255f;
        var a = Random.Range(100, 256) / 255f;
        cutoff = (float) Random.Range(0, 100) * 0.01f;
        baseColor = new Color(r, g, b, a);
        matellic = UnityEngine.Random.Range(30, 95) * 0.01f;
        smoothness = UnityEngine.Random.Range(30, 95) * 0.01f;
        UpdateShow();
    }
}