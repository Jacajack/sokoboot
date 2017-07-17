%ifndef STDIO_REPCHR
%define STDIO_REPCHR

;Prints character repeatedly
;al - char
;cx - times

repchr:
	pushf
	pusha
	mov ah, 0xe				;We will be printing characters
	repchr_loop:			;Loop label
		int 0x10			;Call interrupt 0x10
		loop repchr_loop	;Loop if cx != 0 and decrement it
	popa
	popf
	ret

%endif
