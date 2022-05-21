Example: 
Platform Collectibles

This file contains instructions on how to set up effects demonstrated in this example.
For a general overview of Boing Kit, please refer to README.txt under Boing Kit's root folder.


Instructions:

Add a script to the character that moves the character around based on player input (WASD.cs).

Add a head to the character.

Add a Boing Behavior component to the character's head.
This will make the character's head follow the character's body in a bouncy manner.

Add a Boing Effector component to the character.

Add a script that spawns bushes and flowers which react to the character's effector.
For more details, see README.txt in the Bush Field example folder.

Add a script that spawns the coins (PlatformerCollectiblesMain).

Add a Boing Behavior script to the coin prefab.
Add a script that controls each coin to the coin prefab (CollectibleCoin.cs).
This script spins the coin, as well as bounce it to the screen's top left corner  when collected by the character.
To do so, the script resets the Boing Behavior component's position spring velocity, 
and it sets the coin's position to the screen's top left corner.
The Boing Behavior component will handle the rest and apply a smooth bouncy transition over time.
After a while, the script respawns the coin by setting it back to its original position.
The script also calls the Boing Behavior component's Reboot() method to reset all internal data.
