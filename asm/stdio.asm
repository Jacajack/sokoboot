;Very basic set of stdio tools

;Print single character on screen
;al - character to print
putc:
	pushf
	pusha
	mov ah, 0xE	;Put character on screen
	int 0x10	;Interrupt 10h
	popa
	popf
	ret

;Print null terminated string on screen
;si - string address
puts:
	pushf
	pusha
	mov ah, 0xE
	puts_l1:
		cmp [si], byte 0
		je puts_end
		mov al, [si]
		int 0x10
		inc si
		jmp puts_l1
	puts_end:
	popa
	popf
	ret

;Clear screen in text mode
cls:
	pushf
	pusha
	mov al, 0x02	;Change gfx mode to text mode (that should be enough)
	mov ah, 0		;
	int 0x10		;
	popa
	popf
	ret

;Fetch keystroke (wait)
;return al - ASCII code
;return ah - BIOS scancode
getc:
	pushf					;Push registers
	pusha					;
	mov al, 0x00			;Get character
	mov ah, 0x00			;
	int 0x16				;Call interrupt
	mov [getc_key], ax		;Store key in memory
	popa					;Pop registers
	popf					;
	mov ax, [getc_key]		;Get key into register
	ret
	getc_key: dw 0

;Fetch keystroke (wait)
;return al - 0 if keyboard buffer is empty
kbhit:
	pushf
	pusha
	mov ah, 0x01		;Call interrupt to check keyboard buffer
	int 0x16			;
	jz kbhit_nokey		;ZF set - no key
	kbhit_key:			;Keystroke awaiting
	mov al, 1			;
	mov [kbhit_b], al	;
	jmp kbhit_end		;
	kbhit_nokey:		;No keystroke
	mov al, 0			;
	mov [kbhit_b], al	;
	kbhit_end:			;Exit point
	popa				;
	mov al, [kbhit_b]	;Load return value into al
	popf
	ret
	kbhit_b: db 0

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
