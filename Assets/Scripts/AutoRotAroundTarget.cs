using System.Collections;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;

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
}