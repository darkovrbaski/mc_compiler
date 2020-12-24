//OPIS: dav uslovna izraza
//RETURN: 22

int y;

int main() {
    int a;
    a = 2;
    y = 6;
    a = (a > y) ? a : 20 + (a < y) ? a : 50;
    return a;
}

