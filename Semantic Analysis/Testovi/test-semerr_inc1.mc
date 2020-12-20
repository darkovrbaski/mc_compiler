//OPIS: promenljiva uz inkrement operator nije istog tipa 
int main() {
    int a,b;
    unsigned c; 
    c = 3u;
    a = 1;
    b = 2;
    a = b + c++ - 5;
}
