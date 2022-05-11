using Unity.Collections;
using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;
using Lightmapping = UnityEngine.Experimental.GlobalIllumination.Lightmapping;
using LightType = UnityEngine.LightType;

namespace Rendering.CustomSRP.Runtime
{
    internal partial class CustomRenderPipeline
    {
        private partial void InitializeForEditor();
        private partial void DisposeForEditor();

        private static Lightmapping.RequestLightsDelegate LightsDelegate =
            (Light[] lights, NativeArray<LightDataGI> output) =>
            {
#if UNITY_EDITOR
                var lightData = new LightDataGI();

                for (int i = 0; i < lights.Length; i++)
                {
                    var light = lights[i];
                    switch (light.type)
                    {
                        case LightType.Directional:
                            var directionalLight = new DirectionalLight();
                            LightmapperUtils.Extract(light, ref directionalLight);
                            lightData.Init(ref directionalLight);
                            break;
                        case LightType.Point:
                            var pointLight = new PointLight();
                            LightmapperUtils.Extract(light, ref pointLight);
                            lightData.Init(ref pointLight);
                            break;
                        case LightType.Spot:
                            var spotLight = new SpotLight();
                            LightmapperUtils.Extract(light, ref spotLight);
                            spotLight.innerConeAngle = light.innerSpotAngle * Mathf.Deg2Rad;
                            spotLight.angularFalloff = AngularFalloffType.AnalyticAndInnerAngle;
                            lightData.Init(ref spotLight);
                            break;
                        case LightType.Area:
                            var rectangleLight = new RectangleLight();
                            LightmapperUtils.Extract(light, ref rectangleLight);
                            rectangleLight.mode = LightMode.Baked;
                            lightData.Init(ref rectangleLight);
                            break;
                        case LightType.Disc:
                            var discLight = new DiscLight();
                            LightmapperUtils.Extract(light, ref discLight);
                            discLight.mode = LightMode.Baked;
                            lightData.Init(ref discLight);
                            break;
                        default:
                            lightData.InitNoBake(light.GetInstanceID());
                            break;
                    }

                    lightData.falloff = FalloffType.InverseSquared;
                    output[i] = lightData;
                }
#else
            LightDataGI lightData = new LightDataGI();

            for (int i = 0; i < lights.Length; i++)
            {
                Light light = lights[i];
                lightData.InitNoBake(light.GetInstanceID());
                output[i] = lightData;
            }
#endif
            };

#if UNITY_EDITOR

        private partial void InitializeForEditor()
        {
            Lightmapping.SetDelegate(LightsDelegate);
        }

        private partial void DisposeForEditor()
        {
            Lightmapping.ResetDelegate();
        }

#endif
    }
}