using System;
using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.Rendering;

public partial class A
{
    public A()
    {
        Debug.LogError("构造函数A");
    }

    public  void Log()
    {
        Debug.LogError("B = " + B);
    }
}

public partial class A
{
    private static int b = 1;
    public static int B => b;

    static A()
    {
        Debug.LogError("静态构造函数A");
    }
}

public class Test : MonoBehaviour
{
    [Button("Test")]
    public void Test1()
    {
        Mesh mesh;
    }
}