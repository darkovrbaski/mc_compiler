//OPIS: ugnjezdeni jiro
int main() {
    int b,c,a = 1;
    unsigned z = 2u;
    
    jiro [a]{
		tranga 1 ->
			a = a + 5;
			finish;
		tranga 2 ->
		{
			jiro [z]{
				tranga 1u ->
					a = a + 5;
					finish;
				tranga 2u ->
				{
					b = 3;
				}
				toerana ->
					a = a + b;
	 		}
		}
		tranga 3 ->
				{
					b = 3;
				}
		toerana ->
			a = a + b;
	 }
}

