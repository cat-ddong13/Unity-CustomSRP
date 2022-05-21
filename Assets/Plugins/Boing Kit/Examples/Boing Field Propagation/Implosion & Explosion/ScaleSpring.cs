using BoingKit;
using UnityEngine;

public class ScaleSpring : MonoBehaviour
{
  private static readonly float kInterval = 2.0f;
  private static readonly float kSmallScale = 0.6f;
  private static readonly float kLargeScale = 2.0f;
  private static readonly float kMoveDistance = 30.0f;

  private Vector3Spring m_spring;
  private float m_targetScale = 0.0f;
  private float m_lastTickTime = 0.0f;

  public void Tick()
  {
    m_targetScale = (m_targetScale == kSmallScale) ? kLargeScale : kSmallScale;
    m_lastTickTime = Time.time;

    var effector = GetComponent<BoingEffector>();
    effector.MoveDistance = kMoveDistance * ((m_targetScale == kSmallScale) ? -1.0f : 1.0f);
  }

  public void Start()
  {
    Tick();
    m_spring.Reset(m_targetScale * Vector3.one);
  }

  public void FixedUpdate()
  {
    if (Time.time - m_lastTickTime > kInterval)
      Tick();

    m_spring.TrackHalfLife(m_targetScale * Vector3.one, 6.0f, 0.05f, Time.fixedDeltaTime);
    transform.localScale = m_spring.Value;

    var effector = GetComponent<BoingEffector>();
    effector.MoveDistance *= Mathf.Min(0.99f, 35.0f * Time.fixedDeltaTime);
  }
}
