using UnityEngine;

public class BoneAutoMove : MonoBehaviour
{
    public Vector3 moveRange = new Vector3(0.1f, .1f, .1f);
    private int rotDir = 1;
    public int doFrameCount = 100;

    public void Update()
    {
        if (Time.frameCount % doFrameCount == 0)
        {
            rotDir = -rotDir;
        }

        this.transform.Rotate(rotDir * moveRange / doFrameCount);
    }
}