%ifndef STDIO_ATOI
%define STDIO_ATOI

;Parses string pointed by si and returns its decimal value in ax
;Supports only unsigned integers
;si - string
;return ax - value
;return cf - if set - bad string
atoi:
	pushf					;
	pusha					;
	mov ax, 0				;Clear value register
	mov bx, 0				;Clear character register
	mov cx, 10				;Multiplier
	atoi_l:					;Main loop
		mov bl, [si]		;Get character from string
		test bl, bl			;Check if it's zero
		jz atoi_end			;If it's zero, quit
		sub bl, '0'			;Else, substract 48 from it
		jc atoi_bad			;On overroll, assume string to be bad
		cmp bl, 9			;If the result is greater than 9
		ja atoi_bad			;Also assume string to be bad
		mul cx				;Multiply value register
		jo atoi_bad			;On overflow, assume string to be invalid
		add ax, bx			;Add new character value to the buffer
		inc si				;Increment pointer
		jmp atoi_l			;Loop
	atoi_end:				;
	mov [atoi_val], ax		;Save value
	popa					;Restore registers
	mov ax, [atoi_val]		;Restore the value to ax
	popf					;Restore flags
	clc						;Clear carry flag - success
	ret						;
	atoi_bad:				;
	popa					;Restore registers
	mov ax, 0				;Write 0 to ax
	popf					;Restore flags
	stc						;Set carry flag - error
	ret						;
	atoi_val: dw 0			;Value read from string


%endif
