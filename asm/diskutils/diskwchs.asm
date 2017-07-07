%ifndef DISKUTILS_DISKWCHS
%define DISKUTILS_DISKWCHS

;Writes data to disk
;al - sector count
;es:bx - data address
;cl - sector number
;ch - cylinder number
;dl - drive number
;dh - head number
;es:bx - data addresses
diskwchs:
	pushf
	pusha
	jmp diskwchs_start
	diskwchs_reset:
		popa
		pusha
		mov ah, 0					;Reset disk
		int 0x13					;
	diskwchs_start:
		popa						;In case disk reset modified registers
		pusha						;
		mov ah, 0x3 				;Sector write
		int 0x13					;Disk interrupt
		jnc diskwchs_end			;If carry flag is not set (no error, quit)
		mov cx, [diskwchs_cnt]		;Increment error counter
		inc cx						;
		mov [diskwchs_cnt], cx		;
		cmp cx, disk_err_threshold	;Check if error count is below threshold
		jle diskwchs_reset			;If so, try again
		call diskerr				;Else, call disk error handler
	diskwchs_end:					;
	mov cx, 0						;Clear error counter
	mov [diskwchs_cnt], cx			;
	popa
	popf
	ret
	diskwchs_cnt: dw 0				;Disk error counter

%include "diskutils/diskerr.asm"
%endif
