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

;ax - LBA
;dl - drive number
;dh - sector count
;es:bx - starting addresses
diskloadlba:
	pushf
	pusha
	push dx							;Store dx value
	mov dx, 0						;Clear reminder register
	mov cx, n_s						;Divide LBA by sector per track count
	div cx							;
	inc dx							;Increment reminder
	mov [diskloadlba_s], dx			;Save reminder as sector number
	mov dx, 0						;Clear reminder register
	mov cx, n_h						;Divide LBA by heads per cylinder count
	div cx							;
	mov [diskloadlba_h], dx			;Reminder is head number
	mov [diskloadlba_c], ax			;Quotient is cylinder number
	pop dx							;Restore dx
	mov al, dh						;Load sectors amount into al
	mov cl, [diskloadlba_s]			;Load CHS
	mov ch, [diskloadlba_c]			;
	mov dh, [diskloadlba_h]			;
	mov ah, 0x2 					;Sector read operation
	int 0x13						;Disk interrupt
	jc diskload_error				;Handle disk error
	popa
	popf
	ret
	diskloadlba_s: dw 0
	diskloadlba_h: dw 0
	diskloadlba_c: dw 0
	n_s equ 18
	n_h equ 2

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
