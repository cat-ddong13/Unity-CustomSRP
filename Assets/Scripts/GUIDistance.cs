using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class GUIDistance : MonoBehaviour
{
    public GameObject target;
    public Rect rect;

    private void OnGUI()
    {
        if (null == target)
            return;

        GUI.Label(rect, $"distance = {Vector3.Distance(this.transform.position, target.transform.position)}");
    }
}