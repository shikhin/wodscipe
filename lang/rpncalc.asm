%include "wodscipe.inc"

	mov si, msg
	call puts
	
	ret

msg: db "\o/", 10, 0
