%ifndef STDIO_KBCLBUF
%define STDIO_KBCLBUF

;Empty keyboard buffer
kbclbuf:
	pushf
	pusha
	kbclbuf_loop:			;Loop
		call kbhit			;Check kb buffer
		test al, al			;If empty
		jz kbclbuf_end		;Quit
		call getc			;Else, read char
		jmp kbclbuf_loop	;And loop
	kbclbuf_end:
	popa
	popf
	ret

%include "stdio/kbhit.asm"
%include "stdio/getc.asm"
%endif
