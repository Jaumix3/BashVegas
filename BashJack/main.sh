#!/bin/bash
# BashJack

if [ ! -f ~/saldo.txt ]; then
    echo "100" | base64 > ~/saldo.txt
fi

saldo=$(base64 -d <<< "$(cat ~/saldo.txt)")

declare -a deckGlobal=()
declare -a playerHand=()
declare -a dealerHand=()
selected=0
buttons=("Hit" "Stand")

transmit_sixel() {
    if command -v img2sixel >/dev/null 2>&1; then
        img2sixel "$1"
    else
        echo "Error: img2sixel is not installed. Please install it to use this feature."
        exit 1
    fi
}

function genDeck() {
    local suits=("♤" "♡" "♢" "♧")
    local values=("A" "2" "3" "4" "5" "6" "7" "8" "9" "10" "J" "Q" "K")
    deckGlobal=()
    for suit in "${suits[@]}"; do
        for value in "${values[@]}"; do
            deckGlobal+=("$value$suit")
        done
    done
}

function shuffleDeck() {
    local shuffledDeck=()
    while [ ${#deckGlobal[@]} -gt 0 ]; do
        local randIndex=$((RANDOM % ${#deckGlobal[@]}))
        shuffledDeck+=("${deckGlobal[$randIndex]}")
        unset 'deckGlobal[$randIndex]'
        deckGlobal=("${deckGlobal[@]}")
    done
    deckGlobal=("${shuffledDeck[@]}")
}

function calculateHand() {
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

function dealCard() {
    card="${deckGlobal[0]}"
    deckGlobal=("${deckGlobal[@]:1}")
}

function dealCardPlayer() {
    dealCard
    playerHand+=("$card")
}

function dealCardDealer() {
    dealCard
    dealerHand+=("$card")
}

function playerHandValue() {
    calculateHand "${playerHand[@]}"
    return $?
}

function dealerHandValue() {
    calculateHand "${dealerHand[@]}"
    return $?
}

function draw_ui() {
    clear
    tput cup 1 10
    echo "Saldo: $saldo"
    tput cup 2 10
    echo "Bet: $bet"
    tput cup 4 10
    echo "Player Hand: ${playerHand[@]}"
    # playerHandValue
    # local playerValue=$?
    tput cup 5 10
    # echo "Player Hand Value: $playerValue"
    # tput cup 7 10
    echo "Dealer Hand: ${dealerHand[@]}"
    # dealerHandValue
    # local dealerValue=$?
    # tput cup 8 10
    # echo "Dealer Hand Value: $dealerValue"

    for i in "${!buttons[@]}"; do
        tput cup 7 $((10 + i * 12))
        if [ $i -eq $selected ]; then
            tput smso
            echo -n "${buttons[i]}"
            tput rmso
        else
            echo -n "${buttons[i]}"
        fi
    done
}

function main() {
    tput clear
    tput cup 2 10
    echo "Welcome to BashJack!"
    tput cup 4 10
    echo "Press any key to start..."
    read -rsn1

    while true; do
        genDeck
        shuffleDeck
        playerHand=()
        dealerHand=()

        dealCardPlayer
        dealCardPlayer
        dealCardDealer

        clear
        tput cup 2 10
        echo "Place your bet (minimum 1, max $saldo):"
        tput cup 3 10
        read -p "Bet: " bet

        while ! [[ "$bet" =~ ^[0-9]+$ ]] || [ "$bet" -lt 1 ] || [ $saldo -lt $bet ]; do
            clear
            tput cup 2 10
            echo "Invalid bet. Please enter a number between 1 and $saldo."
            tput cup 3 10
            read -p "Bet: " bet
        done

        while true; do
            draw_ui
            playerHandValue
            local playerValue=$?
            dealerHandValue
            local dealerValue=$?

            if [ $playerValue -eq 21 ] || [ $dealerValue -eq 21 ] || [ $playerValue -gt 21 ] || [ $dealerValue -gt 21 ]; then
                break
            fi

            read -rsn1 key
            case $key in
                $'\x1b')
                    read -rsn2 -t 0.1 key
                    case $key in
                        '[C') [ $selected -lt 1 ] && selected=$((selected + 1)) ;;
                        '[D') [ $selected -gt 0 ] && selected=$((selected - 1)) ;;
                    esac
                    ;;
                '')
                    if [ $selected -eq 0 ]; then
                        dealCardPlayer
                    elif [ $selected -eq 1 ]; then
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
        clear
        tput cup 2 10
        echo "Final Hands:"
        tput cup 4 10
        echo "Player Hand: ${playerHand[@]}"
        # playerHandValue
        # playerValue=$?
        # tput cup 5 10
        # echo "Player Hand Value: $playerValue"
        tput cup 5 10
        echo "Dealer Hand: ${dealerHand[@]}"
        # dealerHandValue
        # dealerValue=$?
        # tput cup 8 10
        # echo "Dealer Hand Value: $dealerValue"
        # tput cup 10 10

        if [ $playerValue -gt 21 ]; then
            tput cup 7 10
            echo "Player bust! Dealer wins!"
            saldo=$((saldo - bet))
        elif [ $dealerValue -gt 21 ]; then
            tput cup 7 10
            echo "Dealer bust! Player wins!"
            saldo=$((saldo + bet))
        elif [ $playerValue -eq 21 ]; then
            tput cup 7 10
            echo "Blackjack! Player wins!"
            saldo=$((saldo + bet * 2))
        elif [ $dealerValue -eq 21 ]; then
            tput cup 7 10
            echo "Blackjack! Dealer wins!"
            saldo=$((saldo - bet))
        elif [ $playerValue -gt $dealerValue ]; then
            tput cup 7 10
            echo "Player wins!"
            saldo=$((saldo + bet))
        elif [ $playerValue -lt $dealerValue ]; then
            tput cup 7 10
            echo "Dealer wins!"
            saldo=$((saldo - bet))
        else
            tput cup 7 10
            echo "It's a tie!"
        fi

        echo $saldo | base64 > ~/saldo.txt

        while true; do
            tput cup 8 10
            echo "Want to continue (Y/n)?"
            read -rsn1 choice
            if [[ -z "$choice" || "$choice" == "y" || "$choice" == "Y" ]]; then
                break
            elif [[ "$choice" == "n" || "$choice" == "N" ]]; then
                if [ -f "keepgambing.png" ]; then
                    transmit_sixel "keepgambing.png"
                fi
                exit 0
            else
                tput cup 15 10
                echo "Invalid choice. Please enter 'Y' or 'N'."
            fi
        done
    done
}

main