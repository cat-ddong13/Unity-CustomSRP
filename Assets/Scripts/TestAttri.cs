using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[AttributeUsage(AttributeTargets.Class)]
public class TestAttri : CustomEditor
{
    public TestAttri(System.Type a): base( a)
    {
        Debug.LogError("a = " + a);
    }
}
