# Maze Runner

## Description
A Bash script where the goal is to navigate your way out of a maze. 
The script connects to a server hosting a maze game and lets the user navigate the maze using commands.
This can be done either through stand-alone commands or by entering a continuous command loop.
The script interacts with the server using **cURL** to retrieve data and update game files.

## Quick Start
* git clone https://github.com/JockeTS/maze-runner.git
* cd maze-runner/
* Start Server: node ./server/index.js
* Start Maze Runner: ./client/mazerunner.bash loop

There are two maps, start with "small-maze" to get familiar with the commands.
When you feel brave enough, give "maze-of-doom" a try and make sure to bring a torch!