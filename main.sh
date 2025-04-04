#!/bin/bash

# Verificar si el archivo de saldo existe
if [ ! -f "saldo.txt" ]; then
    echo "100" > saldo.txt  # Si no existe, asignamos un saldo inicial de 100
fi

# Leer el saldo desde el archivo
saldo=$(cat saldo.txt)

# Definir los símbolos de la máquina tragaperras con probabilidad reducida de ganar
symbols=("1" "1" "1" "C" "C" "C" "B" "B")  # Menos "A" y "B", más "1" y "C"

while true; do
    # Verificar si el jugador tiene saldo
    if (( saldo <= 0 )); then
        echo "¡Te has quedado sin saldo! 😢"
        
        # Opción para pedir un préstamo
        read -p "¿Te gustaría pedir un préstamo de 50? (s/n): " prestamo
        if [[ "$prestamo" == "s" ]]; then
            # Prestar 50 con un interés del 10%
            saldo=50
            echo "Te hemos prestado 50. ¡Recuerda que debes devolverlo con un 10% de interés!"
        else
            break  # Si no quiere pedir un préstamo, terminamos el juego
        fi
    fi

    # Mostrar el saldo
    echo "Tienes $saldo."

    # Pedir la apuesta
    read -p "¿Cuánto quieres apostar? " apuesta

    # Verificar que la apuesta no sea mayor que el saldo
    if (( apuesta > saldo )); then
        echo "No tienes suficiente saldo para esa apuesta."
        continue  # Si no tiene suficiente saldo, continuamos al siguiente giro
    fi

    # Generar cuatro símbolos aleatorios por línea (superior, central, inferior, nueva columna)
    slot1_1=${symbols[$RANDOM % ${#symbols[@]}]}
    slot1_2=${symbols[$RANDOM % ${#symbols[@]}]}
    slot1_3=${symbols[$RANDOM % ${#symbols[@]}]}
    slot1_4=${symbols[$RANDOM % ${#symbols[@]}]}  # Nueva columna

    slot2_1=${symbols[$RANDOM % ${#symbols[@]}]}
    slot2_2=${symbols[$RANDOM % ${#symbols[@]}]}
    slot2_3=${symbols[$RANDOM % ${#symbols[@]}]}
    slot2_4=${symbols[$RANDOM % ${#symbols[@]}]}  # Nueva columna

    slot3_1=${symbols[$RANDOM % ${#symbols[@]}]}
    slot3_2=${symbols[$RANDOM % ${#symbols[@]}]}
    slot3_3=${symbols[$RANDOM % ${#symbols[@]}]}
    slot3_4=${symbols[$RANDOM % ${#symbols[@]}]}  # Nueva columna

    # Mostrar el resultado
    echo "----------------------"
    echo "| $slot1_1 $slot1_2 $slot1_3 $slot1_4 |"
    echo "| $slot2_1 $slot2_2 $slot2_3 $slot2_4 |"
    echo "| $slot3_1 $slot3_2 $slot3_3 $slot3_4 |"
    echo "----------------------"

    # Comprobar combinaciones en cada línea
    ganar=0  # Variable para acumular el premio total

    # Línea 1 (superior)
    if [[ "$slot1_1" == "$slot1_2" && "$slot1_2" == "$slot1_3" && "$slot1_3" == "$slot1_4" ]]; then
        echo "¡Ganaste 100% en la línea superior! 🎉"
        ganar=$((ganar + apuesta))  # Premio 100% de la apuesta
    elif [[ "$slot1_1" == "$slot1_2" || "$slot1_2" == "$slot1_3" || "$slot1_3" == "$slot1_4" ]]; then
        echo "¡Ganaste 50% en la línea superior! 🤑"
        ganar=$((ganar + apuesta / 2))  # Premio 50% de la apuesta
    fi

    # Línea 2 (central)
    if [[ "$slot2_1" == "$slot2_2" && "$slot2_2" == "$slot2_3" && "$slot2_3" == "$slot2_4" ]]; then
        echo "¡Ganaste 100% en la línea central! 🎉"
        ganar=$((ganar + apuesta))  # Premio 100% de la apuesta
    elif [[ "$slot2_1" == "$slot2_2" || "$slot2_2" == "$slot2_3" || "$slot2_3" == "$slot2_4" ]]; then
        echo "¡Ganaste 50% en la línea central! 🤑"
        ganar=$((ganar + apuesta / 2))  # Premio 50% de la apuesta
    fi

    # Línea 3 (inferior)
    if [[ "$slot3_1" == "$slot3_2" && "$slot3_2" == "$slot3_3" && "$slot3_3" == "$slot3_4" ]]; then
        echo "¡Ganaste 100% en la línea inferior! 🎉"
        ganar=$((ganar + apuesta))  # Premio 100% de la apuesta
    elif [[ "$slot3_1" == "$slot3_2" || "$slot3_2" == "$slot3_3" || "$slot3_3" == "$slot3_4" ]]; then
        echo "¡Ganaste 50% en la línea inferior! 🤑"
        ganar=$((ganar + apuesta / 2))  # Premio 50% de la apuesta
    fi

    # Verificar si el jugador ganó en alguna línea
    if (( ganar > 0 )); then
        echo "¡Ganaste $ganar en total!"
        saldo=$((saldo + ganar))  # Sumar al saldo
    else
        echo "¡No ganaste esta vez!"
        saldo=$((saldo - apuesta))  # Restar la apuesta del saldo
    fi

    # Si el jugador pidió un préstamo, agregar un interés del 10% sobre el préstamo
    if (( saldo > 50 )); then
        interes=$((50 * 10 / 100))
        saldo=$((saldo - interes))
        echo "Se ha descontado un interés del 10% sobre el préstamo. Deberás devolver $interes."
    fi

    # Guardar el nuevo saldo en el archivo
    echo $saldo > saldo.txt

    # Preguntar si el jugador quiere seguir jugando
    read -p "¿Quieres jugar de nuevo? (s/n): " choice
    if [[ "$choice" != "s" ]]; then
        break
    fi
done
