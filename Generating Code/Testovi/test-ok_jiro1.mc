//OPIS: primer jiro iskaza
//RETURN: 3

int main() {
    int a = 5,b = 5;
    
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
	 return b;
}
