using UnityEngine;

namespace Rendering.CustomSRP.Runtime
{
    [DisallowMultipleComponent, RequireComponent(typeof(Camera))]
    public class CustomRenderPipelineCamera : MonoBehaviour
    {
        [SerializeField] private CameraSettings cameraSettings = default;
        internal CameraSettings Settings => cameraSettings ??= new CameraSettings();
    }
}