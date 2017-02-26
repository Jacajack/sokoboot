;Resets chosen disk
;dl - drive number
diskreset:
	pushf
	pusha
	mov ah, 0 						;Reset disk
	int 0x13						;BIOS drive interrupt
	popa
	popf
	ret

;Loads sectors into RAM
;al - sectors amount
;bx - starting address
;cl - starting sector
;ch - cylinder number
;dl - drive number
;dh - head number
diskload:
	pushf
	pusha
	mov ah, 0x2 					;Sector read operation
	int 0x13						;Disk interrupt
	jc diskload_error
	popa
	popf
	ret
	diskload_error:
	mov si, diskload_error_s
	call puts
	jmp $
	diskload_error_s:
		db 10, 13, 'CRITICAL - DISK ERROR', 10, 13, 0

%include "puts.asm"
