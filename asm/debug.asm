%ifndef DEBUG_ASM
%define DEBUG_ASM

;Display registers content and wait for keypress
debug:
	pushf
	pusha
	call gotext
	mov si, debug_nl
	call puts
	mov si, debug_ax
	call puts
	call puthexw
	mov si, debug_nl
	call puts
	mov si, debug_bx
	call puts
	mov ax, bx
	call puthexw
	mov si, debug_nl
	call puts
	mov si, debug_cx
	call puts
	mov ax, cx
	call puthexw
	mov si, debug_nl
	call puts
	mov si, debug_dx
	call puts
	mov ax, dx
	call puthexw
	mov si, debug_nl
	call puts
	call getc	
	popa
	popf
	ret
	debug_nl: db 13, 10, 0
	debug_ax: db "ax = ", 0
	debug_bx: db "bx = ", 0
	debug_cx: db "cx = ", 0
	debug_dx: db "dx = ", 0
	
%include "stdio.asm"

%endif
