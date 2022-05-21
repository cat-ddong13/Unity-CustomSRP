/******************************************************************************/
/*
  Project   - Boing Kit
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

using UnityEngine;

public class Spinner : MonoBehaviour
{
  public float Speed;

  private float m_angle;

  public void OnEnable()
  {
    m_angle = Random.Range(0.0f, 360.0f);
  }

  public void Update()
  {
    m_angle += Speed * 360.0f * Time.deltaTime;
    transform.rotation = Quaternion.Euler(0.0f, -m_angle, 0.0f);
  }
}
