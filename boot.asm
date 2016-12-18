[org 0x500]

mov si, load_success_s
call puts

mov si, final_s
call puts


mov bx, 0
dots:
	mov ax, 100
	call delay
	add bx, 1
	mov al, '.'
	call putc
	cmp bx, 80
	jl dots


call gfxtest

jmp 0x700
jmp $

%include "putc.asm"
%include "puts.asm"
%include "gfxtest.asm"
%include "gfxutils.asm"
%include "timeutils.asm"

load_success_s:
	db ' -> EXECUTION OUTSIDE BOOT SECTOR ENGAGED', 10, 13, 0

final_s:
	db ' -> WE ARE READY TO GO', 10, 13, 0

times 512 - ( $ - $$ ) db 0
