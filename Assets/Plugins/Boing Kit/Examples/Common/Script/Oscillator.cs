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

public class Oscillator : MonoBehaviour
{
  public enum WaveTypeEnum
  {
    Sine, 
    Square, 
    Triangle, 
  }

  public WaveTypeEnum WaveType = WaveTypeEnum.Sine;

  private Vector3 m_initCenter;

  public bool UseCenter = false;
  public Vector3 Center;
  public Vector3 Radius;
  public Vector3 Frequency;
  public Vector3 Phase;

  public void Init(Vector3 center, Vector3 radius, Vector3 frequency, Vector3 startPhase)
  {
    Center = center;
    Radius = radius;
    Frequency = frequency;
    Phase = startPhase;
  }

  private float SampleWave(float phase)
  {
    switch (WaveType)
    {
      case WaveTypeEnum.Sine:
        return Mathf.Sin(phase);

      case WaveTypeEnum.Square:
        phase = Mathf.Repeat(phase, 2.0f * Mathf.PI);
        return phase < Mathf.PI ? 1.0f : -1.0f;

      case WaveTypeEnum.Triangle:
        phase = Mathf.Repeat(phase, 2.0f * Mathf.PI);
        if (phase < 0.5f * Mathf.PI)
        {
          return phase / (0.5f * Mathf.PI);
        }
        else if (phase < Mathf.PI)
        {
          return 1.0f - (phase - 0.5f * Mathf.PI) / (0.5f * Mathf.PI);
        }
        else if (phase < 1.5f * Mathf.PI)
        {
          return (Mathf.PI - phase) / (0.5f * Mathf.PI);
        }
        else
        {
          return (phase - 1.5f * Mathf.PI) / (0.5f * Mathf.PI) - 1.0f;
        }
    }

    return 0.0f;
  }

  public void OnEnable()
  {
    m_initCenter = transform.position;
  }

  public void Update()
  {
    Phase += Frequency * 2.0f * Mathf.PI * Time.deltaTime;

    Vector3 pos = UseCenter ? Center : m_initCenter;
    pos.x += Radius.x * SampleWave(Phase.x);
    pos.y += Radius.y * SampleWave(Phase.y);
    pos.z += Radius.z * SampleWave(Phase.z);

    transform.position = pos;
  }
}
