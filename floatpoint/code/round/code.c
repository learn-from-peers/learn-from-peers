#include <stdio.h>
#include <math.h>

const int n = 100000000;

int main()
{
	int i;
	float accum = 0.0f;

	//for(i = 1; i <= n; i++)
		//accum += 1.0f / i;

	for(i = n; i >= 1; i--)
		accum += 1.0f / i;

	if(accum == accum + 1.0f/n+1)
	printf("same\n");
	else
	printf("different\n");

	printf("%f\n", accum);

	return 0;
}
