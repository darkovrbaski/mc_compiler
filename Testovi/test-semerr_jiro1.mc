//OPIS: ne deklarisan <jiro_expression>
int main() {
    int b,c;
    
    jiro [a]{
		tranga 1 ->
			a = a + 5;
			finish;
		tranga 5 ->
		{
			b = 3;
		}
		toerana ->
			a = a + b;
	 }
}

