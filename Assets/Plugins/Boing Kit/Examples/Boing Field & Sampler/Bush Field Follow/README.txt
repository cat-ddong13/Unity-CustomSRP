Example: 
Bush Field Follow

This file contains instructions on how to set up effects demonstrated in this example.
For a general overview of Boing Kit, please refer to README.txt under Boing Kit's root folder.


Instructions:

Add a script to the character that moves it around based on user input (WASD.cs).

Add a Boing Effector component to the character.

Add a Boing Reactor Field to an object parented under the character.
Alternatively, you can just add a reactor field directly to the character.
Add the character's effector to the list of effectors under the reactor field in the inspector (list titled Effectors).
This makes the reactor field follow the character around, keeping the effects visible around the character.
The character's effector will apply effects to the reactor field around the character.

In BushFieldReactorFieldMain.cs:

Create a script that instantiates additional spheres that move along circular paths.
Add a Boing Effector component to each sphere, and then add it to the effector list of the character's reactor field.

Instantiate flowers with Boing Reactor Field CPU Sampler components that sample the rector field.
This will make the flowers sample effects from the reactor field, making the flowers react to effectors as a whole (their transforms are modified).

Create a material property block to be passed in the reactor field's UpdateShaderConstants method to be updated.
Use this material property block to render instanced bushes.
Use a Boing Kit material or a custom material with its vertex shader calling ApplyBoingReactorFieldPerVertex or ApplyBoingReactorFieldPerObject.
For more detailed shader usage, please look at the Example Custom Shader files.
