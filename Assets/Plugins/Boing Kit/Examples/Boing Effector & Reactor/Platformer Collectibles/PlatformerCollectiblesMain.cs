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

public class PlatformerCollectiblesMain : MonoBehaviour
{
  public GameObject Coin;
  public float CoinGridCount = 5;
  public float CoinGridSize = 7.0f;

  public void Start()
  {
    for (int i = 0; i < CoinGridCount; ++i)
    {
      float x = -0.5f * CoinGridSize + CoinGridSize * i / (CoinGridCount - 1);
      for (int j = 0; j < CoinGridCount; ++j)
      {
        float z = -0.5f * CoinGridSize + CoinGridSize * j / (CoinGridCount - 1);

        var coin = Instantiate(Coin);
        coin.transform.position = new Vector3(x, 0.2f, z);
      }
    }
  }
}
