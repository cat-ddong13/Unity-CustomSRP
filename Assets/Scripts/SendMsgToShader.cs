using UnityEngine;

[ExecuteAlways]
public class SendMsgToShader : MonoBehaviour
{
    void Update()
    {
        var mat = this.transform.GetComponent<SkinnedMeshRenderer>().sharedMaterial;
        if (null == mat)
            return;

        mat.SetVector("_FrontNormal",
            new Vector4(this.transform.forward.x, this.transform.forward.y, this.transform.forward.z, 0));
    }
}