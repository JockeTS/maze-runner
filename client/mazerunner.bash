#!/usr/bin/env bash

# Make working directory that of script location
cd "$(dirname "$0")"

# Name of script (from filename)
SCRIPT=$( basename "$0" )

VERSION="1.0.0"

PORT="1337"

BASE_URL="localhost:${PORT}"

# "--version" : Display the current version
function showVersion
{
    local txt=(
        "$SCRIPT version $VERSION"
    )

    printf "%s\\n" "${txt[@]}"
}

# "init" : Initialize a new game
function initGame
{
    # Reset game files
    echo "" > "state/game.csv"
    echo "" > "state/maps.csv"
    echo "" > "state/response.csv"
    echo "0" > "state/room.txt"
    
    # Get game id from server and save it to file
    curl -s -o "state/game.csv" "${BASE_URL}?type=csv"

    # Get map list from server and save it to file
    curl -s -o "state/maps.csv" "${BASE_URL}/map?type=csv"

    # Display welcome text
    local txt
    txt=$(cat "state/game.csv" | cut -d "," -f 1 | tail -n1)
    printf "%s\\n" "${txt[@]}"
}

# "maps" : Display available maps from file
function showMaps
{
    local txt=(
        "Available maps:"
        "1: $(cat "state/maps.csv" | cut -d "," -f 1 | tail -n1)"
        "2: $(cat "state/maps.csv" | cut -d "," -f 2 | tail -n1)"
    )

    printf "%s\\n" "${txt[@]}"
}

# "select <map number>" : Load game with selected map
function selectMap
{
    # Get game id from file
    gameId=$(getGameId)

    # Get name of selected map from file
    selectedMap=$(cat "state/maps.csv" | cut -d "," -f "$1" | tail -n1)

    # Load game on server with selected map, save response to file
    curl -s -o "state/response.csv" "${BASE_URL}/${gameId}/map/${selectedMap}?type=csv"

    # Display server response from file
    local txt
    txt=$(cat "state/response.csv" | cut -d "," -f 1-2 | tail -n1 | tr "," "\n")
    printf "%s\\n" "${txt[@]}"
}

# "enter" : Enter maze and get content of first room
function enterMaze
{
    gameId=$(getGameId)

    # Save server response when starting game to file
    curl -s -o "state/response.csv" "${BASE_URL}/${gameId}/maze?type=csv"

    showRoomInfo
}

# "info" : show info about current room
function showRoomInfo
{
    gameId=$(getGameId)
    currentRoomId=$(getCurrentRoomId)

    # Contact server and save response to file
    curl -s -o "state/response.csv" "${BASE_URL}/${gameId}/maze/${currentRoomId}?type=csv"

    # Display movement options from file
    local txt=(
    "You're in room ${currentRoomId}."
    "You can move as follows:"
        "  West:                    $(cat "state/response.csv" | cut -d "," -f 3 | tail -n1)"
        "  East:                    $(cat "state/response.csv" | cut -d "," -f 4 | tail -n1)"
        "  South:                   $(cat "state/response.csv" | cut -d "," -f 5 | tail -n1)"
        "  North:                   $(cat "state/response.csv" | cut -d "," -f 6 | tail -n1)"
    )

    printf "%s\\n" "${txt[@]}"
}

# "go <direction>" : move to room in selected direction
function moveInMaze
{
    gameId=$(getGameId)
    currentRoomId=$(getCurrentRoomId)

    # Save server response to file
    curl -s -o "state/response.csv" "${BASE_URL}/${gameId}/maze/${currentRoomId}/$1?type=csv"

    # Check for failure or success from file
    failure=$(cat "state/response.csv" | grep -E -o "Path dont exist")
    success=$(cat "state/response.csv" | grep -E -o "You found the exit")

    # If valid movement: update currentRoomId (save to file)
    if [ "$failure" ]
    then
        echo "Noclip not enabled. Pick a valid direction."
    elif [ "$success" ]
    then
        currentRoomId=$(cat "state/response.csv" | cut -d "," -f 1 | tail -n1)
        echo "$currentRoomId" > "state/room.txt"
        echo "Congratulations. You found the exit."
        exit 0
    else
        currentRoomId=$(cat "state/response.csv" | cut -d "," -f 1 | tail -n1)
        echo "$currentRoomId" > "state/room.txt"
        showRoomInfo
    fi
}

# Get game id from file
function getGameId
{
    local gameId
    gameId=$(cat "state/game.csv" | cut -d "," -f 2 | tail -n1)
    echo "$gameId"
}

# Get current room id from file
function getCurrentRoomId
{
    local currentRoomId
    currentRoomId=$(cat "state/room.txt")
    echo "$currentRoomId"
}

# Continuous command loop
function commandLoop
{
    case "$1" in
        select)
            echo "Select map and press enter: "
            read -r
            selectMap "$REPLY"
            enterMaze
            commandLoop "overview"
        ;;

        overview)
            echo "Enter command (west, east, south, north | info, help, done) and press enter: "
            read -r
            commandLoop "$REPLY"
        ;;

        west | east | south | north)
            moveInMaze "$1"
            commandLoop "overview"
        ;;

        info)
            showRoomInfo
            commandLoop "overview"
        ;;

        help)
            echo "You're lost in a dark maze. Did you really expect any help?"
            commandLoop "overview"
        ;;

        done)
            echo "Not OK to quit before exiting the maze..."
            exit 0
        ;;
    esac
}

# Stand-alone commands
function main
{
while (( $# ))
    do
        case "$1" in
            --version | -v)
                showVersion
                exit 0
            ;;

            loop)
                initGame
                showMaps
                commandLoop "select"
                exit 0
            ;;

            init)
                initGame
                exit 0
            ;;

            maps)
                showMaps
                exit 0
            ;;

            select)
                shift
                selectMap "$1"
                exit 0
            ;;

            enter)
                enterMaze
                exit 0
            ;;

            info)
                showRoomInfo
                exit 0
            ;;

            go)
                shift
                moveInMaze "$1"
                exit 0
            ;;

            *)
                echo "Option / Command not recognized."
                showHelp
                exit 1
            ;;

        esac
    done
}

main "$@"
