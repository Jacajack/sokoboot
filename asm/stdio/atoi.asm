%ifndef STDIO_ATOI
%define STDIO_ATOI

;Parses string pointed by si and returns its decimal value in ax
;Supports only unsigned integers
;If strings cointains some unsupported characters at the end they are ignored
;If two digits are separated by unsupported character string is considered bad
;si - string
;return ax - value
;return cf - if set - bad string
atoi:
	pushf					;
	pusha					;
	mov ax, 0				;Clear value register
	mov bx, 0				;Clear character register
	mov cx, 10				;Multiplier
	mov dl, 0				;Register for 'bad character' flag
	atoi_l:					;Main loop
		mov bl, [si]		;Get character from string
		test bl, bl			;Check if it's zero
		jz atoi_end			;If it's zero, quit
		sub bl, '0'			;Else, substract 48 from it
		jc atoi_bad			;On overroll, assume char to be bad
		cmp bl, 9			;If the result is greater than 9
		ja atoi_bad			;Also assume char to be bad
		mul cx				;Multiply value register
		jo atoi_abort		;On overflow, assume string to be invalid
		add ax, bx			;Add new character value to the buffer
		atoi_ok:			;
		test dl, 1			;Check if we've encountered any bad characters
		jnz atoi_abort		;If so, abort
		inc si				;Else, go on
		jmp atoi_l			;Loop
		atoi_bad:			;
		mov dl, 1			;Set 'first bad character flag'
		inc si				;Increment pointer
		jmp atoi_l			;Loop
	atoi_end:				;
	mov [atoi_val], ax		;Save value
	popa					;Restore registers
	mov ax, [atoi_val]		;Restore the value to ax
	popf					;Restore flags
	clc						;Clear carry flag - success
	ret						;
	atoi_abort:				;
	popa					;Restore registers
	mov ax, 0				;Write 0 to ax
	popf					;Restore flags
	stc						;Set carry flag - error
	ret						;
	atoi_val: dw 0			;Value read from string


%endif
