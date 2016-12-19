;Dislays hexadecimal number
puthex:
	pushf
	pusha
	push ax

	and ax, 0xf0					;Fetch older 4 bits
	shr ax, 4						;Shift them into lower position
	mov si, puthex_assoc			;
	add si, ax						;Add offset to assoc table address

	mov al, [si]					;Print character
	mov ah, 0xe						;
	int 0x10						;

	pop ax							;Restore initial value to display
	and ax, 0x0f					;Get 4 younger bits
	mov si, puthex_assoc			;
	add si, ax						;Add offset to assoc table address

	mov al, [si]					;Print character
	mov ah, 0xe						;
	int 0x10						;
	;
	popa
	popf
	ret
	puthex_assoc: db '0123456789abcdef'
