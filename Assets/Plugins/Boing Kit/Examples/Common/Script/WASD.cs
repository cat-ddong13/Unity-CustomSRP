/******************************************************************************/
/*
  Project   - Boing Kit
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WASD : MonoBehaviour
{
  public float Speed = 1.0f;

  public Vector3 Velocity { get { return m_velocity; } }
  public Vector3 m_velocity;

  public void Update()
  {
    Vector3 moveDir = Vector3.zero;

    if (Input.GetKey(KeyCode.W))
      moveDir.z += 1.0f;

    if (Input.GetKey(KeyCode.A))
      moveDir.x -= 1.0f;

    if (Input.GetKey(KeyCode.S))
      moveDir.z -= 1.0f;

    if (Input.GetKey(KeyCode.D))
      moveDir.x += 1.0f;

    Vector3 moveVec =
      moveDir.sqrMagnitude > 0.0f
      ? moveDir.normalized * Speed * Time.deltaTime
      : Vector3.zero;

    m_velocity = moveVec / Time.deltaTime;

    transform.position += moveVec;
  }
}
