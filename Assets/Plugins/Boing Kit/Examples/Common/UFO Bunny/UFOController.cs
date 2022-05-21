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

namespace BoingKit
{
  public class UFOController : MonoBehaviour
  {
    public float LinearThrust = 3.0f;
    public float MaxLinearSpeed = 2.5f;
    public float LinearDrag = 4.0f;
    public float Tilt = 15.0f;

    public float AngularThrust = 30.0f;
    public float MaxAngularSpeed = 30.0f;
    public float AngularDrag = 30.0f;

    [Range(0.0f, 1.0f)] public float Hover = 1.0f;

    public Transform Eyes;
    public float BlinkInterval = 5.0f;
    private float m_blinkTimer = 0.0f;
    private bool m_lastBlinkWasDouble = false;
    private Vector3 m_eyeInitScale;
    private Vector3 m_eyeInitPositionLs;
    private Vector3Spring m_eyeScaleSpring;
    private Vector3Spring m_eyePositionLsSpring;

    public Transform Motor;
    public float MotorBaseAngularSpeed = 10.0f;
    public float MotorMaxAngularSpeed = 10.0f;

    public ParticleSystem BubbleEmitter;
    public float BubbleBaseEmissionRate = 10.0f;
    public float BubbleMaxEmissionRate = 10.0f;

    private Vector3 m_linearVelocity;
    private float m_angularVelocity;
    private float m_yawAngle;

    private Vector3 m_hoverCenter;
    private float m_hoverPhase;

    private float m_motorAngle;

    void Start()
    {
      m_linearVelocity = Vector3.zero;
      m_angularVelocity = 0.0f;
      m_yawAngle = transform.rotation.eulerAngles.y * MathUtil.Deg2Rad;
      m_hoverCenter = transform.position;
      m_hoverPhase = 0.0f;
      m_motorAngle = 0.0f;

      if (Eyes != null)
      {
        m_eyeInitScale = Eyes.localScale;
        m_eyeInitPositionLs = Eyes.localPosition;
        m_blinkTimer = BlinkInterval + Random.Range(1.0f, 2.0f);
        m_lastBlinkWasDouble = false;

        m_eyeScaleSpring.Reset(m_eyeInitScale);
        m_eyePositionLsSpring.Reset(m_eyeInitPositionLs);
      }
    }

    private void OnEnable()
    {
      Start();
    }

