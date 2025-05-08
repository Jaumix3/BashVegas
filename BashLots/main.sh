#!/bin/bash

# Verificar si el archivo de saldo existe
if [ ! -f ~/saldo.txt ]; then
    echo "100" | base64 > ~/saldo.txt
fi

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

transmit_png() {
    data=$(base64 -w 0 "$1")  # -w 0 removes line breaks
    data="${data//[[:space:]]}"
    builtin local pos=0
    builtin local chunk_size=4096
    while [ $pos -lt ${#data} ]; do
        builtin printf "\e_G"
        [ $pos = "0" ] && printf "a=T,f=100,"
        builtin local chunk="${data:$pos:$chunk_size}"
        pos=$(($pos+$chunk_size))
        [ $pos -lt ${#data} ] && builtin printf "m=1"
        [ ${#chunk} -gt 0 ] && builtin printf ";%s" "${chunk}"
        builtin printf "\e\\"
    done
}

while true; do


    if (( saldo <= 0 )); then
        echo "¡Te has quedado sin saldo! 😢"
        read -p "¿Te gustaría pedir un préstamo de 50? (s/n): " prestamo
        if [[ "$prestamo" == "s" ]]; then
            saldo=50
            prestamo_activo=true
            echo "Te hemos prestado 50. ¡Recuerda que debes devolverlo con un 10% de interés!"
        else
            echo "¡Gracias! ¡Vuelve cuando quieras!"
            break
        fi
    fi

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

    # Descomptar l’interès si hi havia préstec activo
    if [[ "$prestamo_activo" == true && $saldo -ge 55 ]]; then
        interes=$((50 * 10 / 100))
        saldo=$((saldo - interes))
        prestamo_activo=false
        echo "🔻 Se ha descontado un interés de $interes por el préstamo."
    fi

    echo $saldo | base64 > ~/saldo.txt

    read -p "¿Quieres jugar de nuevo? (s/n): " choice
    if [[ "$choice" != "s" ]]; then
        if [ -f "keepgambing.png" ]; then
            transmit_png "keepgambing.png"
        fi
        break
    fi
done