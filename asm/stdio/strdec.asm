%ifndef STDIO_STRDEC
%define STDIO_STRDEC

;Write ax value to string as decimal value
;ax - value
;di - output buffer
;carry flag - if set, trailing zeros are displayed
strdec:
	pushf
	pusha
	mov bx, 0				;Clear bx
	jnc strdec_start		;If carry flag is not set - continue routine
	mov bx, 0xffff			;Else, set all bx bits
	strdec_start:			;
	mov dx, 0				;Clear reminder register
	mov cx, 10				;We will be dividing by 10
	div cx					;Divide ax by 10
	push dx					;Push reminder
	mov dx, 0				;Reset reminder
	div cx					;Divide ax by 10
	push dx					;Push reminder
	mov dx, 0				;Reset reminder
	div cx					;Divide ax by 10
	push dx					;Push reminder
	mov dx, 0				;Reset reminder
	div cx					;Divide ax by 10
	push dx					;Push reminder
	mov dx, 0				;Reset reminder
	div cx					;Divide ax by 10
	push dx					;Push reminder
							;
	mov cx, bx				;Get cx initial value
	mov bx, 0				;Clear bx
	cld						;Clear direction flag
	strdec_10000:			;
	pop ax					;Pop digit to ax
	or cx, ax				;Bitwise or ax with cx
	test cx, cx				;If cx is 0, we can skip the digit
	jz strdec_1000			;
	add al, '0'				;Add '0' character to digit number
	stosb					;Write byte to string
	strdec_1000:			;
	pop ax					;Pop digit to ax
	or cx, ax				;Bitwise or ax with cx
	test cx, cx				;If cx is 0, we can skip the digit
	jz strdec_100			;
	add al, '0'				;Add '0' character to digit number
	stosb					;Write byte to string
	strdec_100:				;
	pop ax					;Pop digit to ax
	or cx, ax				;Bitwise or ax with cx
	test cx, cx				;If cx is 0, we can skip the digit
	jz strdec_10			;
	add al, '0'				;Add '0' character to digit number
	stosb					;Write byte to string
	strdec_10:				;
	pop ax					;Pop digit to ax
	or cx, ax				;Bitwise or ax with cx
	test cx, cx				;If cx is 0, we can skip the digit
	jz strdec_1				;
	add al, '0'				;Add '0' character to digit number
	stosb					;Write byte to string
	strdec_1:				;
	pop ax					;Pop digit to ax
	add al, '0'				;Add '0' character to digit number
	stosb					;Write byte to string
	popa
	popf
	ret


%endif
