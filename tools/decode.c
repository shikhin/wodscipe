#include <stdio.h>

int
main(void) {
	unsigned int i;
	int c;
	
	if((c=getchar())==-1) {
		fprintf(stderr, "Error: Not enough data.\n");
		return 1;
	}
	
	i=c%256;
	
	if((c=getchar())==-1) {
		fprintf(stderr, "Error: Not enough data.\n");
		return 1;
	}
	i=c*256+i;
	
	while(i--) {
		if((c=getchar())==-1) {
			fprintf(stderr, "Error: Not enough data.\n");
			return 1;
		}
		putchar(c);
	}
	
	fflush(stdout);
	
	return 0;
}
