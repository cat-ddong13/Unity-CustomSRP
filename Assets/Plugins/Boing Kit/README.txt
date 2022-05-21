Boing Kit - Bouncy VFX Tools for Unity

Publisher:
  Long Bunny Labs
    LongBunnyLabs@gmail.com
    http://LongBunnyLabs.com

Examples:
  For step-by-step instructions on how to set up effects demonstrated in individual examples, 
  please refer to the README.txt file located in each of the example folder.

Tooltips:
  If you need details on a specific component property, 
  please hover the mouse cursor over the property in the editor's inspector, 
  which will cause the tooltip for the property to who up.

If you run into any issues with Boing Kit, please feel free to email me at LongBunnyLabs@gmail.com.
I'd be more than happy to help.


---------------------------------------------------------------------------------------------------

Overview & Quick Start:

  [Shared Boing Params]

    This is a data structure that contains parameters that Boing Kit uses to create bouncy effects. 

    For example, it contains parameters like oscillation frequency and decay rate.

    Each component Boing Kit provides can either use its own local parameters, or use a 
    Shared Boing Params asset created by right clicking in the Project window, and then select 
    Create > Boing Kit > Shared Boing Params.


  [Boing Behavior]

    Add this component to make objects bouncy in reaction to position & rotation change.

    Any change to an object's transform (position & rotation) during its Update function will be 
    picked up by this component and used to create bouncy effects during LateUpdate.

    For example, once this component is added to an object that can be dragged by the mouse, 
    the object will lag behind the mouse cursor as if there's a spring attached between 
    the object and the mouse cursor.


  [Boing Effector]

    Add this component to affect game objects with Boing Reactor components. 

    See the Boing Reactor section below for furtherinformation.


  [Boing Reactor]
    
    Add this component to be affected by game objects with Boing Effector components.

    Once this component is added to an object, the object will not only exhibit behaviors from 
    the Boing Behavior component, but will also be affected by nearby objects with the 
    Boing Effector component.


  [Boing Reactor Field]

    Add this component to create a "proxy grid" of reactors affected by effectors.

    The reactor field component is an alternative to making effectrs affect objects, 
    and is an optimization for certain use cases. The trade-off is that the reactor 
    field only works within a limited area defined by a grid's dimensions and cell size.

    This is good for making effects affect a large amount of objects with the
    Boing Reactor Field sampler component (mentioned below).
    Also, reactor field can be sampled by shaders (powered by the GPU).

    Before starting to play with reactor field propagation, please make sure you are familiar 
    with the basics of how effectors and reactor fields interact first.


  [Boing Reactor Field Sampler]

    Add this component to sample from a reactor field and be affected by effectors.

    Instead of directly being affected by effectors, reactor field sampler works by 
    letting the "proxy grid" of reactors in the reactor field be affected by the effectors, 
    and then sampling from the field to apply the effects to the objects with samplers.

    If using the GPU sampler on an object, it must use a material with a shader that calls the 
    ApplyBoingReactorFieldPerObject or ApplyBoingReactorFieldPerVertex shader functions in the 
    vertex shader. Boing Kit comes with example shaders that already properly call these functions, 
    modified from Unity's standard shader. To see how to call these functions in custom vertex 
    shaders, please check out the Example Custom Shader files in the Warped Teapots example.


  [Boing Bones]

    Add this component to create bouncy hierarchies of skeletal bones or object transforms.

    The very first step is to specify the root transform of a bone chain. The bouncy effects will 
    begin at the root and then propagate throughout the entire hierarchy.

    Multiple chains, each having its own root, can be specified for each Bouncy Bones component.

    Boing Bones can react to lightweight colliders provided by Boing Kit added to the 
    Boing Colliders section in the inspector. Boing Bones can also react to Unity's standard 
    colliders added to the Unity Collider section.

    Boing Bones can also react to Boing Effectors, just like Boing Reactors.


---------------------------------------------------------------------------------------------------

FAQ

  Q: The effects on the grass field and explosion/implosion field in Boing Kit's examples 
     are not working.

  A: This is due to an issue with certain versions of Unity, where material property blocks passed 
     in for instanced mesh rendering are not respected. This has been fixed since Unity 2018.3.

  --

  Q: Boing bones doesn't seem to work well with other procedural animation assets, like Final IK.

  A: Proceduarl animation assets, including Boing Kit, update during the LateUpdate phase.
     There is no guaranteed update order of procedural animation assets unless specified.
     Boing Kit's update needs to happen after all other procedural animation assets.
     This can be set up via the Unity option: Edit > Project Settings > Script Execution Order.

  --

  Q: Materials in the examples are not rendered properly under scriptable render pipeline (SRP), 
     including Unity's LWRP and HDRP.

  A: Materials included in the examples are targeted at the standard render pipeline.
     It is recommended that you try out the examples under Unity's standard render pipeline first.
     In order for GPU-based reactor field samplers to work in scriptable render pipelines, 
     you'd have to call the shader functions provided by Boing Kit in your vertex shaders, 
     as shown in the example shaders.
     The functions are ApplyBoingReactorFieldPerObject and ApplyBoingReactorFieldPerVertex.
     For usage examples, please check out the Example Custom Shader files under the Warped Teapots example.
