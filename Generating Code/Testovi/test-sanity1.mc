//OPIS: Sanity check za miniC gramatiku
//RETURN: 0

/*
	Viselinijski komentar
*/

int f(int x) {
    int y;
    y = 1;
    return x + 2 - y;
}

unsigned f2() {
    return 2u;
}

unsigned ff(unsigned x) {
    unsigned y = 1u;
    return x + f2() - y;
}

int main() {
    int a;
    int b = 2;
    int aa = 0;
    int bb = 0;
    int c = 0;
    int d = 0;
    unsigned u = 0u;
    unsigned w = 0u;
    unsigned uu = 0U;
    unsigned ww = 0U;

    //poziv funkcije
    a = f(3);
   
    //if iskaz sa else delom
    if (a < b)  //1
        a = 1;
    else
        a = -2;

    if (a + c == b + d - 4) //2
        a = 1;
    else
        a = 2;

    if (u == w) {   //3
        u = ff(1u);
        a = f(11);
    }
    else {
        w = 2u;
    }
    if (a + c == b - d - -4) {  //4
        a = 1;
    }
    else
        a = 2;
    a = f(42);

    if (a + (aa-c) - d < b + (bb-a))    //5
        uu = w-u+uu;
    else
        d = aa+bb-c;

    //if iskaz bez else dela
    if (a < b)  //6
        a = 1;

    if (a + c == b - +4)    //7
        a = 1;
    
    return 0;
}