    void FixedUpdate()
    {
      float dt = Time.fixedDeltaTime;

      Vector3 linearInputVec = Vector3.zero;
      if (Input.GetKey(KeyCode.W))
        linearInputVec += Vector3.forward;
      if (Input.GetKey(KeyCode.S))
        linearInputVec += Vector3.back;
      if (Input.GetKey(KeyCode.A))
        linearInputVec += Vector3.left;
      if (Input.GetKey(KeyCode.D))
        linearInputVec += Vector3.right;
      if (Input.GetKey(KeyCode.R))
        linearInputVec += Vector3.up;
      if (Input.GetKey(KeyCode.F))
        linearInputVec += Vector3.down;

      bool linearThrustOn = linearInputVec.sqrMagnitude > MathUtil.Epsilon;
      if (linearThrustOn)
      {
        linearInputVec = linearInputVec.normalized * LinearThrust;
        m_linearVelocity += linearInputVec * dt;
        m_linearVelocity = VectorUtil.ClampLength(m_linearVelocity, 0.0f, MaxLinearSpeed);
      }
      else
      {
        m_linearVelocity = VectorUtil.ClampLength(m_linearVelocity, 0.0f, Mathf.Max(0.0f, m_linearVelocity.magnitude - LinearDrag * dt));
      }

      float speed = m_linearVelocity.magnitude;
      float tSpeed = speed * MathUtil.InvSafe(MaxLinearSpeed);

      Quaternion tiltRot = Quaternion.identity;
      float tHorizontal = 1.0f;
      float tHorizontalSpeed = 0.0f;
      if (speed > MathUtil.Epsilon)
      {
        Vector3 flatVel = m_linearVelocity;
        flatVel.y = 0.0f;
        tHorizontal = 
          m_linearVelocity.magnitude > 0.01f 
            ? 1.0f - Mathf.Clamp01(Mathf.Abs(m_linearVelocity.y) / m_linearVelocity.magnitude) 
            : 0.0f;
        tHorizontalSpeed = Mathf.Min(1.0f, speed / Mathf.Max(MathUtil.Epsilon, MaxLinearSpeed)) * tHorizontal;
        Vector3 tiltAxis = Vector3.Cross(Vector3.up, flatVel).normalized;
        float tiltAngle = Tilt * MathUtil.Deg2Rad * tHorizontalSpeed;
        tiltRot = QuaternionUtil.AxisAngle(tiltAxis, tiltAngle);
      }

      float angularInput = 0.0f;
      if (Input.GetKey(KeyCode.Q))
        angularInput -= 1.0f;
      if (Input.GetKey(KeyCode.E))
        angularInput += 1.0f;

      bool largerMaxAngularSpeed = Input.GetKey(KeyCode.LeftControl);

      bool angularThurstOn = Mathf.Abs(angularInput) > MathUtil.Epsilon;
      if (angularThurstOn)
      {
        float maxAngularSpeed = MaxAngularSpeed * (largerMaxAngularSpeed ? 2.5f : 1.0f);
        angularInput *= AngularThrust * MathUtil.Deg2Rad;
        m_angularVelocity += angularInput * dt;
        m_angularVelocity = Mathf.Clamp(m_angularVelocity, -maxAngularSpeed * MathUtil.Deg2Rad, maxAngularSpeed * MathUtil.Deg2Rad);
      }
      else
      {
        m_angularVelocity -= Mathf.Sign(m_angularVelocity) * Mathf.Min(Mathf.Abs(m_angularVelocity), AngularDrag * MathUtil.Deg2Rad * dt);
      }
      m_yawAngle += m_angularVelocity * dt;
      Quaternion yawRot = QuaternionUtil.AxisAngle(Vector3.up, m_yawAngle);

      m_hoverCenter += m_linearVelocity * dt;
      m_hoverPhase += Time.deltaTime;

      Vector3 hoverVec =
          0.05f * Mathf.Sin(1.37f * m_hoverPhase) * Vector3.right
        + 0.05f * Mathf.Sin(1.93f * m_hoverPhase + 1.234f) * Vector3.forward
        + 0.04f * Mathf.Sin(0.97f * m_hoverPhase + 4.321f) * Vector3.up;
      hoverVec *= Hover;

      Quaternion hoverQuat = Quaternion.FromToRotation(Vector3.up, hoverVec + Vector3.up);

      transform.position = m_hoverCenter + hoverVec;
      transform.rotation = tiltRot * yawRot * hoverQuat;

      if (Motor != null)
      {
        float motorAngularSpeedDeg = Mathf.Lerp(MotorBaseAngularSpeed, MotorMaxAngularSpeed, tHorizontalSpeed);
        m_motorAngle += motorAngularSpeedDeg * MathUtil.Deg2Rad * dt;
        Motor.localRotation = QuaternionUtil.AxisAngle(Vector3.up, m_motorAngle - m_yawAngle);
      }

      if (BubbleEmitter != null)
      {
        var emission = BubbleEmitter.emission;
        emission.rateOverTime = Mathf.Lerp(BubbleBaseEmissionRate, BubbleMaxEmissionRate, tSpeed);
      }

      if (Eyes != null)
      {
        m_blinkTimer -= dt;
        if (m_blinkTimer <= 0.0f)
        {
          bool doubleBlink = !m_lastBlinkWasDouble && Random.Range(0.0f, 1.0f) > 0.75f;
          m_blinkTimer =
              doubleBlink
                ? 0.2f 
                : BlinkInterval + Random.Range(1.0f, 2.0f);
          m_lastBlinkWasDouble = doubleBlink;

          m_eyeScaleSpring.Value.y = 0.0f;
          m_eyePositionLsSpring.Value.y -= 0.025f;
        }

        Eyes.localScale = m_eyeScaleSpring.TrackDampingRatio(m_eyeInitScale, 30.0f, 0.8f, dt);
        Eyes.localPosition = m_eyePositionLsSpring.TrackDampingRatio(m_eyeInitPositionLs, 30.0f, 0.8f, dt);
      }
    }
  }
}
