;Print contents of al register on screen (as hex number)
;al - value
puthexb:
	pushf
	pusha
	push ax
	and ax, 0x00f0					;Fetch older 4 bits
	shr ax, 4						;Shift them into lower position
	mov si, puthexb_assoc			;
	add si, ax						;Add offset to assoc table address
	mov al, [si]					;Print character
	mov ah, 0xe						;
	int 0x10						;
	pop ax							;Restore initial value to display
	and ax, 0x000f					;Get 4 younger bits
	mov si, puthexb_assoc			;
	add si, ax						;Add offset to assoc table address
	mov al, [si]					;Print character
	mov ah, 0xe						;
	int 0x10						;
	popa
	popf
	ret
	puthexb_assoc: db '0123456789abcdef'

;Print contents of ax register on screen (as hex number)
;ax - value
puthexw:
	pushf
	pusha
	mov bx, ax
	shr ax, 8
	call puthexb
	mov ax, bx
	call puthexb
	popa
	popf
	ret
