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
    local ruleta=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "32" "33" "34" "35" "36")
    local cero="0"

    echo "-------------------------"
    if [[ $numero -eq 0 ]]; then
        cero=" X"
    fi
    echo "|         $cero        |"
    echo "-------------------------"

    for i in ${!ruleta[@]}; do
        if [[ ${ruleta[$i]} -eq $numero ]]; then
            ruleta[$i]=" X"
        fi
    done

    for ((i = 0; i < 36; i+=4)); do
        printf "| %2s | %2s | %2s | %2s |\n" "${ruleta[$i]}" "${ruleta[$i+1]}" "${ruleta[$i+2]}" "${ruleta[$i+3]}"
    done

    echo "-------------------------"
    echo "Bola en $numero"
}

obtener_color() {
    local num=$1
    if [[ $num -eq 0 ]]; then
        echo "Verde"
    elif [[ "1 3 5 7 9 12 14 16 18 19 21 23 25 27 30 32 34 36" =~ " $num " ]]; then
        echo "Rojo"
    else
        echo "Negro"
    fi
}

Apuesta() {
    local saldo=$1
    local apuestas=()
    local cantidades=()
    local apuesta_rojo=0
    local apuesta_negro=0
    local total_numeros_apostados=0
    local max_numeros=18

    while (( total_numeros_apostados < max_numeros )); do
        echo ""
        read -p "¿Quieres hacer una apuesta? [y/n] " h
        if [[ "$h" =~ ^[Yy]$ || "$h" == "" || "$h" =~ ^[Yy]es$ ]]; then
            echo "----------------------"
            read -p "Haz tu apuesta (Rojo, Negro, 1-12, 13-24, 25-36, C1, C2, C3 o un número del 0 al 36. Piensa que máximo son 18 números): " apuesta

            if [[ "$apuesta" == "Rojo" && $apuesta_negro -eq 1 ]] || [[ "$apuesta" == "Negro" && $apuesta_rojo -eq 1 ]]; then
                echo "No puedes apostar a ambos colores o repetir color."
                continue
            fi

            local numeros_cubiertos=0
            if [[ "$apuesta" == "Rojo" || "$apuesta" == "Negro" ]]; then
                numeros_cubiertos=18
            elif [[ "$apuesta" == "1-12" || "$apuesta" == "13-24" || "$apuesta" == "25-36" ]]; then
                numeros_cubiertos=12
            elif [[ "$apuesta" == "C1" || "$apuesta" == "C2" || "$apuesta" == "C3" ]]; then
                numeros_cubiertos=12
            elif [[ "$apuesta" =~ ^[0-9]+$ && "$apuesta" -ge 0 && "$apuesta" -le 36 ]]; then
                numeros_cubiertos=1
            else
                echo "Apuesta inválida."
                continue
            fi

            if (( total_numeros_apostados + numeros_cubiertos > max_numeros )); then
                echo "No puedes cubrir más de 18 números. Esta apuesta cubriría $numeros_cubiertos y ya llevas $total_numeros_apostados."
                continue
            fi

            total_numeros_apostados=$((total_numeros_apostados + numeros_cubiertos))

            if [[ "$apuesta" == "Rojo" ]]; then
                apuesta_rojo=1
            elif [[ "$apuesta" == "Negro" ]]; then
                apuesta_negro=1
            fi

            apuestas+=("$apuesta")

            read -p "Introduce la cantidad a apostar para esta opción: " canta
            while [[ $canta -gt $saldo || $canta -le 0 ]]; do
                read -p "Cantidad inválida. Introduce una menor o igual a $saldo y mayor a 0: " canta
            done
            cantidades+=("$canta")
            saldo=$((saldo - canta))
            guardar_saldo "$saldo"
        else
            break
        fi
    done

    numganador=$((RANDOM % 37))
    color=$(obtener_color "$numganador")
    mostrar_ruleta "$numganador"

    local ganancia=0

    for idx in "${!apuestas[@]}"; do
        local apuesta="${apuestas[$idx]}"
        local cantidad="${cantidades[$idx]}"

        case "$apuesta" in
            Rojo)
                if [[ "$color" == "Rojo" ]]; then
                    g=$((cantidad * 2))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g en Rojo"
                fi
                ;;
            Negro)
                if [[ "$color" == "Negro" ]]; then
                    g=$((cantidad * 2))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g en Negro"
                fi
                ;;
            1-12)
                if (( numganador >= 1 && numganador <= 12 )); then
                    g=$((cantidad * 3))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g en la docena 1-12"
                fi
                ;;
            13-24)
                if (( numganador >= 13 && numganador <= 24 )); then
                    g=$((cantidad * 3))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g en la docena 13-24"
                fi
                ;;
            25-36)
                if (( numganador >= 25 && numganador <= 36 )); then
                    g=$((cantidad * 3))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g en la docena 25-36"
                fi
                ;;
            C1)
                if (( numganador % 3 == 1 && numganador != 0 )); then
                    g=$((cantidad * 3))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g en Columna 1"
                fi
                ;;
            C2)
                if (( numganador % 3 == 2 && numganador != 0 )); then
                    g=$((cantidad * 3))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g en Columna 2"
                fi
                ;;
            C3)
                if (( numganador % 3 == 0 && numganador != 0 )); then
                    g=$((cantidad * 3))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g en Columna 3"
                fi
                ;;
            *)
                if [[ "$apuesta" -eq "$numganador" ]]; then
                    g=$((cantidad * 36))
                    ganancia=$((ganancia + g))
                    echo "Ganaste $g apostando al número $apuesta"
                fi
                ;;
        esac
    done

    saldo=$((saldo + ganancia))
    guardar_saldo "$saldo"
    echo "Saldo actual: $saldo"
}

main() {
    local saldo
    saldo=$(cargar_saldo)
    echo "Bienvenido a la ruleta, tu saldo es: $saldo"
    echo "---------------------------"

    while true; do
        read -p "¿Deseas empezar? [Y/n] " h
        case "$h" in
            [Yy]*|"")
                Apuesta "$saldo"
                saldo=$(cargar_saldo)
                ;;
            [Nn]*)
                xdg-open "minero.png"
                read -p "¿Seguro que deseas salir? Y/n] " confirm
                if [[ "$confirm" =~ ^[Yy]$ || "$confirm" == "" ]]; then
                    break
                fi
                ;;
            *)
                echo "Opción no válida."
                ;;
        esac
    done
    echo "Gracias por jugar y regalarnos tu dinero <3"
}

main
