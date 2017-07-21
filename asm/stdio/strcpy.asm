%ifndef STDIO_STRCPY
%define STDIO_STRCPY

;Copy string
;si - source
;di - destination
strcpy:
	pushf
	pusha
		cld					;Clear direction flag
		strcpy_loop:		;Loop
		cmp byte [si], 0	;Check if we reached NUL
		je strcpy_end		;If so, quit
		cmp byte [di], 0	;
		je strcpy_end		;
		movsb				;Copy byte
		jmp strcpy_loop		;Loop
	strcpy_end:
	popa
	popf
	ret

%endif
