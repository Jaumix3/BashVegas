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
