%ifndef STDIO_CURSOR
%define STDIO_CURSOR

;Hide cursor
hcursor:
	pushf
	pusha
	mov bx, 0
	mov ah, 3			;Get cursor position and shape
	int 0x10			;
	or ch, ( 1 << 5 )	;Set bit 5 of CH
	mov ah, 1			;Set cursor shape
	int 0x10			;
	popa
	popf
	ret

;Show cursor
scursor:
	pushf
	pusha
	mov bx, 0			;
	mov ah, 3			;Get cursor position and shape
	int 0x10			;
	and ch, ~( 1 << 5 )	;Clear bit 5 of CH
	mov ah, 1			;Set cursor shape
	int 0x10			;
	popa
	popf
	ret

%endif
