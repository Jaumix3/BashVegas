#!/bin/bash

guardar_saldo() {
    local saldo=$1
    echo -n "$saldo" | base64 > ~/saldo.txt
}

cargar_saldo() {
    if [[ ! -f ~/saldo.txt ]]; then
        echo "100" | base64 > ~/saldo.txt
    fi
    local saldo_base64
    saldo_base64=$(cat ~/saldo.txt)
    echo $(echo "$saldo_base64" | base64 --decode)
}

mostrar_ruleta() {
    local numero=$1
    local ruleta=()
    for ((i=1; i<=36; i++)); do
        ruleta+=("$i")
    done
    local cero="0"
    echo "----------------"
    if [[ $numero -eq 0 ]]; then
        cero=" X"
    fi
    echo "|       $cero      |"
    echo "----------------"
    for i in ${!ruleta[@]}; do
        if [[ ${ruleta[$i]} -eq $numero ]]; then
            ruleta[$i]=" X"
        fi
    done
    for ((i = 0; i < 36; i+=3)); do
        printf "| %2s | %2s | %2s |\n" "${ruleta[$i]}" "${ruleta[$i+1]}" "${ruleta[$i+2]}"
    done
    echo "----------------"
    echo "Bola en $numero"
}

obtener_color() {
    local num=$1
    if [[ $num -eq 0 ]]; then
        echo "Verde"
    elif [[ " 1 3 5 7 9 12 14 16 18 19 21 23 25 27 30 32 34 36 " =~ " $num " ]]; then
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
        read -p "¿Quieres hacer una apuesta? [Y/n] " h
        if [[ "$h" =~ ^[Yy]$ || "$h" == "" || "$h" =~ ^[Yy]es$ ]]; then
            apuesta=$(dialog --clear --stdout \
                --title "Selecciona tu apuesta" \
                --menu "¿Dónde quieres apostar?" 20 50 40 \
                Rojo "Color Rojo (18 números)" \
                Negro "Color Negro (18 números)" \
                "1-12" "Primera docena" \
                "13-24" "Segunda docena" \
                "25-36" "Tercera docena" \
                C1 "Columna 1" \
                C2 "Columna 2" \
                C3 "Columna 3" \
                0 "Número 0" \
                $(for i in $(seq 1 36); do echo "$i Número $i"; done))

            if [[ $? -ne 0 || -z "$apuesta" ]]; then
                echo "Apuesta cancelada"
                continue
            fi

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

            cantidad=$(dialog --clear --stdout \
                --title "Cantidad a apostar" \
                --rangebox "Selecciona la cantidad a apostar (Saldo actual: $saldo)" 0 50 1 100 "$saldo")

            if [[ $? -ne 0 || -z "$cantidad" || ! "$cantidad" =~ ^[0-9]+$ || "$cantidad" -le 0 || "$cantidad" -gt "$saldo" ]]; then
                echo "Cantidad inválida o apuesta cancelada."
                continue
            fi

            cantidades+=("$cantidad")
            saldo=$((saldo - cantidad))
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
                    ganancia=$((ganancia + cantidad * 2))
                fi
                ;;
            Negro)
                if [[ "$color" == "Negro" ]]; then
                    ganancia=$((ganancia + cantidad * 2))
                fi
                ;;
            1-12)
                if (( numganador >= 1 && numganador <= 12 )); then
                    ganancia=$((ganancia + cantidad * 3))
                fi
                ;;
            13-24)
                if (( numganador >= 13 && numganador <= 24 )); then
                    ganancia=$((ganancia + cantidad * 3))
                fi
                ;;
            25-36)
                if (( numganador >= 25 && numganador <= 36 )); then
                    ganancia=$((ganancia + cantidad * 3))
                fi
                ;;
            C1)
                if (( numganador % 3 == 1 && numganador != 0 )); then
                    ganancia=$((ganancia + cantidad * 3))
                fi
                ;;
            C2)
                if (( numganador % 3 == 2 && numganador != 0 )); then
                    ganancia=$((ganancia + cantidad * 3))
                fi
                ;;
            C3)
                if (( numganador % 3 == 0 && numganador != 0 )); then
                    ganancia=$((ganancia + cantidad * 3))
                fi
                ;;
            *)
                if [[ "$apuesta" -eq "$numganador" ]]; then
                    ganancia=$((ganancia + cantidad * 36))
                fi
                ;;
        esac
    done

    saldo=$((saldo + ganancia))
    guardar_saldo "$saldo"
    echo "Saldo actual: $saldo"
}

normas() {
    read -p "¿Deseas 'E'mpezar o leer las 'n'ormas? [E/n] " pk
    case "$pk" in
        [Ee]*|"")
            ;;
        [Nn]*)
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            cat "$SCRIPT_DIR/normas.txt"
            ;;
        *)
            ;;
    esac
}

main() {
    local saldo
    saldo=$(cargar_saldo)
    normas
    echo "Bienvenido a la ruleta, tu saldo es: $saldo"
    while true; do
        read -p "¿Deseas continuar? [Y/n] " h
        case "$h" in
            [Yy]*|"")
                Apuesta "$saldo"
                saldo=$(cargar_saldo)
                ;;
            [Nn]*)
                xdg-open "minero.png"
                read -p "¿Seguro que deseas salir? [Y/n] " confirm
                if [[ "$confirm" =~ ^[Yy]$ || "$confirm" == "" ]]; then
                    break
                fi
                ;;
            *)
                ;;
        esac
    done
    echo "Gracias por jugar y regalarnos tu dinero <3"
}

main
