//OPIS: ugnjezdeni jiro
//RETURN: 3
int main() {
    int a = 1;
    int b = 3;
    jiro [a]{
		tranga 1 ->
		{
			jiro [b]{
				tranga 3 ->
					a = a + 5;
				toerana ->
					a = a + b;
	 		}
		}
		toerana ->
			a = a + b;
	 }
	 return b;
}

