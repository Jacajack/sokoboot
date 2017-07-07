;Switch to text mode if it isn't currently enabled
gotext:
	pushf
	pusha
	mov ax, 0		;Clear ax
	mov ah, 0xF		;We will be reading current graphics mode
	int 0x10		;Call interrput
	cmp al, 0x02	;Check if current mode is standard text mode
	je gotext_end	;If so, quit (not to clear the screen)
	mov ah, 0		;Change video mode
	mov al, 0x02	;Text mode
	int 0x10		;Run interrupt
	gotext_end:
	popa
	popf
	ret
