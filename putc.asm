putc:
	pushf
	pusha
	mov ah, 0xe
	int 0x10
	popa
	popf
	ret
