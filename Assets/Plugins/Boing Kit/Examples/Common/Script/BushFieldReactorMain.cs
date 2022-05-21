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
using System.Collections.Generic;
using UnityEngine;

public class BushFieldReactorMain : MonoBehaviour
{
  public GameObject Bush;
  public GameObject Blossom;
  public GameObject Sphere;

  public int NumBushes;
  public Vector2 BushScaleRange;

  public int NumBlossoms;
  public Vector2 BlossomScaleRange;

  public Vector2 FieldBounds;

  public int NumSpheresPerCircle;
  public int NumCircles;
  public float MaxCircleRadius;
  public float CircleSpeed;

  private List<GameObject> m_aSphere;
  private float m_basePhase;

  public void Start()
  {
    Random.InitState(0);

    for (int i = 0; i < NumBushes; ++i)
    {
      var bush = Instantiate(Bush);

      float scale = Random.Range(BushScaleRange.x, BushScaleRange.y);

      bush.transform.position =
        new Vector3
        (
          Random.Range(-0.5f * FieldBounds.x, 0.5f * FieldBounds.x), 
          0.2f * scale, 
          Random.Range(-0.5f * FieldBounds.y, 0.5f * FieldBounds.y)
        );

      bush.transform.rotation = Quaternion.Euler(0.0f, Random.Range(0.0f, 360.0f), 0.0f);

      bush.transform.localScale = scale * Vector3.one;

      var bushBoing = bush.GetComponent<BoingBehavior>();
      if (bushBoing != null)
        bushBoing.Reboot();
    }

    for (int i = 0; i < NumBlossoms; ++i)
    {
      var blossom = Instantiate(Blossom);

      float scale = Random.Range(BlossomScaleRange.x, BlossomScaleRange.y);

      blossom.transform.position =
        new Vector3
        (
          Random.Range(-0.5f * FieldBounds.x, 0.5f * FieldBounds.y),
          0.2f * scale,
          Random.Range(-0.5f * FieldBounds.y, 0.5f * FieldBounds.y)
        );

      blossom.transform.rotation = Quaternion.Euler(0.0f, Random.Range(0.0f, 360.0f), 0.0f);

      blossom.transform.localScale = scale * Vector3.one;

      var blossomBoing = blossom.GetComponent<BoingBehavior>();
      if (blossomBoing != null)
        blossomBoing.Reboot();
    }

    m_aSphere = new List<GameObject>(NumSpheresPerCircle * NumCircles);
    for (int c = 0; c < NumCircles; ++c)
      for (int s = 0; s < NumSpheresPerCircle; ++s)
      {
        m_aSphere.Add(Instantiate(Sphere));
      }

    m_basePhase = 0.0f;
  }

  public void Update()
  {
    int iSphere = 0;
    for (int c = 0; c < NumCircles; ++c)
    {
      float radius = MaxCircleRadius / (c + 1);
      for (int s = 0; s < NumSpheresPerCircle; ++s)
      {
        float phase = m_basePhase + (s / (float) NumSpheresPerCircle) * 2.0f * Mathf.PI;
        phase *= (c % 2 == 0) ? 1.0f : -1.0f;

        var sphere = m_aSphere[iSphere];

        sphere.transform.position =
          new Vector3
          (
            radius * Mathf.Cos(phase),
            0.2f,
            radius * Mathf.Sin(phase)
          );

        ++iSphere;
      }
    }

    m_basePhase -= (CircleSpeed / MaxCircleRadius) * Time.deltaTime;
  }
}
