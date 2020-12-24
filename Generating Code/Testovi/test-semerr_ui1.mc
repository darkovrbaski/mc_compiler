//OPIS: uslovni izraz razliciti tipovi exp-a
//RETURN: 50

unsigned y;

int main() {
    int a;
    a = 2;
    y = 6u;
    a = (a == 5) ? a : y;
    return a;
}

