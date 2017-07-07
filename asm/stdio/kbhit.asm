%ifndef STDIO_KBHIT
%define STDIO_KBHIT

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

%endif
