;Print single character on screen
;al - character to print
putc:
	pushf
	pusha
	mov ah, 0xE	;Put character on screen
	int 0x10	;Interrupt 10h
	popa
	popf
	ret
