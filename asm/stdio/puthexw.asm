%ifndef STDIO_PUTHEXW
%define STDIO_PUTHEXW
;Print contents of ax register on screen (as hex number)
;ax - value
puthexw:
	pushf
	pusha
	push ax
	shr ax, 8
	call puthexb
	pop ax
	call puthexb
	popa
	popf
	ret

%include "stdio/puthexb.asm"
%endif
