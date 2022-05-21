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
using System.Linq;
using UnityEngine;

public class BushFieldReactorFieldMain : MonoBehaviour
{
  public GameObject Bush;
  public GameObject Blossom;
  public GameObject Sphere;
  public BoingReactorField ReactorField;

  public int NumBushes;
  public Vector2 BushScaleRange;

  public int NumBlossoms;
  public Vector2 BlossomScaleRange;

  public Vector2 FieldBounds;

  public int NumSpheresPerCircle;
  public int NumCircles;
  public float MaxCircleRadius;
  public float CircleSpeed;

  private List<BoingEffector> m_aSphere;
  private float m_basePhase;

  private static readonly int kNumInstancedBushesPerDrawCall = 1000; // Unity 5 doesn't like 1024 and I don't like 1023 *sigh*
  private Matrix4x4 [][] m_aaInstancedBushMatrix;
  private MaterialPropertyBlock m_bushMaterialProps;

  public void Start()
  {
    Random.InitState(0);

    var bushGpuSampler = Bush.GetComponent<BoingReactorFieldGPUSampler>();
    if (bushGpuSampler == null)
    {
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

        var cpuSampler = bush.GetComponent<BoingReactorFieldCPUSampler>();
        if (cpuSampler != null)
          cpuSampler.ReactorField = ReactorField;

        var gpuSampler = bush.GetComponent<BoingReactorFieldGPUSampler>();
        if (gpuSampler != null)
          gpuSampler.ReactorField = ReactorField;
      }
    }
    else
    {
      m_aaInstancedBushMatrix = new Matrix4x4[(NumBushes + kNumInstancedBushesPerDrawCall - 1) / kNumInstancedBushesPerDrawCall][];
      for (int i = 0; i < m_aaInstancedBushMatrix.Length; ++i)
      {
        m_aaInstancedBushMatrix[i] = new Matrix4x4[kNumInstancedBushesPerDrawCall];
      }
      for (int i = 0; i < NumBushes; ++i)
      {
        float scale = Random.Range(BushScaleRange.x, BushScaleRange.y);

        Vector3 position =
          new Vector3
          (
            Random.Range(-0.5f * FieldBounds.x, 0.5f * FieldBounds.x),
            0.2f * scale,
            Random.Range(-0.5f * FieldBounds.y, 0.5f * FieldBounds.y)
          );

        Quaternion rotation = Quaternion.Euler(0.0f, Random.Range(0.0f, 360.0f), 0.0f);

        m_aaInstancedBushMatrix[i / kNumInstancedBushesPerDrawCall][i % kNumInstancedBushesPerDrawCall].SetTRS(position, rotation, scale * Vector3.one);
      }
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

      blossom.GetComponent<BoingReactorFieldCPUSampler>().ReactorField = ReactorField;
    }

    m_aSphere = new List<BoingEffector>(NumSpheresPerCircle * NumCircles);
    for (int c = 0; c < NumCircles; ++c)
      for (int s = 0; s < NumSpheresPerCircle; ++s)
      {
        var sphere = Instantiate(Sphere);
        m_aSphere.Add(sphere.GetComponent<BoingEffector>());
      }

    var field = ReactorField.GetComponent<BoingReactorField>();
    field.Effectors =
      field.Effectors != null 
        ? field.Effectors.Concat(m_aSphere.ToArray()).ToArray()   
        : m_aSphere.ToArray();

    m_basePhase = 0.0f;
  }

#if UNITY_2017_1_OR_NEWER && !UNITY_2018_3_OR_NEWER
  private static bool s_warnedMaterialPropertyBlocks = false;
#endif

  public void Update()
  {
  #if UNITY_2017_1_OR_NEWER && !UNITY_2018_3_OR_NEWER
    if (!s_warnedMaterialPropertyBlocks)
    {
      Debug.LogWarning
      (
        "There's a known issue with Unity between 2017.1 and 2018.2 where material property blocks are not correctly applied to instanced meshes.\n" 
        + "You may not see the effects applied properly to instanced meshes in this example. " 
        + "This issue has been fixed since Unity 2018.3."
      );

      s_warnedMaterialPropertyBlocks = true;
    }
  #endif

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

    if (m_aaInstancedBushMatrix != null)
    {
      var bushMesh = Bush.GetComponent<MeshFilter>().sharedMesh;
      var bushMaterial = Bush.GetComponent<MeshRenderer>().sharedMaterial;

      if (m_bushMaterialProps == null)
        m_bushMaterialProps = new MaterialPropertyBlock();

      if (ReactorField.UpdateShaderConstants(m_bushMaterialProps))
      {
        foreach (var aInstancedBushMatrix in m_aaInstancedBushMatrix)
        {
          Graphics.DrawMeshInstanced(bushMesh, 0, bushMaterial, aInstancedBushMatrix, aInstancedBushMatrix.Length, m_bushMaterialProps);
        }
      }
    }
  }
}
