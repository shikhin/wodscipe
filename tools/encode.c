#include <stdio.h>

int
main(void) {
	char buf[32766]; /* Upper 32K of first segment minus 2 bytes for size */
	unsigned int i, j;
	int c;
	
	for(i=0; (c=getchar())>-1; i++) {
		if(i>=sizeof(buf)) {
			fprintf(stderr, "Error: File too big to fit.\n");
			return 1;
		}
		
		buf[i]=c;
	}
	
	putchar(i%256);
	putchar(i/256);
	fwrite(buf, 1, i, stdout);
	
	return 0;
}
