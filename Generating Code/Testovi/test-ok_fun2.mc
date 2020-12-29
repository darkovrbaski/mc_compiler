//OPIS: funkcija sa vise parametra
//RETURN: 7

int f(int a, int b, unsigned c) {
   return b + a;
}

int main() {
    int a = 5,b = 6;
    a = f(1, b, 3U);
    return a;
}
