//OPIS: primer dva jiro iskaza jedan za drugim 
//RETURN: 6

int main() {
    int a = 5, b = 5;
    
	 jiro [a]{
    	tranga 1 ->
			a = a + 5;
			finish;
		tranga 5 ->
		{
			a = 1;
		}
		tranga 6 -> b = 3;
		toerana ->
			a = a + b;
	 }
	 
	 jiro [a]{
    	tranga 1 ->
			a = a + 5;
			finish;
		tranga 5 ->
		{
			b = 3;
		}
		tranga 6 -> b = 3;
		toerana ->
			a = a + b;
	 }
	 return 6;
}
