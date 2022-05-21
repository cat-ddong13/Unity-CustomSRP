Example: 
Jellyfish UFO Bunny

This file contains instructions on how to set up effects demonstrated in this example.
For a general overview of Boing Kit, please refer to README.txt under Boing Kit's root folder.


Instructions:

For how to set up bouncy bones for the base UFO Bunny, see README.txt under the UFO Bunny example folder.

Add a second Boing Bones component to the character.
This time, use a bone chain list size of 8.
Set the root of each bone chain to be the root transform of each tentacle.
Set up the collision radius of each bone chain to properly match the shape of the mesh.
Check the Inter-Chain Collision open of each bone chain to prevent tentacles from inter-penetrating.
