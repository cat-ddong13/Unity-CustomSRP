using Sirenix.OdinInspector;
using UnityEngine;
using Random = UnityEngine.Random;

public class MultiObjectsCreater : MonoBehaviour
{
    public Vector3 area;
    public int num;
    public GameObject sourceObj;

    [Button("生成")]
    public void Create()
    {
        for (int i = 0; i < num; i++)
        {
            var x = Random.Range(0, area.x ) - area.x * 0.5f;
            var y = Random.Range(0, area.y ) - area.y * 0.5f;
            var z = Random.Range(0, area.z ) - area.z * 0.5f;
            var obj = GameObject.Instantiate(sourceObj) as GameObject;
            obj.transform.SetParent(this.transform);
            obj.transform.localScale = Vector3.one;
            obj.transform.localPosition = new Vector3(x, y, z);

            obj.SetActive(true);
        }
    }

    [Button("清除")]
    public void Clear()
    {
        var childCount = this.transform.childCount;
        for (int i = childCount - 1; i >= 0; i--)
        {
            GameObject.DestroyImmediate(this.transform.GetChild(i).gameObject);
        }
    }

    [Button("变色")]
    public void Effective()
    {
        var objs = this.GetComponentsInChildren<PerObjectMaterialProperties>();
        if (null == objs)
            return;

        for (int i = 0; i < objs.Length; i++)
        {
            objs[i].RdmValue();
        }
    }
}