### 这是一个有关于Unity自定义可编程渲染管线的基础系列教程。

该教程涉及到一个简单的渲染管线的搭建，各种光源和阴影的计算与着色，DrawCall和几种Batching的方式，复杂的多贴图及相关遮罩，多相机的渲染和堆叠相机的解决方案，一个简洁的后处理系统包括了Bloom、ColorGrading、ToneMapping、FXAA的简单实现等等…对于了解Unity的渲染流程和CPU-GPU沟通协作方式有着很好的帮助。

本文主要取自[Catlike Coding](https://catlikecoding.com/unity/tutorials/custom-srp/)的系列教程，并根据自己的理解和习惯对部分代码结构进行了简单的重构和细节上的调整，之后有时间应该会对原文中介绍不够详细或没有介绍到的一些技术和实现另外开贴。

同时我也有一篇关于原文的翻译帖正在更新中，想要一步一步去理解和实现的可以在下边找到译文的链接，想要阅读原作的也可以去[Catlike Coding](https://catlikecoding.com/unity/tutorials/custom-srp/)的小屋里学习。

文末给出了给予我很大帮助的链接。

在代码中做了很详细的注释，就不过多叙述(主要是懒)，直接上代码链接了。

(*本系列教程使用的是Unity 2021.3.1f1c1 版本*)

--------------------------------------------------------------------------------------------
# 我的简书

- ### [cat-ddong13](https://github.com/cat-ddong13)

--------------------------------------------------------------------------------------------

# 代码结构

### Custom RP/Editor：

CustomLightEditor.cs
CustomShaderGUI.cs
RenderingLayerMaskDrawer.cs

### Custom RP/Runtime：

CameraBufferSettings.cs
CameraRenderer.cs
CameraRenderer.Editor.cs
CameraSettings.cs
CustomRenderPipeline.cs
CustomRenderPipeline.Editor.cs
CustomRenderPipelineAsset.cs
CustomRenderPipelineAsset.Editor.cs
CustomRenderPipelineCamera.cs
CustomShaderKeywords.cs
CustomShaderPropertyId.cs
CustomShaderTagIds.cs
DrawGizmos.cs
EnumPasses.cs
Lighting.cs
PostFXBloom.cs
PostFXColorGradingTonemapping.cs
PostFXRenderer.cs
PostFXRenderer.Editor.cs
PostFXSettings.cs
ReinterpretExtensions.cs
RenderingLayerMaskFieldAttribute.cs
Shadows.cs
ShadowSettings.cs

### Custom RP/ShaderLibrary：

BRDF.hlsl
Common.hlsl
Fragment.hlsl
GI.hlsl
Light.hlsl
Lighting.hlsl
Shadows.hlsl
Surface.hlsl
UnityInput.hlsl

### Custom RP/Shaders：

CameraRender.shader
CameraRenderPasses.hlsl
FXAAPass.hlsl
Lit.shader
LitInput.hlsl
LitPass.hlsl
MetaPass.hlsl
PostFX.shader
PostFXPasses.hlsl
ShadowCasterPass.hlsl
UICustomBlending.shader
Unlit.shader
UnlitInput.hlsl
UnlitParticles.shader
UnlitPass.hlsl

--------------------------------------------------------------------------------------------
![](https://upload-images.jianshu.io/upload_images/27923821-612de28636877d03.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1024)![](https://upload-images.jianshu.io/upload_images/27923821-bc9d9ec53cc52d85.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1024)![效果图](https://upload-images.jianshu.io/upload_images/27923821-449e471d11802d85.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1024)

--------------------------------------------------------------------------------------------

### 相关参考资料

- **[Catlike Coding](https://catlikecoding.com/unity/tutorials/custom-srp/)**
- **[Candy Cat-《UnityShader入门精要》 冯乐乐](https://github.com/candycat1992)**
- **[HLSL 文档](https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl)**
- **[Unity官方手册](https://docs.unity3d.com/Manual/Graphics.html)**
- **[CG 文档](https://developer.download.nvidia.com/cg/index.html)**
- **《3D数学基础:图形与游戏开发》**

--------------------------------------------------------------------------------------------