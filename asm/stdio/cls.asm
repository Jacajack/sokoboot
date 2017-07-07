;Clear screen in text mode
cls:
	pushf
	pusha
	mov al, 0x02	;Change gfx mode to text mode (that should be enough)
	mov ah, 0		;
	int 0x10		;
	popa
	popf
	ret
