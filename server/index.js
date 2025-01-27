/**
 * Main program to run the maze server
 *
 */
import maze from './maze.js'
// const maze = require("./maze");

const port = 1337

maze.listen(port)

console.log('The maze server is now listening on: ' + port)
