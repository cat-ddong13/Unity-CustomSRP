Example: 
Warped Teapots

This file contains instructions on how to set up effects demonstrated in this example.
For a general overview of Boing Kit, please refer to README.txt under Boing Kit's root folder.


Instructions:

Create an empty object and add a Boing Reactor Field component to it.

Create some spheres and add a Boing Effector component to each one of them.
Add the effectors to the reactor field's effector list in the inspector window.

Add a script to each sphere that pops them around periodically (Oscillator.cs).

Create some teapots and apply to them a custom material using a custom shader.

Add a Boing Reactor Field GPU Sampler component to each of the teapot.
Assign the reactor field to the Boing Reactor Field GPU Sampler component in the inspector window.
This will case the sampler to sample the reactor field, and update its shader constants appropriately.

For blue teapots, their vertex shader sample the reactor field using the ApplyBoingReactorFieldPerObject shader function. This makes every vertex sample the same position in the reactor field, resulting in the teapots being translated and rotated as a whole.

For purple teapots, their vertex shader sample the reactor field using the ApplyBoingReactorFieldPerVertex shader function. This makes every vertex sample the reactor field at its own position, so each vertex is transformed differently, resulting in the teapots being warped and distorted.
