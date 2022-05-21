Example: 
UFO Bunny

This file contains instructions on how to set up effects demonstrated in this example.
For a general overview of Boing Kit, please refer to README.txt under Boing Kit's root folder.


Instructions:

Add a Boing Bones component to the character.

In the inspector window, resize the bone chain list size to be 9, 
because we need to add 9 different transforms as bone chain roots for effect propagation:
Roots of ears (left & right), roots of hair (3 bangs & 2 tails), root of tail, root of antenna.
This alone should already add bouncy bones effects to the character.

Add a Boing Collider component to each of the appropriate child transform of the character: head and body.
They are meant to prevent penetration of bouncy bones against the character's own body.

Add the Boing Collider components to the Boing Colliders list under the Boing Bones component in the inspector window.
Check the Boing Kit Collision option under bone chains in the inspector window. This will make the bone chains collide with the colliders.
Check the Inter-Chain Collision option under bone chains. This will make bone chains collide with each other.
Adjust the collision radius and collision radius curve so that the bones' own colliders match the shape of the character's mesh. The collision radius can be visualized by checking the Raw Bones option under the Debug Draw section in the inspector window.

Add the colliders of the spinning cross object to the Unity Colliders list under the Boing Bones component in the inspector window.
Check the Unity Collision option under bone chains in the inspector window. This will make the bone chains collide with Unity's standard colliders.

As for moving the character and creating a grass field that reacts to the character's effector, please refer to README.txt under the Bush Field Follow example folder.
