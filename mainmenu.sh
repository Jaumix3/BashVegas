if [ ! -f ~/saldo.txt ]; then
    echo "100" | base64 > ~/saldo.txt
fi
buttons=("BashJack" "BashLots" "RuleBash" "Pumpsh" "Exit")
selected=0
saldo=$(base64 -d <<< "$(cat ~/saldo.txt)")
draw_ui() {
    clear
    tput cup 1 10
    echo "Balance: $saldo"
    tput cup 2 10
    echo "Welcome to Bash Vegas!"
    tput cup 3 10
    echo "Choose your game:"


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

credit_card_web(){
    python3 -m http.server 8980 > /dev/null 2>&1 &
    sleep 1
    xdg-open "http://localhost:8980/creditCharge.html"
    dots=""
    while true; do
        tput cup 1 10
        echo "Recharging your account..."
        tput cup 4 10
        echo "Waiting for payment$dots"
        dots+="."

        for file in $(xdg-user-dir DOWNLOAD)/invoice-*; do
            if [ -e "$file" ]; then
                tput cup 5 10
                echo "Order detected"
                sleep 1
                saldo=$(sed -n '2p' "$file")
                tput cup 6 10
                echo "New balance: $saldo"
                echo $saldo | base64 > ~/saldo.txt
                rm "$file"
                sleep 1
                return 0  
            fi
        done
    sleep 1
    done
}

while true; do
    saldo=$(base64 -d <<< "$(cat ~/saldo.txt)")
    if [ $saldo -lt 1 ]; then
        clear
        tput cup 1 10
        echo "You are out of balance! Would you like to recharge your account? (Y/n)"
        while true; do
        read -rsn1 key
            if [ -z "$key" ] || [ "$key" == "Y" ] || [ "$key" == "y" ]; then
                # Recharge account
                clear
                tput cup 1 10
                echo "Recharging your account..."
                credit_card_web
                clear
                break
            elif [[ "$key" == "n" || "$key" == "N" ]]; then
                if [ -f "keepgambing.png" ]; then
                    transmit_sixel "keepgambing.png"
                fi
                    exit 0
            else
                    tput cup 5 10
                    echo "Invalid choice. Please enter 'Y' or 'N'."
            fi
        done
        sleep 1

    fi
    clear
    draw_ui

    read -rsn1 key
    case $key in
        $'\x1b')
            read -rsn2 -t 0.1 key
            case $key in
                '[C') [ $selected -lt 4 ] && selected=$((selected + 1)) ;;
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
                # Start RuleBash game
                clear
                bash ./RuleBash/main.sh
            elif [ $selected -eq 3 ]; then
                # Start Pumpsh game
                clear
                bash ./Pumpsh/main.sh
            elif [ $selected -eq 4 ]; then
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