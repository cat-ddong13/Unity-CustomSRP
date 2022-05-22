### 这是一个有关于Unity自定义可编程渲染管线的基础系列教程。

该教程涉及到一个简单的渲染管线的搭建，各种光源和阴影的计算与着色，DrawCall和几种Batching的方式，复杂的多贴图及相关遮罩，多相机的渲染和堆叠相机的解决方案，一个简洁的后处理系统包括了Bloom、ColorGrading、ToneMapping、FXAA的简单实现等等…对于了解Unity的渲染流程和CPU-GPU沟通协作方式有着很好的帮助。

本文主要取自[Catlike Coding](https://catlikecoding.com/unity/tutorials/custom-srp/)的系列教程，并根据自己的理解和习惯对部分代码结构进行了简单的重构和细节上的调整，之后有时间应该会对原文中介绍不够详细或没有介绍到的一些技术和实现另外开贴。

(*本系列教程使用的是Unity 2021.3.1f1c1 版本*)

--------------------------------------------------------------------------------------------
# 我的简书

- ### [cat-ddong13](https://github.com/cat-ddong13)

--------------------------------------------------------------------------------------------
![](https://upload-images.jianshu.io/upload_images/27923821-612de28636877d03.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1024)![](https://upload-images.jianshu.io/upload_images/27923821-bc9d9ec53cc52d85.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1024)![效果图](https://upload-images.jianshu.io/upload_images/27923821-449e471d11802d85.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1024)

--------------------------------------------------------------------------------------------

### 相关参考资料

- **[Catlike Coding](https://catlikecoding.com/unity/tutorials/custom-srp/)**
- **[Candy Cat-《UnityShader入门精要》 冯乐乐](https://github.com/candycat1992)**
- **[HLSL 文档](https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl)**
- **[Unity官方手册](https://docs.unity3d.com/Manual/Graphics.html)**
- **[CG 文档](https://developer.download.nvidia.com/cg/index.html)**
- **[线性代数的本质](https://www.bilibili.com/video/BV1Ys411k7yQ?share_source=copy_web)**
- **《3D数学基础:图形与游戏开发》**

--------------------------------------------------------------------------------------------
# 更新
- 2022.5.15 更新基于ShellMethods/Z-Bias/VertexNormal的三种顶点法描边
- 2022.5.16 更新基于后处理+Sobel算子的描边
- 2022.5.17 更新基于后处理+图像深度检测的描边
- 2022.5.19 添加了Cel-Shading卡通着色+高光+边缘光
- 2022.5.20 更新了Cel-Shading表面阴影部分的融合方式，代码整理并更改了一些参数
- 2022.5.22 更新眼球跟随相机的shader实现(简化了计算模型)、添加动骨插件给头发加了点动态效果
- 2022.5.23 更新卡通渲染到URP管线、添加一个草地场景
