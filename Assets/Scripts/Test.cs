using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.Rendering;

public class C
{
    public int c;
}

public class A
{
    public int a1;
    public string a2;
    public C a3;
}

public struct B
{
    public int b1;
    public string b2;
    public C b3;
}

public enum Aaaa
{
}

public class Test : MonoBehaviour
{
    [Button("Test")]
    public void Test1()
    {
    }
}