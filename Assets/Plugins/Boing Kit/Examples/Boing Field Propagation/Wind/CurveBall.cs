using BoingKit;
using UnityEngine;

public class CurveBall : MonoBehaviour
{
  public float Interval = 2.0f;

  private float m_speedX = 0.0f;
  private float m_speedZ = 0.0f;
  private float m_timer = 0.0f;

  public void Reset()
  {
    float angle = Random.Range(0.0f, MathUtil.TwoPi);
    float cos = Mathf.Cos(angle);
    float sin = Mathf.Sin(angle);
      

    m_speedX = 40.0f * cos;
    m_speedZ = 40.0f * sin;
    m_timer = 0.0f;

    Vector3 position = transform.position;
    position.x = -10.0f * cos;
    position.z = -10.0f * sin;
    transform.position = position;
  }

  public void Start()
  {
    Reset();
  }

  public void Update()
  {
    float dt = Time.deltaTime;

    if (m_timer > Interval)
      Reset();

    Vector3 position = transform.position;
    position.x += m_speedX * dt;
    position.z += m_speedZ * dt;
    transform.position = position;

    m_timer += dt;
  }
}
