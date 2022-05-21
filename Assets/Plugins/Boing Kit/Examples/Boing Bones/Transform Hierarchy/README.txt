Example: 
Transform Hierarchy

This file contains instructions on how to set up effects demonstrated in this example.
For a general overview of Boing Kit, please refer to README.txt under Boing Kit's root folder.


Instructions:

The Boing Bones component not only works on skeletal bones, but also on ordinary transform hierarchies.

Set up a transform hierarchy (objects parented to other objects).

Add a Boing Bones component to the root object.

Set the bone chain list size to 1, and set the root object's transform as the root of the bone chain.

Move the root object around in play mode, and the parented objects shall react to the movement in a bouncy manner.
