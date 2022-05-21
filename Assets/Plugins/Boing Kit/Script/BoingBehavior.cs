/******************************************************************************/
/*
  Project   - Boing Kit
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

#if UNITY_EDITOR
using UnityEditor;
#endif

using UnityEngine;

namespace BoingKit
{
  public class BoingBehavior : MonoBehaviour
  {
    public BoingManager.UpdateMode UpdateMode = BoingManager.UpdateMode.Update;
    public BoingManager.UpdateTiming UpdateTiming = BoingManager.UpdateTiming.Late;

    public bool TwoDDistanceCheck      = false;
    public bool TwoDPositionInfluence  = false;
    public bool TwoDRotationInfluence  = false;
    public bool EnablePositionEffect   = true;
    public bool EnableRotationEffect   = true;
    public bool GlobalReactionUpVector = false;

    public BoingManager.TranslationLockSpace TranslationLockSpace = BoingManager.TranslationLockSpace.Global;
    public bool LockTranslationX = false;
    public bool LockTranslationY = false;
    public bool LockTranslationZ = false;

    public BoingWork.Params Params;
    public SharedBoingParams SharedParams;

    #if UNITY_2018_1_OR_NEWER
    internal bool PositionSpringDirty = false;
    internal bool RotationSpringDirty = false;
    #endif

    public Vector3Spring PositionSpring
    {
      get { return Params.Instance.PositionSpring; }
      set
      {
        Params.Instance.PositionSpring = value;

        #if UNITY_2018_1_OR_NEWER
        PositionSpringDirty = true;
        #endif
      }
    }

    public QuaternionSpring RotationSpring
    {
      get { return Params.Instance.RotationSpring; }
      set
      {
        Params.Instance.RotationSpring = value;

        #if UNITY_2018_1_OR_NEWER
        RotationSpringDirty = true;
        #endif
      }
    }

    internal Vector3 CachedPosition;
    internal Vector3 RenderPosition;
    internal Quaternion CachedRotation;
    internal Quaternion RenderRotation;

    internal bool InitRebooted = false;

    public BoingBehavior()
    {
      Params.Init();
    }

    public virtual void Reboot()
    {
      Params.Instance.PositionSpring.Reset(gameObject.transform.position);
      Params.Instance.RotationSpring.Reset(gameObject.transform.rotation);
      CachedPosition = gameObject.transform.position;
      CachedRotation = gameObject.transform.rotation;
    }

    public virtual void OnEnable()
    {
      InitRebooted = false;
      Register();
    }

    public void Start()
    {
      InitRebooted = false;
    }

    public void OnDisable()
    {
      Unregister();
    }

    protected virtual void Register()
    {
      BoingManager.Register(this);
    }

    protected virtual void Unregister()
    {
      BoingManager.Unregister(this);
    }

    public void UpdateFlags()
    {
      Params.Bits.SetBit(BoingWork.ReactorFlags.TwoDDistanceCheck     , TwoDDistanceCheck     );
      Params.Bits.SetBit(BoingWork.ReactorFlags.TwoDPositionInfluence , TwoDPositionInfluence );
      Params.Bits.SetBit(BoingWork.ReactorFlags.TwoDRotationInfluence , TwoDRotationInfluence );
      Params.Bits.SetBit(BoingWork.ReactorFlags.EnablePositionEffect  , EnablePositionEffect  );
      Params.Bits.SetBit(BoingWork.ReactorFlags.EnableRotationEffect  , EnableRotationEffect  );
      Params.Bits.SetBit(BoingWork.ReactorFlags.GlobalReactionUpVector, GlobalReactionUpVector);

      Params.Bits.SetBit(BoingWork.ReactorFlags.FixedUpdate, (UpdateMode == BoingManager.UpdateMode.FixedUpdate));
      Params.Bits.SetBit(BoingWork.ReactorFlags.LateUpdateTiming, (UpdateTiming == BoingManager.UpdateTiming.Late));
    }

    public virtual void PrepareExecute()
    {
      PrepareExecute(false);
    }

    protected void PrepareExecute(bool accumulateEffectors)
    {
      if (SharedParams != null)
        BoingWork.Params.Copy(ref SharedParams.Params, ref Params);

      UpdateFlags();

      Params.InstanceID = GetInstanceID();

      Vector3 scale = transform.localScale;

      #if UNITY_2018_1_OR_NEWER
      Params.Instance.PrepareExecute
      (
        ref Params, 
        CachedPosition, 
        CachedRotation, 
        Mathf.Min(scale.x, scale.y, scale.z), 
        accumulateEffectors
      );
      #else
      Params.Instance.PrepareExecute
      (
        ref Params, 
        transform.position, 
        transform.rotation, 
        Mathf.Min(scale.x, scale.y, scale.z), 
        accumulateEffectors
      );
      #endif
    }

    public void Execute(float dt)
    {
      Params.Execute(dt);
    }

    public void PullResults()
    {
      PullResults(ref Params);
    }

    public void GatherOutput(ref BoingWork.Output o)
    {
        #if UNITY_2018_1_OR_NEWER
        if (BoingManager.UseAsynchronousJobs)
        {
          if (PositionSpringDirty)
            PositionSpringDirty = false;
          else
            Params.Instance.PositionSpring = o.PositionSpring;

          if (RotationSpringDirty)
            RotationSpringDirty = false;
          else
            Params.Instance.RotationSpring = o.RotationSpring;
        }
        else
        #endif
        {
          Params.Instance.PositionSpring = o.PositionSpring;
          Params.Instance.RotationSpring = o.RotationSpring;
        }
    }

    private void PullResults(ref BoingWork.Params p)
    {
      CachedPosition = transform.position;
      RenderPosition = BoingWork.ComputeTranslationalResults(transform, transform.position, p.Instance.PositionSpring.Value, this);
      transform.position = RenderPosition;

      CachedRotation = transform.rotation;
      RenderRotation = p.Instance.RotationSpring.ValueQuat;;
      transform.rotation = RenderRotation;
    }

    public void Restore()
    {
      if (Application.isEditor)
      {
        // transforms can be manually modified in editor between post-update and pre-update
        // we respect that by skipping restoration of cached transforms

        if ((transform.position - RenderPosition).sqrMagnitude < 1e-4f)
          transform.position = CachedPosition;

        if (QuaternionUtil.GetAngle(transform.rotation * Quaternion.Inverse(RenderRotation)) < 1e-2f)
          transform.rotation = CachedRotation;
      }
      else
      {
        transform.position = CachedPosition;
        transform.rotation = CachedRotation;
      }
    }
  }
}

