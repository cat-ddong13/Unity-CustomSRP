using UnityEditor;
using UnityEngine;

namespace Rendering.CustomSRP.Runtime
{
    internal partial class PostFXRenderer
    {
        private partial void ApplySceneViewState();

#if UNITY_EDITOR

        private partial void ApplySceneViewState()
        {
            // 忽略不支持后处理的scene窗口
            if (camera.cameraType == CameraType.SceneView &&
                !SceneView.currentDrawingSceneView.sceneViewState.imageEffectsEnabled)
            {
                settings = null;
            }
        }

#endif
    }
}