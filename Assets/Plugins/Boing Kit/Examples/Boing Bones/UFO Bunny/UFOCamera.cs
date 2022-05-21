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

public class UFOCamera : MonoBehaviour
{
  public Transform Target;

  private Vector3 m_targetOffset;
  private Vector3Spring m_spring;

  void Start ()
  {
    if (Target == null)
      return;

    m_targetOffset = transform.position - Target.position;

    m_spring.Reset(transform.position);
  }
  
  void FixedUpdate()
  {
    if (Target == null)
      return;
    
    Vector3 positionTarget = Target.position + m_targetOffset;
    transform.position = m_spring.TrackExponential(positionTarget, 0.02f, Time.fixedDeltaTime);
  }
}
