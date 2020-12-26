//OPIS: for iskaz pogresan tip deklaracije i nula za literal koraka
int main() {
    int a,b,c;
    b = 10;
    for (int a = 5u; a < b; 20) {
    	c = a + b;
    	for (unsigned a = 1; a < b; 0) {
    		c = c - 1;
    	}
    }
}
