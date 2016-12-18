;Resets chosen disk
diskreset:
	;dl - drive number
	pushf
	pusha
	mov ah, 0 	;Reset disk
	int 0x13	;BIOS drive interrupt
	popa
	popf
	ret

;Loads sectors into RAM
diskload:
	;al - sectors amount
	;dl - drive number
	;bx - starting address
	;cl - starting sector
	pushf
	pusha
	mov ah, 0x2 ;Sector read operation
	mov ch, 0 	;Cylinder number
	mov dh, 0	;Head number
	int 0x13	;Disk interrupt
	jc diskload_error
	popa
	popf
	ret
	diskload_error:
	mov si, diskload_error_s
	call puts
	jmp $
	diskload_error_s:
		db 10, 13, '[DISK ERROR]', 10, 13, 0
