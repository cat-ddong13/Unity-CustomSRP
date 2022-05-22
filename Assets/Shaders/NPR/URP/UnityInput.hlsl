#ifndef CUSTOM_UNITY_INPUT_INCLUDED
#define CUSTOM_UNITY_INPUT_INCLUDED

CBUFFER_START(UnityPerDraw)

// float4x4 unity_ObjectToWorld;
// float4x4 unity_WorldToObject;
float4x4 unity_MatrixMV;

// x:淡入淡出的渐变因子,范围[0,1]
// y:淡入淡出的渐变因子,范围[0,15/16]，分16个级别0/16、1/16…15/16
// float4 unity_LODFade;
// 模型的scale值是三维向量，即xyz，当这三个值中有奇数个值为负时（1、3个），unity_WorldTransformParams.w = -1，否则为1.
// real4 unity_WorldTransformParams;

// y:灯光数
// real4 unity_LightData;
// 每个通道存储一个灯光索引，共8个
// real4 unity_LightIndices[2];

// 通过差值光探测器提供的
// 适用于动态物体的阴影遮罩因子数据
// 范围[0,1]
// float4 unity_ProbesOcclusion;
// HDR环境映射解码指令
// float4 unity_SpecCube0_HDR;

// 光照贴图tilling、offset
// float4 unity_LightmapST;
// float4 unity_DynamicLightmapST;

// 光照探针
// 3阶球谐系数
// float4 unity_SHAr;
// float4 unity_SHAg;
// float4 unity_SHAb;
// float4 unity_SHBr;
// float4 unity_SHBg;
// float4 unity_SHBb;
// float4 unity_SHC;

// 体积探针
// x:是否使用了LPPV(Light Probe Proxy Volume 光探针代理体),Disabled(0)/Enabled(1)
// y:计算过程是发生在世界空间还是本地模型空间，0世界(Global),1模型(local)
// z:采样的体积纹理在u方向上的纹素大小
float4 unity_ProbeVolumeParams;
// LPPV长宽高的倒数
float4 unity_ProbeVolumeSizeInv;
// LPPV左下角的x、y、z坐标
float4 unity_ProbeVolumeMin;
// 定义了从世界空间转换到LPPV模型空间的变换矩阵
float4x4 unity_ProbeVolumeWorldToObject;

// x:对象的渲染层级掩码
// float4 unity_RenderingLayer;

CBUFFER_END

float4x4 unity_MatrixITMV;
// float4x4 unity_MatrixV;
// float4x4 unity_MatrixVP;
// float4x4 glstate_matrix_projection;
// float3 _WorldSpaceCameraPos;
// x = 1或-1 (-1表示投影被翻转)
// y = 近裁剪面
// z = 远裁剪面
// w = 1/远裁剪面
// float4 _ProjectionParams;
// xy: 正交摄像机的宽度和高度 z:没有定义
// w:1.0(正交摄像机) w:0.0(透视摄像机)
// float4 unity_OrthoParams;

// 屏幕参数，单位为像素
// x = width
// y = height
// z = 1 + 1.0 / width
// w = 1 + 1.0 / height
// float4 _ScreenParams;

// ZBuffer线性化(http://www.humus.name/temp/Linearize%20depth.txt)
// x = 1-far/near
// y = far/near
// z = x/far
// w = y/far
// 如果是Z反转的话(UNITY_REVERSED_Z == 1)
// x = -1+far/near
// y = 1
// z = x/far
// w = 1/far
// float4 _ZBufferParams;

#endif
