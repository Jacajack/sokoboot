%ifndef STDIO_PUTHEXW
%define STDIO_PUTHEXW
;Print contents of ax register on screen (as hex number)
;ax - value
puthexw:
	pushf
	pusha
	mov bx, ax
	shr ax, 8
	call puthexb
	mov ax, bx
	call puthexb
	popa
	popf
	ret

%include "stdio/puthexb.asm"
%endif
