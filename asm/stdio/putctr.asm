%ifndef STDIO_PUTCTR
%define STDIO_PUTCTR

;Prints text in the middle of the screen
;Only supports one line strings
;si - string
putctr_width equ 80
putctr:
	pushf
	pusha
	mov di, si					;Store string address
	mov ax, 0					;Reset counter
	putctr_meas_loop:			;
		cmp [si], byte 0		;Check if character is CR, LF or NUL
		je putctr_meas_end		;
		cmp [si], byte 10		;
		je putctr_meas_end		;
		cmp [si], byte 13		;
		je putctr_meas_end		;
		inc si					;If no, increment counters and loop
		inc ax					;
		jmp putctr_meas_loop	;
	putctr_meas_end:			;
	shr ax, 1					;Divide string length by 2
	mov cx, putctr_width/2		;
	sub cx, ax					;Substract it from half of screen width
	jc putctr_end				;On carry, quit
	mov al, ' '					;Pad out with spaces 
	mov ah, 0xe					;Interrupt settings
	putctr_pad_loop:			;Padding loop
		int 0x10				;Interrupt for character output
		loop putctr_pad_loop	;Loop
	mov si, di					;Restore string address
	putctr_loop:				;The main loop
		mov al, [si]			;Get character from string
		cmp al, 0				;Check if it's NUL
		je putctr_end			;If so, quit
		int 0x10				;Else, print it
		inc si					;Increment counter
		jmp putctr_loop			;Loop
	putctr_end:
	popa
	popf
	ret

	%endif
