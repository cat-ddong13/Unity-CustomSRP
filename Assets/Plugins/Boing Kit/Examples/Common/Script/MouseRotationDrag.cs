/******************************************************************************/
/*
  Project   - Squash And Stretch Kit
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

using UnityEngine;

public class MouseRotationDrag : MonoBehaviour
{
  private bool m_currFrameHasFocus;
  private bool m_prevFrameHasFocus;
  private Vector3 m_prevMousePosition;

  private Vector3 m_euler;

  void Start()
  {
    m_currFrameHasFocus = false;
    m_prevFrameHasFocus = false;
  }

  void Update()
  {
    m_currFrameHasFocus = Application.isFocused;
    bool prevFrameHasFocus = m_prevFrameHasFocus;
    m_prevFrameHasFocus = m_currFrameHasFocus;

    if (!prevFrameHasFocus && !m_currFrameHasFocus)
      return;

    Vector3 currMousePosition = Input.mousePosition;
    Vector3 prevMousePosition = m_prevMousePosition;
    Vector3 mousePositionDelta = currMousePosition - prevMousePosition;
    m_prevMousePosition = currMousePosition;

    if (!prevFrameHasFocus)
    {
      m_euler = transform.rotation.eulerAngles;
      return;
    }

    if (Input.GetMouseButton(0))
    {
      m_euler.x += mousePositionDelta.y;
      m_euler.y += mousePositionDelta.x;
      transform.rotation = Quaternion.Euler(m_euler);
    }
  }
}
