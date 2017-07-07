%ifndef DISKUTILS_DISKRCHS
%define DISKUTILS_DISKRCHS

;Reads data from disk
;al - sector count
;es:bx - data address
;cl - sector number
;ch - cylinder number
;dl - drive number
;dh - head number
;es:bx - data addresses
diskrchs:
	pushf
	pusha
	jmp diskrchs_start
	diskrchs_reset:
		popa
		pusha
		mov ah, 0					;Reset disk
		int 0x13					;
	diskrchs_start:
		popa						;In case disk reset modified registers
		pusha						;
		mov ah, 0x2 				;Sector read
		int 0x13					;Disk interrupt
		jnc diskrchs_end			;If carry flag is not set (no error, quit)
		mov cx, [diskrchs_cnt]		;Increment error counter
		inc cx						;
		mov [diskrchs_cnt], cx		;
		cmp cx, disk_err_threshold	;Check if error count is below threshold
		jle diskrchs_reset			;If so, try again
		call diskerr				;Else, call disk error handler
	diskrchs_end:					;
	mov cx, 0						;Clear error counter
	mov [diskrchs_cnt], cx			;
	popa
	popf
	ret
	diskrchs_cnt: dw 0				;Disk error counter

%include "diskutils/diskerr.asm"
%endif
