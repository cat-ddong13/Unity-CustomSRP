/******************************************************************************/
/*
  Project   - Boing Kit
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

#ifndef BOING_KIT_CORE
#define BOING_KIT_CORE

#include "SpringFloat4.cginc"

#define kEffectorFlagContinuousMotion         (1 << 0)

#define kReactorFlagTwoDDistanceCheck         (1 << 0)
#define kReactorFlagTwoDPositionInfluence     (1 << 1)
#define kReactorFlagTwoDRotationInfluence     (1 << 2)
#define kReactorFlagEnablePositionEffect      (1 << 3)
#define kReactorFlagEnableRotationEffect      (1 << 4)
#define kReactorFlagGlobalReactionUpVector    (1 << 5)
#define kReactorFlagEnablePropagation         (1 << 6)
#define kReactorFlagAnchorPropagationAtBorder (1 << 7)

#define kPlaneXY 0
#define kPlaneXZ 1
#define kPlaneYZ 2

#define kParameterModeExponential               0
#define kParameterModeOscillationByHalfLife     1
#define kParameterModeOscillationByDampingRatio 2

// 80 bytes
struct Effector
{
  // bytes 0-47 (48 bytes)
  float4 prevPosition;
  float4 currPosition;
  float4 linearVelocityDir;

  // bytes 48-63 (16 bytes)
  float radius;
  float fullEffectRadius;
  float moveDistance;
  float linearImpulse;

  // bytes 64-79 (16 bytes)
  float rotateAngle;
  float angularImpulse;
  int bits;
  int m_padding0;
};

// 32 bytes
struct SpringVector3
{
  // bytes 0-15 (16 bytes)
  float4 value;

  // bytes 16-31 (16 bytes)
  float4 velocity;
};

// 192 bytes
struct InstanceData
{
  // 0-63 (64 bytes)
  float4 positionTarget;
  float4 positionOrigin;
  float4 rotationTarget;
  float4 rotationOrigin;

  // bytes 64-79 (16 bytes)
  int4 intData; // (numEffectors, instantAccumulation, *, *)

  // bytes 80-95 (16 bytes)
  float4 upWs;

  // bytes 96-159 (64 bytes)
  SpringFloat4 positionSpring;
  SpringFloat4 rotationSpring;

  // bytes 160 - 191 (32 bytes)
  float4 positionPropagationWorkData;
  float4 rotationPropagationWorkData;
};

// 288 bytes
struct ReactorParams
{
  // bytes 0-15 (16 bytes)
  int instanceId; // unused
  int bits;
  int twoDPlane;
  int padding0;

  // bytes 16-31 (16 bytes)
  int positionParameterMode;
  int rotationParameterMode;
  int padding1;
  int padding2;

  // bytes 32-79 (48 bytes)
  float positionExponentialHalfLife;
  float positionOscillationHalfLife;
  float positionOscillationFrequency;
  float positionOscillationDampingRatio;
  float moveReactionMultiplier;
  float linearImpulseMultiplier;
  float rotationExponentialHalfLife;
  float rotationOscillationHalfLife;
  float rotationOscillationFrequency;
  float rotationOscillationDampingRatio;
  float rotationReactionMultiplier;
  float angularImpulseMultiplier;

  // bytes 80-95 (16 bytes)
  float4 rotationReactionUp;

  // bytes 96-287 (192 bytes)
  InstanceData Instance;
};

// 112 bytes
struct FieldParams
{
  int4 nums;          // (numCells.xyz, numEffectors)
  int4 cellData;      // (iCellBase.xyz, *)
  int4 intData;       // (falloffMode, falloffDimensions, propagationDepth, *)
  float4 gridCenter;  // (gridCenter.xyz, *)
  float4 upWs;        // (upWs.xyz, *)
  float4 fieldCenter; // (fieldPos.xyz, *)
  float4 floatData;   // (falloffRatio, cellSize, dt, *)
};

#define kFalloffNone   0
#define kFalloffCircle 1
#define kFalloffSquare 2

#define kFalloffXYZ 0
#define kFalloffXY  1
#define kFalloffXZ  2
#define kFalloffYZ  3

#endif
