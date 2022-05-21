/******************************************************************************/
/*
  Project   - Boing Kit
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

using System.Linq;

using BoingKit;

using UnityEngine;

public class SquashAndStretchComparison : MonoBehaviour
{
  public float Run = 11.0f;
  public float Period = 3.0f;
  public float Rest = 3.0f;

  public Transform BonesA;
  public Transform BonesB;

  private float m_timer;

  void Start ()
  {
    m_timer = 0.0f;
  }
  
  void FixedUpdate()
  {
    var aBonesA = BonesA.GetComponents<BoingBones>();
    var aBonesB = BonesB.GetComponents<BoingBones>();
    var aTransform = new Transform[] { BonesA.transform, BonesB.transform };
    var aBones = aBonesA.Concat(aBonesB);

    float dt = Time.fixedDeltaTime;
    float halfRun = 0.5f * Run;

    m_timer += dt;

    if (m_timer > Period + Rest)
    {
      m_timer = Mathf.Repeat(m_timer, Period + Rest);

      foreach (var tf in aTransform)
      {
        Vector3 pos = tf.position;
        pos.z = -halfRun;
        tf.position = pos;
      }

      foreach (var bones in aBones)
      {
        bones.Reboot();
      }
    }

    float p = Mathf.Min(1.0f, m_timer * MathUtil.InvSafe(Period));
    float t = 1.0f - Mathf.Pow(1.0f - p, 6.0f);

    foreach (var tf in aTransform)
    {
      Vector3 pos = tf.position;
      pos.z = Mathf.Lerp(-halfRun, halfRun, t);
      tf.position = pos;
    }
  }
}
