#include "bits/stdc++.h"
using namespace std;

float Apuesta(int saldo){
    string apuesta;
    int canta = 0, numap;
    cout << "Dispones de un saldo de: " << saldo << ".\n";
    cout << "Haz tu apuesta: (Rojo, Negro o un número del 0 al 36).\n";
    cin >> apuesta;
    cout << "Ahora introduce la cantidad a apostar: ";
    cin >> canta;
    if(canta > saldo){
        cout << "Introduce una cantidad válida. (Menor o igual a " << saldo << ")\n";
        cin >> canta; }
    saldo -= canta;
    int numganador = rand() % 37;
    cout << "La bola ha caído en " << numganador << ".\n";
  if (apuesta == to_string(numganador) && numganador != 0) { 
            cout << "Has ganado una cantidad de: " << canta * 4 << endl; 
            saldo += canta * 5; 
    }
    else{
        if (apuesta == "Rojo" && (numganador % 2 != 0 && numganador != 0)) { 
            cout << "Has ganado una cantidad de: " << canta * 1.5 << endl; 
            saldo += canta * 1.5;}
        else if (apuesta == "Negro" && (numganador % 2 != 1 && numganador != 0)) { 
            cout << "Has ganado una cantidad de: " << canta * 1.5 << endl; 
            saldo += canta * 1.5;}
        else if (apuesta == "0" && numganador == 0){
            cout << "Has ganado una cantidad de: " << canta * 10 << endl; 
            saldo += canta * 11;
        }
        else{
            cout << "Has perdido la apuesta. " << endl;
            
        }
    }
    return saldo;
}

int main(){
int a = 1;
float saldo = 500, Apuesta(int saldo);
string h;
while (a == 1)
{
    saldo = Apuesta(saldo);
    if(saldo == 0){
        a = 0;
    }
    else{
    cout << "Tu saldo restante es: " << saldo << ".\n" << "Deseas continuar? [Y/N] ";
    cin >> h;
    if(h == "Y" || h == "y" || h=="" || h == "yes" || h== "Yes"){
        a = 1;
    }
    else if(h == "N" || h == "n" || h=="No" || h == "no" || h== "NO"){
        a = 0;
    }
    else{
        cout << "Opción no válida. [Y/N]";
    }
    }
}
    cout << "Gracias por jugar y regalarnos tu dinero <3" << endl;
}