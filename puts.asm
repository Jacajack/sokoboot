;Displays null-terminated string
puts:
	pushf
	pusha
	puts_step:
		mov bx, [si]
		mov al, bl	;Get character
		cmp al, 0	;Check for null characetr
		je puts_end
		mov ah, 0xe	;Put character
		int 0x10	;BIOS interrupt
		add si, 1	;Increment pointer
		jmp puts_step
	puts_end:
	popa
	popf
	ret
