/******************************************************************************/
/*
  Project   - Boing Kit
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

using BoingKit;
using UnityEngine;

public class JellyfishUFOCamera : MonoBehaviour
{
  public Transform Target;

  private Vector3Spring m_spring;

  void Start()
  {
    if (Target == null)
      return;

    m_spring.Reset(Target.transform.position);
  }

  void FixedUpdate()
  {
    if (Target == null)
      return;

    m_spring.TrackExponential(Target.transform.position, 0.5f, Time.fixedDeltaTime);

    Vector3 lookDir = (m_spring.Value - transform.position).normalized;
    transform.rotation = Quaternion.LookRotation(lookDir);
  }
}
