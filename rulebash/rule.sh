#!/bin/bash

guardar_saldo() {
    echo "$1" > saldo.txt
}

cargar_saldo() {
    if [[ ! -f saldo.txt ]]; then
        echo "No se encontró saldo guardado."
        read -p "Introduce el saldo inicial: " saldo_inicial
        echo "$saldo_inicial" > saldo.txt
    fi
    cat saldo.txt
}

Apuesta() {
    local saldo=$1
    local apuesta
    local canta
    local numganador
    local apuestas=()
    local cantidades=()
    local apuesta_rojo=0
    local apuesta_negro=0

    for i in {1..5}; do
        read -p "¿Quieres hacer la apuesta $i? [Y/N] " h
        if [[ "$h" == "Y" || "$h" == "y" || "$h" == "" || "$h" == "yes" || "$h" == "Yes" ]]; then
            read -p "Haz tu apuesta $i (Rojo, Negro o un número del 0 al 36): " apuesta

            while [[ ("$apuesta" == "Rojo" && $apuesta_rojo -eq 1) || ("$apuesta" == "Negro" && $apuesta_negro -eq 1) ]]; do
                echo "No puedes apostar a ambos colores. Intenta de nuevo."
                read -p "Haz tu apuesta $i (Rojo, Negro o un número del 0 al 36): " apuesta
            done

            if [[ "$apuesta" == "Rojo" && $apuesta_rojo -eq 0 && $apuesta_negro -eq 0 ]]; then
                apuestas+=("$apuesta")
                apuesta_rojo=1
            elif [[ "$apuesta" == "Negro" && $apuesta_negro -eq 0 && $apuesta_rojo -eq 0 ]]; then
                apuestas+=("$apuesta")
                apuesta_negro=1
            elif [[ "$apuesta" =~ ^[0-9]+$ && "$apuesta" -ge 0 && "$apuesta" -le 36 ]]; then
                apuestas+=("$apuesta")
            else
                i=$((i-1))
                continue
            fi

            read -p "Introduce la cantidad a apostar para esta opción: " canta
            while [[ $canta -gt $saldo ]]; do
                read -p "Cantidad inválida. Introduce una menor o igual a $saldo: " canta
            done
            cantidades+=("$canta")
            saldo=$((saldo - canta))
            guardar_saldo "$saldo"
        else
            break
        fi
    done

    numganador=$((RANDOM % 37))
    >&2 echo "La bola ha caído en $numganador."

    for i in "${!apuestas[@]}"; do
        local apuesta="${apuestas[$i]}"
        local cantidad="${cantidades[$i]}"

        if [[ "$apuesta" == "$numganador" && $numganador -ne 0 ]]; then
            >&2 echo "Has ganado una cantidad de: $((cantidad * 4)) por apostar al número $apuesta."
            saldo=$((saldo + cantidad * 5))
        elif [[ "$apuesta" == "Rojo" && $((numganador % 2)) -ne 0 && $numganador -ne 0 ]]; then
            >&2 echo "Has ganado una cantidad de: $((cantidad * 3 / 2)) por apostar a Rojo."
            saldo=$((saldo + cantidad * 3 / 2))
        elif [[ "$apuesta" == "Negro" && $((numganador % 2)) -eq 0 && $numganador -ne 0 ]]; then
            >&2 echo "Has ganado una cantidad de: $((cantidad * 3 / 2)) por apostar a Negro."
            saldo=$((saldo + cantidad * 3 / 2))
        elif [[ "$apuesta" == "0" && $numganador -eq 0 ]]; then
            >&2 echo "Has ganado una cantidad de: $((cantidad * 10)) por apostar al número 0."
            saldo=$((saldo + cantidad * 11))
        fi
    done

    guardar_saldo "$saldo"

    echo "$saldo"
}

main() {
    local saldo
    local h

    saldo=$(cargar_saldo)
    echo "Dispones de un saldo de: $saldo."

    while true; do
        read -p "¿Deseas hacer tus apuestas ahora? [Y/N] " h
        if [[ "$h" == "Y" || "$h" == "y" || "$h" == "" || "$h" == "yes" || "$h" == "Yes" ]]; then
            saldo=$(Apuesta "$saldo")
        elif [[ "$h" == "N" || "$h" == "n" || "$h" == "No" || "$h" == "no" || "$h" == "NO" ]]; then
            echo "Apuesta no realizada."
        else
            echo "Opción no válida. [Y/N]"
            continue
        fi

        echo "Saldo final después de todas las apuestas: $saldo"
        read -p "¿Quieres seguir jugando? [Y/N] " h
        if [[ "$h" == "Y" || "$h" == "y" || "$h" == "" || "$h" == "yes" || "$h" == "Yes" ]]; then
            continue
        elif [[ "$h" == "N" || "$h" == "n" || "$h" == "No" || "$h" == "no" || "$h" == "NO" ]]; then
            xdg-open "minero.png"
            read -p "¿Seguro? [Y/N] " h
            if [[ "$h" == "Y" || "$h" == "y" || "$h" == "" || "$h" == "yes" || "$h" == "Yes" ]]; then
                break
            fi
        else
            echo "Opción no válida. [Y/N]"
        fi
    done

    echo "Gracias por jugar y regalarnos tu dinero <3"
}

main
