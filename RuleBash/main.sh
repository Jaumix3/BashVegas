#!/bin/bash

guardar_saldo() {
    local saldo=$1
    echo -n "$saldo" | base64 > ~/saldo.txt
}

cargar_saldo() {
    if [[ ! -f ~/saldo.txt ]]; then
        echo "100" | base64 > ~/saldo.txt
    fi
    local saldo_base64=$(cat ~/saldo.txt)
    echo $(echo "$saldo_base64" | base64 --decode)
}

mostrar_ruleta() {
    local numero=$1
    local line1="---------------------"
    local line2="|                   |"
    
    echo "$line1"
    
    if [[ $numero -eq 0 ]]; then
        echo "|             0             |"
    else
        echo "$line2"
    fi
    
    local ruleta=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "32" "33" "34" "35" "36" "0")
    
    for i in ${!ruleta[@]}; do
        if [[ ${ruleta[$i]} -eq $numero ]]; then
            ruleta[$i]="X "  
        fi
    done
    
    echo "|          ${ruleta[-1]}        |"
    echo "| ${ruleta[0]}  | ${ruleta[1]}  | ${ruleta[2]}  | ${ruleta[3]}  |"
    echo "| ${ruleta[4]}  | ${ruleta[5]}  | ${ruleta[6]}  | ${ruleta[7]}  |"
    echo "| ${ruleta[8]} | ${ruleta[9]}  | ${ruleta[10]} | ${ruleta[11]} |"
    echo "| ${ruleta[12]} | ${ruleta[13]} | ${ruleta[14]} | ${ruleta[15]} |"
    echo "| ${ruleta[16]} | ${ruleta[17]} | ${ruleta[18]} | ${ruleta[19]} |"
    echo "| ${ruleta[20]} | ${ruleta[21]} | ${ruleta[22]} | ${ruleta[23]} |"
    echo "| ${ruleta[24]} | ${ruleta[25]} | ${ruleta[26]} | ${ruleta[27]} |"
    echo "| ${ruleta[28]} | ${ruleta[29]} | ${ruleta[30]} | ${ruleta[31]} |"
    echo "| ${ruleta[32]} | ${ruleta[33]} | ${ruleta[34]} | ${ruleta[35]} |"
    
    echo "$line2"
    echo "$line1"
    
    echo "Bola en $numero"
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
        echo ""
        read -p "¿Quieres hacer la apuesta $i? [Y/N] " h
        if [[ "$h" == "Y" || "$h" == "y" || "$h" == "" || "$h" == "yes" || "$h" == "Yes" ]]; then
            echo "----------------------"
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
    mostrar_ruleta "$numganador" # Mostrar la ruleta con el número donde cayó la bola

    for i in "${!apuestas[@]}"; do
        local apuesta="${apuestas[$i]}"
        local cantidad="${cantidades[$i]}"

        if [[ "$apuesta" == "$numganador" && $numganador -ne 0 ]]; then
            echo "¡Has ganado una cantidad de: $((cantidad * 4)) por apostar al número $apuesta!"
            saldo=$((saldo + cantidad * 5))
        elif [[ "$apuesta" == "Rojo" && $((numganador % 2)) -ne 0 && $numganador -ne 0 ]]; then
            echo "¡Has ganado una cantidad de: $((cantidad * 3 / 2)) por apostar a Rojo!"
            saldo=$((saldo + cantidad * 3 / 2))
        elif [[ "$apuesta" == "Negro" && $((numganador % 2)) -eq 0 && $numganador -ne 0 ]]; then
            echo "¡Has ganado una cantidad de: $((cantidad * 3 / 2)) por apostar a Negro!"
            saldo=$((saldo + cantidad * 3 / 2))
        elif [[ "$apuesta" == "0" && $numganador -eq 0 ]]; then
            echo "¡Has ganado una cantidad de: $((cantidad * 10)) por apostar al número 0!"
            saldo=$((saldo + cantidad * 11))
        fi
    done

    guardar_saldo "$saldo"
    echo "---------------------------"
    echo "Saldo final después de todas las apuestas: $saldo"
    echo "---------------------------"
    return "$saldo"
}

# Función principal
main() {
    local saldo
    local h

    saldo=$(cargar_saldo)
    echo "Bienvenido a la ruleta, tu saldo es: $saldo"
    echo "---------------------------"

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
