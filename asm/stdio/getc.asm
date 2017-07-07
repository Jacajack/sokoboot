%ifndef STDIO_GETC
%define STDIO_GETC

;Fetch keystroke (wait)
;return al - ASCII code
;return ah - BIOS scancode
getc:
	pushf					;Push registers
	pusha					;
	mov al, 0x00			;Get character
	mov ah, 0x00			;
	int 0x16				;Call interrupt
	mov [getc_key], ax		;Store key in memory
	popa					;Pop registers
	popf					;
	mov ax, [getc_key]		;Get key into register
	ret
	getc_key: dw 0

%endif
