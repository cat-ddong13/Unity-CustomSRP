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

public class UFOEffector : MonoBehaviour
{
  private float m_radius;
  private float m_moveDistance;
  private float m_rotateAngle;

  public void Start()
  {
    var effector = GetComponent<BoingEffector>();

    m_radius = effector.Radius;
    m_moveDistance = effector.MoveDistance;
    m_rotateAngle = effector.RotationAngle;
  }

  public void FixedUpdate()
  {
    var effector = GetComponent<BoingEffector>();

    effector.Radius = m_radius * (1.0f + 0.2f * Mathf.Sin(11.0f * Time.time) * Mathf.Sin(7.0f * Time.time + 1.54f));
    effector.MoveDistance = m_moveDistance * (1.0f + 0.2f * Mathf.Sin(9.3f * Time.time + 5.19f) * Mathf.Sin(7.3f * Time.time + 4.73f));
    effector.RotationAngle = m_rotateAngle * (1.0f + 0.2f * Mathf.Sin(7.9f * Time.time + 2.97f) * Mathf.Sin(8.3f * Time.time + 0.93f));

    transform.localPosition = 
        Vector3.right   * 0.25f * Mathf.Sin(5.23f * Time.time + 9.87f) 
      + Vector3.forward * 0.25f * Mathf.Sin(4.93f * Time.time + 7.39f);
  }
}
