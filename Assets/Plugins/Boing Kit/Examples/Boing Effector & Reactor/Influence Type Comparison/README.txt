Example: 
Influence Type Comparison

This file contains instructions on how to set up effects demonstrated in this example.
For a general overview of Boing Kit, please refer to README.txt under Boing Kit's root folder.


Instructions:

Add a script to the sphere that moves it around based on player input (WASD.cs).

Add a Boing Effector component to the sphere.
This will make it push the bushes around.

Create 4 patches of bushes.
Add a Boing Reactor component to each bush.

For each bush in the same patch, use the same parameters for its Boing Reactor component.

In this example, each patch only has one of the following effects enabled:
Position, rotation, linear impulse, and angular impulse.

Move there sphere around in play mode to observe and compare the difference effects.
