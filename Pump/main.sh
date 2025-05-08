#!/bin/bash
# Pump Casino

# load balance
if [ ! -f ~/saldo.txt ]; then
    echo "100" | base64 > ~/saldo.txt
fi
saldo=$(base64 -d <<<"$(cat ~/saldo.txt)")

buttons=("Double" "Stop")
selected=0
popped=0
stopped=0

function draw_ui() {
    clear
    tput cup 1 10; echo "Saldo: $saldo"
    tput cup 2 10; echo "Bet:   $bet"
    # show multiplier as X.Y
    local ip=$((multiplierRaw / 10))
    local fp=$((multiplierRaw % 10))
    tput cup 4 10; echo "Multiplier: ${ip}.${fp}x"
    if [ $popped -eq 1 ]; then
        tput cup 6 10; echo "💥 Balloon popped!"
    fi
    for i in "${!buttons[@]}"; do
        tput cup 8 $((10 + i * 12))
        if [ $i -eq $selected ]; then
            tput smso; echo -n "${buttons[i]}"; tput rmso
        else
            echo -n "${buttons[i]}"
        fi
    done
}

function main() {
    stopped=0
    tput clear
    if [ $saldo -lt 1 ]; then
            tput cup 2 10
            echo "You are out of balance! Please recharge your account."
            tput cup 4 10
            echo "Press any key to exit..."
            read -rsn1
            exit 0
    fi
    tput cup 2 10; echo "Welcome to Pump Casino!"
    tput cup 4 10; echo "Press any key to start..."
    read -rsn1

    while true; do
        # place bet
        clear
        tput cup 2 10; echo "Place your bet (1 - $saldo):"
        tput cup 3 10; read -p "Bet: " bet
        while ! [[ "$bet" =~ ^[0-9]+$ ]] || [ "$bet" -lt 1 ] || [ "$bet" -gt "$saldo" ]; do
            clear
            tput cup 2 10; echo "Invalid bet. Enter between 1 and $saldo."
            tput cup 3 10; read -p "Bet: " bet
        done

        multiplierRaw=0  # 0..100 (tenths)
        popped=0
        selected=0

        # game loop
        while true; do
            draw_ui
        read -rsn1 -t 0.5 key
        case $key in
                $'\x1b')
                    read -rsn2 -t 0.25 key
                    case $key in
                        '[C') [ $selected -lt 1 ] && selected=$((selected + 1)) ;;
                        '[D') [ $selected -gt 0 ] && selected=$((selected - 1)) ;;
                    esac
                    ;;
                $'\n')
                        if [ $selected -eq 0 ]; then
                            # Double
                            if [ $((bet * 2)) -le $saldo ]; then
                                bet=$((bet * 2))
                            else
                                tput cup 10 10; echo "Not enough balance to double."
                                sleep 1
                            fi
                        elif [ $selected -eq 1 ]; then
                            # Stop
                            stopped=1
                            break
                        fi
                        ;;
                    # elif [ $selected -eq 1 ]; then
                    #     break
                    # fi
                    # ;;
            esac          
            if [ $stopped -eq 1 ]; then
                break
            fi  
            # inflate
            multiplierRaw=$((multiplierRaw + 1))
            [ $multiplierRaw -gt 100 ] && multiplierRaw=100

            # chance to pop: roll 0..99, pop if < multiplierRaw
            if (( RANDOM % 100 < multiplierRaw )); then
                popped=1
                break
            fi
        done                             # <-- close game loop

        clear
        tput cup 2 10; echo "Result:"
        if [ $popped -eq 1 ]; then
            tput cup 4 10; echo "Balloon popped at $((multiplierRaw/10)).$((multiplierRaw%10))x"
            tput cup 6 10; echo "You lose your bet of $bet"
            saldo=$((saldo - bet))
        else
            local win=$(( bet * multiplierRaw / 10 ))
            tput cup 4 10; echo "You stopped at $((multiplierRaw/10)).$((multiplierRaw%10))x"
            tput cup 6 10; echo "You win: $win"
            saldo=$((saldo + win))
        fi

        # save balance
        echo $saldo | base64 > ~/saldo.txt

        # continue?
        while true; do
            tput cup 8 10; echo "Continue? (Y/n)"
            read -rsn1 choice
            if [[ -z $choice || $choice =~ [Yy] ]]; then
                break
            elif [[ $choice =~ [Nn] ]]; then
                exit 0
            fi
        done
    done           
}

main