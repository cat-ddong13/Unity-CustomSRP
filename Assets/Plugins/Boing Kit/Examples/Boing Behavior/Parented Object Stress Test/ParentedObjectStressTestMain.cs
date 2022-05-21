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

public class ParentedObjectStressTestMain : MonoBehaviour
{
  public GameObject Object;
  public Vector3 NumObjects;
  public Vector3 Spacing;

  public void Start()
  {
    for (int c = 0; c < (int) NumObjects.x; ++c)
      for (int r = 0; r < (int) NumObjects.y; ++r)
        for (int d = 0; d < (int) NumObjects.z; ++d)
        {
          var obj = Instantiate(Object);
          obj.transform.position =
            new Vector3
            (
              2.0f * (c / (NumObjects.x - 1) - 0.5f) * NumObjects.x * Spacing.x,
              2.0f * (r / (NumObjects.y - 1) - 0.5f) * NumObjects.y * Spacing.y,
              2.0f * (d / (NumObjects.z - 1) - 0.5f) * NumObjects.z * Spacing.z
            );
        }
  }
}
