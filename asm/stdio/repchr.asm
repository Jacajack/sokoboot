%ifndef STDIO_REPCHR
%define STDIO_REPCHR

;Prints character repeatedly
;al - char
;cx - times

repchr:
	pushf
	pusha
	mov ah, 0xe
	repchr_loop:
		int 0x10
		loop repchr_loop
	popa
	popf
	ret

%endif
