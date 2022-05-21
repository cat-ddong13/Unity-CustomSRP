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

public class RotationStepper : MonoBehaviour
{
  public enum ModeEnum
  {
    Fixed, 
    Random
  };

  public ModeEnum Mode = ModeEnum.Fixed;

  [ConditionalField("Mode", ModeEnum.Fixed)]
  public float Angle = 25.0f;

  public float Frequency;

  private float m_phase;

  public void OnEnable()
  {
    m_phase = 0.0f;

    Random.InitState(0);
  }

  public void Update()
  {
    m_phase += Frequency * Time.deltaTime;

    switch (Mode)
    {
      case ModeEnum.Fixed:
        transform.rotation = Quaternion.Euler(0.0f, 0.0f, (Mathf.Repeat(m_phase, 2.0f) < 1.0f ? -25.0f : 25.0f));
        break;

      case ModeEnum.Random:
        while (m_phase >= 1.0f)
        {
          Random.InitState(Time.frameCount);
          transform.rotation = Random.rotationUniform;
          --m_phase;
        }
        break;
    }
  }
}
