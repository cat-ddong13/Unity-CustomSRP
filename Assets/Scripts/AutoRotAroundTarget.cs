using System.Collections;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.Rendering;

public class AutoRotAroundTarget : MonoBehaviour
{
    public bool rot = false;
    public GameObject target;
    public float angleSpeed = 0.1f;

    void Update()
    {
        if (!rot)
            return;

        if (null == target)
            return;

        this.transform.RotateAround(target.transform.position, Vector3.up, angleSpeed);
    }

    [Button("LookAt Target")]
    private void LookAk()
    {
        if (null == target)
        {
            return;
        }

        this.transform.position = target.transform.position - Vector3.forward*0.5f + Vector3.up * 1.5f;
    }


    public RenderPipelineAsset custom; 
    
    [Button("切换自定义管线")]
    public void ChangePipeline()
    {
        GraphicsSettings.renderPipelineAsset = custom;
        QualitySettings.renderPipeline = custom;
    }

    [Button("切换原生管线")]
    public void BuildinPipeline()
    {
        GraphicsSettings.renderPipelineAsset = null;
        QualitySettings.renderPipeline = null;
    }
}