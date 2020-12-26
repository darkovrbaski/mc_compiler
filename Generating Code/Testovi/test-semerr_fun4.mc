//OPIS: poziv funkcije sa vise parametra, pogresni parametri

int f(int a, int b, unsigned c) { }

int main() {
	int a = 0;
	a = f(1, 2u, 3);
	return 0;
}

