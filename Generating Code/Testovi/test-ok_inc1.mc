//OPIS: inkrement operator unutar izraza i kao sam izraz
//RETURN: 1

int main() {
    int a,b,c;
    a = 1;
    b = 2;
    c = 3;
    a = b + c++ - 5;
    a++;
    return a;
}
