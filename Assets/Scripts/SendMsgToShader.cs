using UnityEngine;

[ExecuteAlways]
public class SendMsgToShader : MonoBehaviour
{
    void Update()
    {
        var rd = this.transform.GetComponent<Renderer>();
        if (null == rd)
            return;
        
        var mat = rd.sharedMaterial;
        if (null == mat)
            return;

        mat.SetVector("_FrontNormal",
            this.transform.forward);
        mat.SetVector("_LeftNormal",
            -this.transform.right);
        mat.SetFloat("_FrameCount", Time.frameCount);
    }
}