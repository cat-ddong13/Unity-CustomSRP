using BoingKit;
using UnityEngine;

public class LiquidMain : MonoBehaviour
{
  public Material PlaneMaterial;
  public BoingReactorField ReactorField;
  public GameObject Effector;

  private static readonly float kPlaneMeshCellSize = 0.25f;
  private static readonly int kNumInstancedPlaneCellPerDrawCall = 1000; // Unity 5 doesn't like 1024 and I don't like 1023 *sigh*
  private static readonly int kNumMovingEffectors = 5;
  private static readonly float kMovingEffectorPhaseSpeed = 0.5f;
  private static int kNumPlaneCells;
  private static readonly int kPlaneMeshResolution = 64;
  private Mesh m_planeMesh;
  private Matrix4x4[][] m_aaInstancedPlaneCellMatrix;

  private GameObject[] m_aMovingEffector;
  private float[] m_aMovingEffectorPhase;

  private void ResetEffector(GameObject obj)
  {
    Transform t = obj.transform;
    t.position = new Vector3(Random.Range(-0.3f, 0.3f), -100.0f, Random.Range(-0.3f, 0.3f)) * kPlaneMeshCellSize * kPlaneMeshResolution;
  }

  public void Start()
  {
    m_planeMesh = new Mesh();
    m_planeMesh.vertices = 
      new Vector3[]
      {
        new Vector3(-0.5f, 0.0f, -0.5f) * kPlaneMeshCellSize, 
        new Vector3(-0.5f, 0.0f,  0.5f) * kPlaneMeshCellSize, 
        new Vector3( 0.5f, 0.0f,  0.5f) * kPlaneMeshCellSize, 
        new Vector3( 0.5f, 0.0f, -0.5f) * kPlaneMeshCellSize, 
      };
    m_planeMesh.normals = 
      new Vector3[]
      {
        new Vector3(0.0f, 1.0f, 0.0f), 
        new Vector3(0.0f, 1.0f, 0.0f), 
        new Vector3(0.0f, 1.0f, 0.0f), 
        new Vector3(0.0f, 1.0f, 0.0f), 
      };
    m_planeMesh.SetIndices(new int[] { 0, 1, 2, 0, 2, 3 }, MeshTopology.Triangles, 0);

    kNumPlaneCells = kPlaneMeshResolution * kPlaneMeshResolution;
    m_aaInstancedPlaneCellMatrix = new Matrix4x4[(kNumPlaneCells + kNumInstancedPlaneCellPerDrawCall - 1) / kNumInstancedPlaneCellPerDrawCall][];
    for (int i = 0; i < m_aaInstancedPlaneCellMatrix.Length; ++i)
      m_aaInstancedPlaneCellMatrix[i] = new Matrix4x4[kNumInstancedPlaneCellPerDrawCall];

    Vector3 planeCenterShift = new Vector3(-0.5f, 0.0f, -0.5f) * kPlaneMeshCellSize * kPlaneMeshResolution;
    for (int y = 0; y < kPlaneMeshResolution; ++y)
      for (int x = 0; x < kPlaneMeshResolution; ++x)
      {
        int iCellFlat = y * kPlaneMeshResolution + x;
        Vector3 cellCenter = new Vector3(x, 0.0f, y) * kPlaneMeshCellSize + planeCenterShift;
        Matrix4x4 mat = Matrix4x4.TRS(cellCenter, Quaternion.identity, Vector3.one);
        m_aaInstancedPlaneCellMatrix[iCellFlat / kNumInstancedPlaneCellPerDrawCall][iCellFlat % kNumInstancedPlaneCellPerDrawCall] = mat;
      }

    m_aMovingEffector = new GameObject[kNumMovingEffectors];
    m_aMovingEffectorPhase = new float[kNumMovingEffectors];
    var aEffectorComp = new BoingEffector[kNumMovingEffectors];
    for (int i = 0; i < kNumMovingEffectors; ++i)
    {
      var newEffector = Instantiate(Effector);
      m_aMovingEffector[i] = newEffector;
      ResetEffector(newEffector);
      m_aMovingEffectorPhase[i] = -MathUtil.HalfPi + (i / (float) kNumMovingEffectors) * MathUtil.Pi;
      aEffectorComp[i] = newEffector.GetComponent<BoingEffector>();
    }

    ReactorField.Effectors = aEffectorComp;
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
  
    ReactorField.UpdateShaderConstants(PlaneMaterial);

    int numPlanesToDraw = kNumPlaneCells;
    for (int i = 0; i < m_aaInstancedPlaneCellMatrix.Length; ++i)
    {
      var aMat = m_aaInstancedPlaneCellMatrix[i];
      Graphics.DrawMeshInstanced(m_planeMesh, 0, PlaneMaterial, aMat, Mathf.Min(numPlanesToDraw, kNumInstancedPlaneCellPerDrawCall));
      numPlanesToDraw -= kNumInstancedPlaneCellPerDrawCall;
    }

    for (int i = 0; i < kNumMovingEffectors; ++i)
    {
      var effector = m_aMovingEffector[i];

      float phase = m_aMovingEffectorPhase[i];
      phase += MathUtil.TwoPi * kMovingEffectorPhaseSpeed * Time.deltaTime;
      float prevPhase = phase;
      phase = Mathf.Repeat(phase + MathUtil.HalfPi, MathUtil.Pi) - MathUtil.HalfPi;
      m_aMovingEffectorPhase[i] = phase;

      if (phase < prevPhase - 0.01f)
        ResetEffector(effector);

      Vector3 position = effector.transform.position;
      position.y = Mathf.Tan(Mathf.Clamp(phase, -MathUtil.HalfPi + 0.2f, MathUtil.HalfPi - 0.2f)) + 3.5f;
      effector.transform.position = position;
    }
  }
}
