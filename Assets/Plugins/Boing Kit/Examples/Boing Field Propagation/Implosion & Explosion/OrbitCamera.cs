using BoingKit;
using UnityEngine;

public class OrbitCamera : MonoBehaviour
{ 
  private static readonly float kOrbitSpeed = 0.01f;
  private float m_phase = 0.0f;

  public void Start()
  {
    
  }

  public void Update()
  {
    m_phase += kOrbitSpeed * MathUtil.TwoPi * Time.deltaTime;

    transform.position = new Vector3(-4.0f * Mathf.Cos(m_phase), 6.0f, 4.0f * Mathf.Sin(m_phase));
    transform.rotation = Quaternion.LookRotation((new Vector3(0.0f, 3.0f, 0.0f) - transform.position).normalized);
  }
}
