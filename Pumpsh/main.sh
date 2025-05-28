#!/bin/bash
# Pumpsh Casino

# load balance
if [ ! -f ~/saldo.txt ]; then
    echo "100" | base64 > ~/saldo.txt
fi
saldo=$(base64 -d <<<"$(cat ~/saldo.txt)")

buttons=("Double" "Next" "Stop")
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
    tput cup 2 10; echo "Welcome to Pumpsh!"
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

        # debit stake immediately
        saldo=$((saldo - bet))

        multiplierRaw=0  # 0..100 (tenths)
        popped=0
        selected=0

        # game loop
        while true; do
            draw_ui

            # read one key with timeout
            # tput cup 0 0; echo $key
            # handle arrow keys
            # if [[ $key == $'\x1b'  ]]; then
            #     read -rsn2 -t 0.1 rest
            #     key+=$rest
            # fi

            
            read -rsn1 key
        
            if [ $stopped -eq 1 ]; then
                break
            fi
            
            case $key in
                $'\x1b')
                    read -rsn2 -t 0.1 key
                    case $key in
                        '[C') [ $selected -lt 2 ] && selected=$((selected + 1)) ;;
                        '[D') [ $selected -gt 0 ] && selected=$((selected - 1)) ;;
                    esac
                    ;;
                '')       # Enter key
                
                    if [ $selected -eq 2 ]; then
                        # Stop
                        stopped=1
                        multiplierRaw=$((multiplierRaw + 1))
                        [ $multiplierRaw -gt 100 ] && multiplierRaw=100
                        if (( RANDOM % 100 < multiplierRaw )); then
                            popped=1
                            continue
                        fi
                        break
                        # continue
                    fi
                    if [ $selected -eq 1 ]; then
                        # Next
                        # inflate and check pop
                        multiplierRaw=$((multiplierRaw + 1))
                        [ $multiplierRaw -gt 100 ] && multiplierRaw=100
                        if (( RANDOM % 100 < multiplierRaw )); then
                            popped=1
                            continue
                        fi
                    fi
                    if [ $selected -eq 0 ]; then
                        # Double
                        if [ $((bet * 2)) -le $saldo ]; then
                            bet=$((bet * 2))
                            multiplierRaw=$((multiplierRaw + 1))
                            [ $multiplierRaw -gt 100 ] && multiplierRaw=100
                            if (( RANDOM % 100 < multiplierRaw )); then
                                popped=1
                                continue
                            fi
                        else
                            tput cup 10 10; echo "Not enough balance to double."
                            sleep 1
                        fi
                        
                        continue
                    fi
                    ;;
            esac
            # multiplierRaw=$((multiplierRaw + 1))
            # [ $multiplierRaw -gt 100 ] && multiplierRaw=100
            # if (( RANDOM % 100 < multiplierRaw )); then
            #     popped=1
            #     break
            # fi
            if [ $popped -eq 1 ]; then
                # balloon popped
                break
            fi
        done  # game loop                        # <-- close game loop

        clear
        tput cup 2 10; echo "Result:"
        if [ $popped -eq 1 ]; then
            tput cup 4 10; echo "Balloon popped at $((multiplierRaw/10)).$((multiplierRaw%10))x"
            tput cup 6 10; echo "You lose your bet of $bet"
            # stake already debited above, so no further change
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
            clear
            tput cup 2 10; echo "Result:"
            if [ $popped -eq 1 ]; then
                tput cup 4 10; echo "Balloon popped at $((multiplierRaw/10)).$((multiplierRaw%10))x"
                tput cup 6 10; echo "You lose your bet of $bet"
                # stake already debited above, so no further change
            else
                local win=$(( bet * multiplierRaw / 10 ))
                tput cup 4 10; echo "You stopped at $((multiplierRaw/10)).$((multiplierRaw%10))x"
                tput cup 6 10; echo "You win: $win"
            fi
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