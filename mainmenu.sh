buttons=("BashJack" "BashLots" "RuleBash" "Exit")
selected=0
draw_ui() {
    clear
    tput cup 1 10
    echo "BashJack: $BashJack"
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

transmit_sixel() {
    if command -v img2sixel >/dev/null 2>&1; then
        img2sixel "$1"
    else
        echo "Error: img2sixel is not installed. Please install it to use this feature."
        exit 1
    fi
}

while true; do
    draw_ui

    read -rsn1 key
    case $key in
        $'\x1b')
            read -rsn2 -t 0.1 key
            case $key in
                '[C') [ $selected -lt 3 ] && selected=$((selected + 1)) ;;
                '[D') [ $selected -gt 0 ] && selected=$((selected - 1)) ;;
            esac
            ;;
        '')
            if [ $selected -eq 0 ]; then
                # Start BashJack game
                clear
                bash ./BashJack/main.sh
            elif [ $selected -eq 1 ]; then
                # Start BashLots game.
                clear
                bash ./BashLots/main.sh
            elif [ $selected -eq 2 ]; then
                # Show rules
                clear
                bash ./RuleBash/main.sh
            elif [ $selected -eq 3 ]; then
                # Exit the script
                clear
                if [ -f "keepgambing.png" ]; then
                    transmit_sixel "keepgambing.png"
                fi
                exit 0
            fi
            ;;
    esac
done
done