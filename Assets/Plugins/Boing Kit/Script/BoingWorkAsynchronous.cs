/******************************************************************************/
/*
  Project   - Boing Kit
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

#if UNITY_2018_1_OR_NEWER

using Unity.Collections;
using Unity.Jobs;

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;

namespace BoingKit
{
  public static class BoingWorkAsynchronous
  {
    #region Registry

    internal static void PostUnregisterBehaviorCleanUp()
    {
      if (s_behaviorJobNeedsGather)
      {
        s_hBehaviorJob.Complete();
        s_aBehaviorParams.Dispose();
        s_aBehaviorOutput.Dispose();
        s_behaviorJobNeedsGather = false;
      }
    }

    internal static void PostUnregisterEffectorReactorCleanUp()
    {
      if (s_reactorJobNeedsGather)
      {
        s_hReactorJob.Complete();
        s_aEffectors.Dispose();
        s_aReactorExecParams.Dispose();
        s_aReactorExecOutput.Dispose();
        s_reactorJobNeedsGather = false;
      }
    }

    #endregion


    #region Behavior

    private struct BehaviorJob : IJobParallelFor
    {
      public NativeArray<BoingWork.Params> Params;
      public NativeArray<BoingWork.Output> Output;
      public float DeltaTime;
      public float FixedDeltaTime;
      public int NumFixedUpdateIterations;
      public bool LateUpdateTiming;

      public void Execute(int index)
      {
        var ep = Params[index];

        if (LateUpdateTiming != ep.Bits.IsBitSet(BoingWork.ReactorFlags.LateUpdateTiming))
          return;

        if (ep.Bits.IsBitSet(BoingWork.ReactorFlags.FixedUpdate))
        {
          for (int i = 0; i < NumFixedUpdateIterations; ++i)
            ep.Execute(FixedDeltaTime);
        }
        else
        {
          ep.Execute(BoingManager.DeltaTime);
        }

        Output[index] = new BoingWork.Output(ep.InstanceID, ref ep.Instance.PositionSpring, ref ep.Instance.RotationSpring);
      }
    }

    private static bool s_behaviorJobNeedsGather = false;
    private static JobHandle s_hBehaviorJob;
    private static NativeArray<BoingWork.Params> s_aBehaviorParams;
    private static NativeArray<BoingWork.Output> s_aBehaviorOutput;

    internal static void ExecuteBehaviors
    (
      Dictionary<int, BoingBehavior> behaviorMap, 
      BoingManager.UpdateTiming updateTiming
    )
    {
      // gather job
      if (updateTiming == BoingManager.UpdateTiming.Early)
      {
        if (s_behaviorJobNeedsGather)
        {
          Profiler.BeginSample("Gather Behavior Job");
          s_hBehaviorJob.Complete();
          for (int iBehavior = 0, n = s_aBehaviorParams.Length; iBehavior < n; ++iBehavior)
            s_aBehaviorOutput[iBehavior].GatherOutput(behaviorMap);
          s_aBehaviorParams.Dispose();
          s_aBehaviorOutput.Dispose();
          Profiler.EndSample();

          s_behaviorJobNeedsGather = false;
        }
      }

      // kick job
      if (updateTiming == BoingManager.UpdateTiming.Late)
      {
        Profiler.BeginSample("Kick Behavior Job");
        Profiler.BeginSample("Allocate");
        s_aBehaviorParams = new NativeArray<BoingWork.Params>(behaviorMap.Count, Allocator.TempJob, NativeArrayOptions.UninitializedMemory);
        s_aBehaviorOutput = new NativeArray<BoingWork.Output>(behaviorMap.Count, Allocator.TempJob, NativeArrayOptions.UninitializedMemory);
        Profiler.EndSample();
        {
          Profiler.BeginSample("Push Data");
          int iBehavior = 0;
          foreach (var itBehavior in behaviorMap)
          {
            var behavior = itBehavior.Value;
            behavior.PrepareExecute();
            s_aBehaviorParams[iBehavior++] = behavior.Params;
          }
          Profiler.EndSample();
        }
        float dt = Time.deltaTime;
        var job = new BehaviorJob()
        {
          Params = s_aBehaviorParams, 
          Output = s_aBehaviorOutput, 
          DeltaTime = BoingManager.DeltaTime, 
          FixedDeltaTime = BoingManager.FixedDeltaTime, 
          NumFixedUpdateIterations = BoingManager.NumFixedUpdateIterations, 
          LateUpdateTiming = (updateTiming == BoingManager.UpdateTiming.Late)
        };
        s_hBehaviorJob = job.Schedule(s_aBehaviorParams.Length, 32);
        JobHandle.ScheduleBatchedJobs();
        Profiler.EndSample();

        s_behaviorJobNeedsGather = true;
      }
    }

    #endregion // Behavior


    #region Reactor

    private struct ReactorJob : IJobParallelFor
    {
      [ReadOnly] public NativeArray<BoingEffector.Params> Effectors;
      public NativeArray<BoingWork.Params> Params;
      public NativeArray<BoingWork.Output> Output;
      public float DeltaTime;
      public float FixedDeltaTime;
      public int NumFixedUpdateIterations;
      public bool LateUpdateTiming;

      public void Execute(int index)
      {
        var rep = Params[index];

        if (LateUpdateTiming != rep.Bits.IsBitSet(BoingWork.ReactorFlags.LateUpdateTiming))
          return;

        for (int i = 0, n = Effectors.Length; i < n; ++i)
        {
          var eep = Effectors[i];
          rep.AccumulateTarget(ref eep);
        }
        rep.EndAccumulateTargets();

        if (rep.Bits.IsBitSet(BoingWork.ReactorFlags.FixedUpdate))
        {
          for (int i = 0; i < NumFixedUpdateIterations; ++i)
            rep.Execute(FixedDeltaTime);
        }
        else
        {
          rep.Execute(BoingManager.DeltaTime);
        }

        Output[index] = new BoingWork.Output(rep.InstanceID, ref rep.Instance.PositionSpring, ref rep.Instance.RotationSpring);
      }
    }

    private static bool s_reactorJobNeedsGather = false;
    private static JobHandle s_hReactorJob;
    private static NativeArray<BoingEffector.Params> s_aEffectors;
    private static NativeArray<BoingWork.Params> s_aReactorExecParams;
    private static NativeArray<BoingWork.Output> s_aReactorExecOutput;

    internal static void ExecuteReactors
    (
      Dictionary<int, BoingEffector> effectorMap, 
      Dictionary<int, BoingReactor> reactorMap, 
      Dictionary<int, BoingReactorField> fieldMap, 
      Dictionary<int, BoingReactorFieldCPUSampler> cpuSamplerMap, 
      BoingManager.UpdateTiming updateTiming
    )
    {
      float dt = Time.deltaTime;

      // gather job
      if (updateTiming == BoingManager.UpdateTiming.Early)
      {
        if (s_reactorJobNeedsGather)
        {
          Profiler.BeginSample("Gather Reactor Job");
          if (s_aEffectors.Length > 0 && s_aReactorExecParams.Length > 0)
          {
            s_hReactorJob.Complete();

            Profiler.BeginSample("Pull Data");
            for (int iReactor = 0, n = s_aReactorExecParams.Length; iReactor < n; ++iReactor)
            {
              s_aReactorExecOutput[iReactor].GatherOutput(reactorMap);
            }
            Profiler.EndSample();
          }
          s_aEffectors.Dispose();
          s_aReactorExecParams.Dispose();
          s_aReactorExecOutput.Dispose();
          Profiler.EndSample();

          s_reactorJobNeedsGather = false;
        }
      }

      // kick job
      if (updateTiming == BoingManager.UpdateTiming.Late)
      {
        Profiler.BeginSample("Kick Reactor Job");
        s_aEffectors = new NativeArray<BoingEffector.Params>(effectorMap.Count, Allocator.TempJob, NativeArrayOptions.UninitializedMemory);
        s_aReactorExecParams = new NativeArray<BoingWork.Params>(reactorMap.Count, Allocator.TempJob, NativeArrayOptions.UninitializedMemory);
        s_aReactorExecOutput = new NativeArray<BoingWork.Output>(reactorMap.Count, Allocator.TempJob, NativeArrayOptions.UninitializedMemory);
        {
          Profiler.BeginSample("Push Data");
          int iEffector = 0;
          var eep = new BoingEffector.Params();
          foreach (var itEffector in effectorMap)
          {
            var effector = itEffector.Value;
            eep.Fill(itEffector.Value);
            s_aEffectors[iEffector++] = eep;
          }
          int iReactor = 0;
          foreach (var itReactor in reactorMap)
          {
            var reactor = itReactor.Value;
            reactor.PrepareExecute();
            s_aReactorExecParams[iReactor++] = reactor.Params;
          }
          Profiler.EndSample();
        }
        if (s_aEffectors.Length > 0 && s_aReactorExecParams.Length > 0)
        {
          var job = new ReactorJob()
          {
            Effectors = s_aEffectors, 
            Params = s_aReactorExecParams, 
            Output = s_aReactorExecOutput, 
            DeltaTime = dt, 
            FixedDeltaTime = BoingManager.FixedDeltaTime, 
            NumFixedUpdateIterations = BoingManager.NumFixedUpdateIterations, 
            LateUpdateTiming = (updateTiming == BoingManager.UpdateTiming.Late)
          };
          s_hReactorJob = job.Schedule(s_aReactorExecParams.Length, 32);
          JobHandle.ScheduleBatchedJobs();
        }
        Profiler.EndSample();

        Profiler.BeginSample("Update Fields (CPU)");
        foreach (var itField in fieldMap)
        {
          var field = itField.Value;
          switch (field.HardwareMode)
          {
            case BoingReactorField.HardwareModeEnum.CPU:
              field.ExecuteCpu(dt);
              break;
          }
        }
        Profiler.EndSample();

        Profiler.BeginSample("Update Field Samplers");
        foreach (var itSampler in cpuSamplerMap)
        {
          var sampler = itSampler.Value;
          //sampler.SampleFromField();
        }
        Profiler.EndSample();

        s_reactorJobNeedsGather = true;
      }
    }

    #endregion // Reactor


    #region Bones

    // use fixed time step for bones because they involve collision resolution
    internal static void ExecuteBones
    (
      BoingEffector.Params[] aEffectorParams, 
      Dictionary<int, BoingBones> bonesMap, 
      BoingManager.UpdateTiming updateTiming
    )
    {
      Profiler.BeginSample("Update Bones (Execute)");

      foreach (var itBones in bonesMap)
      {
        var bones = itBones.Value;
        if (bones.UpdateTiming != updateTiming)
          continue;

        bones.PrepareExecute();

        for (int i = 0; i < aEffectorParams.Length; ++i)
          bones.AccumulateTarget(ref aEffectorParams[i]);
        bones.EndAccumulateTargets();

        switch (bones.UpdateMode)
        {
          case BoingManager.UpdateMode.Update:
            bones.Params.Execute(bones, BoingManager.DeltaTime);
            break;

          case BoingManager.UpdateMode.FixedUpdate:
            for (int iteration = 0; iteration < BoingManager.NumFixedUpdateIterations; ++iteration)
              bones.Params.Execute(bones, BoingManager.FixedDeltaTime);
            break;
        }
      }

      Profiler.EndSample();
    }

    internal static void PullBonesResults
    (
      BoingEffector.Params[] aEffectorParams,
      Dictionary<int, BoingBones> bonesMap, 
      BoingManager.UpdateTiming updateTiming
    )
    {
      Profiler.BeginSample("Update Bones (Pull Results)");

      foreach (var itBones in bonesMap)
      {
        var bones = itBones.Value;
        if (bones.UpdateTiming != updateTiming)
          continue;

        bones.Params.PullResults(bones);
      }

      Profiler.EndSample();
    }

    #endregion // Bones
  }
}

#endif
