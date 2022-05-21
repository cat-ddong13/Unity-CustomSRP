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
using System;
using UnityEngine;

public class CollectibleCoin : MonoBehaviour
{
  public float RespawnTime;

  private bool m_taken;
  private Vector3 m_respawnPosition;
  private float m_respawnTimerStartTime;

  public void Update()
  {
    var boing = GetComponent<BoingBehavior>();

    if (m_taken)
    {
      if (Time.time - m_respawnTimerStartTime < RespawnTime)
        return;

      transform.position = m_respawnPosition + 0.4f * Vector3.down;

      if (boing != null)
        boing.Reboot();

      transform.position = m_respawnPosition;

      m_taken = false;
    }

    var player = GameObject.Find("Character");
    var coinIcon = GameObject.Find("Coin Icon");
    var coinCounter = GameObject.Find("Coin Counter");

    float distSqr = (player.transform.position - transform.position).sqrMagnitude;
    if (distSqr > 0.4f)
      return;

    m_respawnPosition = transform.position;

    if (boing != null)
    {
      var positionSpring = boing.PositionSpring;
      positionSpring.Reset(transform.position, new Vector3(100.0f, 0.0f, 0.0f));
      boing.PositionSpring = positionSpring;
    }

    transform.position = coinIcon.transform.position + new Vector3(-2.0f, 0.5f, 0.0f);

    var text = coinCounter.GetComponent<TextMesh>();
    text.text = (Convert.ToInt32(text.text) + 1).ToString();

    m_respawnTimerStartTime = Time.time;
    m_taken = true;
  }
}
