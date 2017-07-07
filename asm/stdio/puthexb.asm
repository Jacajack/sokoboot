%ifndef STDIO_PUTHEXB
%define STDIO_PUTHEXB

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

%endif
