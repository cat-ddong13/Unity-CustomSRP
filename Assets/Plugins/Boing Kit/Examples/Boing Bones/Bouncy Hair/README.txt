Example: 
Bouncy Hair

This file contains instructions on how to set up effects demonstrated in this example.
For a general overview of Boing Kit, please refer to README.txt under Boing Kit's root folder.


Instructions:

Add a Boing Bones component to the character.

In the inspector window, resize the bone chain list size to be 8, 
because we need to add 8 different transforms as bone chain roots for effect propagation:
Roots of hair tails (left & right), roots of front hair (left & right), roots of side hair (left & right), roots of head ribbons (left & right).
This alone should already add bouncy bones effects to the character.

Add a Boing Collider component to each of the appropriate child transform of the character: head, upper arms, lower arms, torso, and pelvis.
They are meant to prevent penetration of bouncy bones against the character's own body.

Add the Boing Collider components to the Boing Colliders list under the Boing Bones component in the inspector window.
Check the Boing Kit Collision option under bone chains in the inspector window. This will make the bone chains collide with the colliders.
Check the Inter-Chain Collision option under bone chains. This will make bone chains collide with each other.
Adjust the collision radius and collision radius curve so that the bones' own colliders match the shape of the character's mesh. The collision radius can be visualized by checking the Raw Bones option under the Debug Draw section in the inspector window.
