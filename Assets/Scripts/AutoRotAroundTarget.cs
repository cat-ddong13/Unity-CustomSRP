using System.Collections;
using System.Collections.Generic;
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
}