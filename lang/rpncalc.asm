%include "wodscipe.inc"

start:
	mov si, msg
	call puts
	
.loop:
	call getch
	call putchar
	
	cmp al, 10
	jne .loop
	
	ret

msg: db "\o/", 10, 0
