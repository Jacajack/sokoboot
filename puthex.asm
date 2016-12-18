;Dislays hexadecimal number
puthex:
	pushf
	pusha
	push ax
	;
	and ax, 0xf0
	shr ax, 4
	and ax, 0x0f
	mov si, puthex_assoc
	add si, ax
	;
	mov al, [si]
	mov ah, 0xe
	int 0x10
	;
	pop ax
	and ax, 0x0f
	mov si, puthex_assoc
	add si, ax
	;
	mov al, [si]
	mov ah, 0xe
	int 0x10
	;
	popa
	popf
	ret
	puthex_assoc: db '0123456789abcdef'
