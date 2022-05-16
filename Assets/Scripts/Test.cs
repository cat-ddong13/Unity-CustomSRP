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
        C c = new C();
        c.c = 3;

        A a = new A();
        a.a1 = 1;
        a.a2 = "a2";
        a.a3 = c;

        Dictionary<int, A> dicA = new Dictionary<int, A>();
        dicA.Add(a.a1, a);

        dicA[1].a1 = 2;

        B b = new B();
        b.b1 = 2;
        b.b2 = "b2";
        b.b3 = c;

        Dictionary<int, B> dicB = new Dictionary<int, B>();
        dicB.Add(b.b1, b);

        foreach (var item in dicA.Values)
        {
            item.a1 = 4;
            item.a2 = "a222";
            item.a3.c = 5;
        }

        b.b1 = 33;
        dicB[2] = b;
    }
}