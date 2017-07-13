%ifndef STDIO_PUTDEC
%define STDIO_PUTDEC

;Print value as decimal number
;ax - value
;carry flag - if set, trailing zeros are displayed
putdec:
	pushf
	pusha
	mov bx, 0			;Clear bx
	jnc putdec_start	;If carry flag is not set - continue routine
	mov bx, 0xffff		;Else, set all bx bits
	putdec_start:		;
	mov dx, 0			;Clear reminder register
	mov cx, 10			;We will be dividing by 10
	div cx				;Divide ax by 10
	push dx				;Push reminder
	mov dx, 0			;Reset reminder
	div cx				;Divide ax by 10
	push dx				;Push reminder
	mov dx, 0			;Reset reminder
	div cx				;Divide ax by 10
	push dx				;Push reminder
	mov dx, 0			;Reset reminder
	div cx				;Divide ax by 10
	push dx				;Push reminder
	mov dx, 0			;Reset reminder
	div cx				;Divide ax by 10
	push dx				;Push reminder
						;
	mov cx, bx			;Get cx initial value
	mov bx, 0			;Clear bx
	putdec_10000:		;
	pop ax				;Pop digit to ax
	or cx, ax			;Bitwise or ax with cx
	test cx, cx			;If cx is 0, we can skip the digit
	jz putdec_1000		;
	add al, '0'			;Add '0' character to digit number
	mov ah, 0xE			;Display digit on screen
	int 0x10			;
	putdec_1000:		;
	pop ax				;Pop digit to ax
	or cx, ax			;Bitwise or ax with cx
	test cx, cx			;If cx is 0, we can skip the digit
	jz putdec_100		;
	add al, '0'			;Add '0' character to digit number
	mov ah, 0xE			;Display digit on screen
	int 0x10			;
	putdec_100:			;
	pop ax				;Pop digit to ax
	or cx, ax			;Bitwise or ax with cx
	test cx, cx			;If cx is 0, we can skip the digit
	jz putdec_10		;
	add al, '0'			;Add '0' character to digit number
	mov ah, 0xE			;Display digit on screen
	int 0x10			;
	putdec_10:			;
	pop ax				;Pop digit to ax
	or cx, ax			;Bitwise or ax with cx
	test cx, cx			;If cx is 0, we can skip the digit
	jz putdec_1			;
	add al, '0'			;Add '0' character to digit number
	mov ah, 0xE			;Display digit on screen
	int 0x10			;
	putdec_1:			;
	pop ax				;Pop digit to ax
	add al, '0'			;Add '0' character to digit number
	mov ah, 0xE			;Display digit on screen
	int 0x10			;
	popa
	popf
	ret


%endif
