#!/bin/bash

saldo=$(base64 -d <<< cat ~/saldo.txt)

# Definir símbolos con distribución ajustada (menos probabilidad de ganar)
symbols=("1" "1" "A" "A" "B" "B" "C" "C" "D" "D" "E" "E" "F" "F")

# Línies de premi: llistes d’índexs del tauler (0 a 14)
linies=(
  "5 6 7 8 9" "0 1 2 3 4" "10 11 12 13 14"
  "0 6 12 8 4" "10 6 2 8 14" "0 6 7 8 14"
  "10 6 7 8 4" "5 1 2 3 9" "5 11 12 13 9"
  "5 1 7 3 9" "5 11 7 13 9" "0 1 7 3 4"
  "10 11 7 13 14" "0 6 2 8 4" "10 6 12 8 14"
  "0 6 12 8 4" "10 6 2 8 14" "5 1 7 13 9"
  "5 11 7 3 9" "0 6 7 8 4"
)

while true; do
    echo "Tienes $saldo."
    read -p "¿Cuánto quieres apostar? " apuesta

    # Handle "all in" case first
    if [[ "${apuesta,,}" == "all in" ]]; then
        apuesta=$saldo
        echo "¡Vas con todo! Apostando $apuesta 💥"
    fi

    if (( apuesta > saldo )); then
        echo "No tienes suficiente saldo."
        continue
    fi

    # Generar tauler 3x5 (array de 15 elements)
    tablero=()
    for i in {0..14}; do
        tablero[$i]=${symbols[$RANDOM % ${#symbols[@]}]}
    done

    # Mostrar el tauler
    echo "-------------------------"
    for fila in 0 1 2; do
        for col in 0 1 2 3 4; do
            idx=$((fila * 5 + col))
            echo -n "| ${tablero[$idx]} "
        done
        echo "|"
    done
    echo "-------------------------"

    # Comprovació de línies guanyadores
    ganar=0

    for i in "${!linies[@]}"; do
        read -a pos <<< "${linies[$i]}"
        s1="${tablero[${pos[0]}]}"
        s2="${tablero[${pos[1]}]}"
        s3="${tablero[${pos[2]}]}"
        s4="${tablero[${pos[3]}]}"
        s5="${tablero[${pos[4]}]}"

        if [[ "$s1" == "$s2" && "$s2" == "$s3" ]]; then
            premio=$((apuesta / 2))
            if [[ "$s3" == "$s4" ]]; then
                premio=$((apuesta * 1))
                if [[ "$s4" == "$s5" ]]; then
                    premio=$((apuesta * 2))
                fi
            fi
            ganar=$((ganar + premio))
            echo "🎉 Línea $((i+1)) ganadora con '$s1' → +$premio"
        fi
    done

    if (( ganar > 0 )); then
        echo "¡Ganaste $ganar en total!"
        saldo=$((saldo + ganar))
    else
        echo "¡No ganaste esta vez!"
        saldo=$((saldo - apuesta)) 
    fi

    read -p "¿Quieres jugar de nuevo? (S/n): " choice
    if [[ "$choice" != "s" && "$choice" != "S" ]]; then
        if [ -f "keepgambing.png" ]; then
        transmit_png "keepgambing.png"
        fi
        break
    fi
done

