#!/bin/bash
#BashJack

#Deck format → hex char [1-9, A-D] + (A → Spade, B →  Heart, C → Diamond, D → Club)
#1A, 2A, 3A... 9A, AA, BA, CA


declare -a deckGlobal=()
card=""
function genDeck(){
    local suits=("♤" "♡" "♢" "♧")
    local values=("A" "2" "3" "4" "5" "6" "7" "8" "9" "10" "J" "Q" "K")
    for suit in "${suits[@]}"; do
        for value in "${values[@]}"; do
            deckGlobal+=("$value$suit")
        done
    done
    
}

function shuffleDeck(){
    local shuffledDeck=()
    declare -g deckGlobal
    
    while [ ${#deckGlobal[@]} -gt 0 ]; do
        local randIndex=$((RANDOM % ${#deckGlobal[@]}))
        shuffledDeck+=("${deckGlobal[$randIndex]}")
        unset 'deckGlobal[$randIndex]'
        deckGlobal=("${deckGlobal[@]}")
    done
    
    deckGlobal=("${shuffledDeck[@]}")
}



function calculateHand(){
    local hand=("$@")
    local total=0
    local aces=0
    
    for card in "${hand[@]}"; do
        local value="${card%${card#?}}"
        if [[ "$value" =~ ^[2-9]$ ]]; then
            total=$((total + value))
            elif [[ "$value" == "1" || "$value" == "J" || "$value" == "Q" || "$value" == "K" ]]; then
            total=$((total + 10))
            elif [[ "$value" == "A" ]]; then
            aces=$((aces + 1))
            total=$((total + 11))
        fi
    done
    
    while [ $total -gt 21 ] && [ $aces -gt 0 ]; do
        total=$((total - 10))
        aces=$((aces - 1))
    done
    
    return $total
}
# function dealCard(){
#     # Deal a card from the deck
#     declare -g deckGlobal
#     local card="${deckGlobal[0]}"
#     deckGlobal=("${deckGlobal[@]:1}")
#     echo "$card"
# }

function dealCard(){
    card="${deckGlobal[0]}"
    deckGlobal=("${deckGlobal[@]:1}")
}

function dealCardPlayer(){
    dealCard
    playerHand+=("$card")
}

function dealCardDealer(){
    dealCard
    dealerHand+=("$card")
}

# genDeck
# echo "${deckGlobal[@]}"

# shuffleDeck

# echo "${deckGlobal[@]}"

# echo "$shuffledDeck"

declare -a playerHand
declare -a dealerHand

# dealCardPlayer
# dealCardDealer

# echo "Player Hand: ${playerHand[@]}"
# echo "Dealer Hand: ${dealerHand[@]}"
# dealCardPlayer
# dealCardDealer

function playerHandValue() {
    echo "Player Hand: ${playerHand[@]}"
    calculateHand "${playerHand[@]}"
    local value=$?
    echo "Player Hand Value: $value"
    return $value
}

# playerHandValue

function dealerHandValue() {
    echo "Dealer Hand: ${dealerHand[@]}"
    calculateHand "${dealerHand[@]}"
    local value=$?
    echo "Dealer Hand Value: $value"
    return $value
}

function clearPlayerHand(){
    playerHand=()
}
function clearDealerHand(){
    dealerHand=()
}

selected=0
buttons=("Hit" "Stand")

draw_ui() {
    clear
    tput cup 1 10
    echo "Bet: $bet"
    tput cup 2 10
    echo "Player Hand: ${playerHand[@]}"
    tput cup 3 10
    echo "Dealer Hand: ${dealerHand[@]}"
    
    # Draw buttons
    for i in "${!buttons[@]}"; do
        tput cup 5 $((10 + i * 12))
        if [ $i -eq $selected ]; then
            tput smso  # Start standout mode (highlight)
            echo -n "${buttons[i]}"
            tput rmso  # End standout mode
        else
            echo -n "${buttons[i]}"
        fi
    done
}

function main(){
    tput clear
    tput cup 2 10
    echo "Welcome to BashJack!"
    tput cup 4 10
    echo "Press any key to start..."
    read -rsn1
    while true; do
        
        # done
        
        # Game logic
        genDeck
        shuffleDeck
        
        dealCardPlayer
        dealCardPlayer
        dealCardDealer # Deal only 1 card to dealer so only 1 list is needed
        # dealCardDealer
        
        playerHandValue
        local playerValue=$?
        
        dealerHandValue
        local dealerValue=$?
        
        echo "Player Hand Value: $playerValue"
        echo "Dealer Hand Value: $dealerValue"
        
        # while true; do
            # echo "Player Hand: ${playerHand[@]}"
            # echo "Dealer Hand: ${dealerHand[@]}"
            # echo "Player Hand Value: $playerValue"
            # echo "Dealer Hand Value: $dealerValue"
            
            # if [ $playerValue -gt 21 ]; then
            #     echo "Player bust! Dealer wins!"
            #     break
            #     elif [ $dealerValue -gt 21 ]; then
            #     echo "Dealer bust! Player wins!"
            #     break
            # fi
            # Prompt the player to place a bet
            clear
            tput cup 2 10
            echo "Place your bet (minimum 1):"
            tput cup 3 10
            read -p "Bet: " bet

            # Validate the bet input
            while ! [[ "$bet" =~ ^[0-9]+$ ]] || [ "$bet" -lt 1 ]; do
                clear
                tput cup 2 10
                echo "Invalid bet. Please enter a number bigger than 0."
                tput cup 3 10
                read -p "Bet: " bet
            done

            # Display the bet amount
            # clear
            # tput cup 2 10
            # echo "You placed a bet of $bet."
            # tput cup 3 10
            # echo "Press any key to continue..."
            # read -rsn1
            
            while true; do
                draw_ui
                
                # Read user input
                read -rsn1 key
                case $key in
                    $'\x1b') # Handle arrow keys
                        read -rsn2 -t 0.1 key
                        case $key in
                            '[C') # Right arrow
                                if [ $selected -lt 1 ]; then
                                    selected=$((selected + 1))
                                fi
                            ;;
                            '[D') # Left arrow
                                if [ $selected -gt 0 ]; then
                                    selected=$((selected - 1))
                                fi
                            ;;
                        esac
                    ;;
                    '') # Enter key
                        if [ $selected -eq 0 ]; then
                            clear
                            dealCardPlayer
                            playerHandValue
                            playerValue=$?
                            break
                            elif [ $selected -eq 1 ]; then
                            clear
                            while [ $dealerValue -lt 17 ]; do
                                dealCardDealer
                                dealerHandValue
                                dealerValue=$?
                            done
                            break
                        fi
                    ;;
                esac
            done
            # read -p "Do you want to hit (h) or stand (s)? " choice
            # if [[ "$choice" == "h" ]]; then
            #     dealCardPlayer
            #     playerHandValue
            if [ $dealerValue -gt 21 ]; then
                clear
                tput cup 2 10
                echo "Dealer bust! Player wins!"
                tput cup 3 10
                echo "Player Hand: ${playerHand[@]}"
                tput cup 4 10
                echo "Dealer Hand: ${dealerHand[@]}"
            elif [ $playerValue -gt 21 ]; then
                clear
                tput cup 2 10
                echo "Player bust! Dealer wins!"
                tput cup 3 10
                echo "Player Hand: ${playerHand[@]}"
                tput cup 4 10
                echo "Dealer Hand: ${dealerHand[@]}"
            elif [ $playerValue -eq 21 ]; then
                clear
                tput cup 2 10
                echo "Blackjack! Player wins!"
                tput cup 3 10
                echo "Player Hand: ${playerHand[@]}"
                tput cup 4 10
                echo "Dealer Hand: ${dealerHand[@]}"
            elif [ $dealerValue -eq 21 ]; then
                clear
                tput cup 2 10
                echo "Blackjack! Dealer wins!"
                tput cup 3 10
                echo "Player Hand: ${playerHand[@]}"
                tput cup 4 10
                echo "Dealer Hand: ${dealerHand[@]}"
            elif [ $playerValue -gt $dealerValue ]; then
                clear
                tput cup 2 10
                echo "Player wins!"
                tput cup 3 10
                echo "Player Hand: ${playerHand[@]}"
                tput cup 4 10
                echo "Dealer Hand: ${dealerHand[@]}"
            elif [ $playerValue -lt $dealerValue ]; then
                clear
                tput cup 2 10
                echo "Dealer wins!"
                tput cup 3 10
                echo "Player Hand: ${playerHand[@]}"
                tput cup 4 10
                echo "Dealer Hand: ${dealerHand[@]}"
            else
                clear
                tput cup 2 10
                echo "It's a tie!"
            fi
            while true; do
                tput cup 6 10
                echo "Want to continue (Y/n)"
                read -rsn1 choice
                if [[ -z "$choice" || "$choice" == "y" || "$choice" == "Y" ]]; then
                    playerHand=()
                    dealerHand=()
                    playerValue=0
                    dealerValue=0
                    genDeck
                    shuffleDeck
                    break
                elif [[ "$choice" == "n" || "$choice" == "N" ]]; then
                    exit 0
                else
                    echo "Invalid choice. Please enter 'Y' or 'N' to continue."
                fi
            done
            
            # else
            #     echo "Invalid choice. Please enter 'h' or 's'."
            # fi
            
        # done
        # echo "Game over!"
        # echo "Player Hand: ${playerHand[@]}"
        # echo "Dealer Hand: ${dealerHand[@]}"
        # echo "Player Hand Value: $playerValue"
        # echo "Dealer Hand Value: $dealerValue"
        # echo "Remaining cards in deck: ${#deckGlobal[@]}"
        # echo "Remaining cards in deck: ${deckGlobal[@]}"
        
    done
    
}

main
