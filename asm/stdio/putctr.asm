%ifndef STDIO_PUTCTR
%define STDIO_PUTCTR

;Prints text in the middle of the screen
;si - string
putctr_width equ 80
putctr:
	pushf
	pusha
	mov di, si
	mov ax, 0
	putctr_meas_loop:
		cmp [si], byte 0
		je putctr_meas_end
		inc si
		inc ax
		jmp putctr_meas_loop
	putctr_meas_end:
	shr ax, 1
	mov bx, putctr_width/2
	sub bx, ax
	jc putctr_end
	mov al, ' '
	mov ah, 0xe
	putctr_pad_loop:
		cmp bx, 0
		je putctr_pad_end
		int 0x10
		dec bx
		jmp putctr_pad_loop
	putctr_pad_end:
	mov si, di
	mov ah, 0xe
	putctr_loop:
		mov al, [si]
		cmp al, 0
		je putctr_end
		int 0x10
		inc si
		jmp putctr_loop
	putctr_end:
	popa
	popf
	ret

	%endif
