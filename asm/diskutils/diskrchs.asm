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
;df - if set errors aren't critical
;return cf - set on error
diskrchs:
	pushf
	pusha
	mov word [diskrchs_cnt], 0						;Clear error counter
	jmp diskrchs_start								;
	diskrchs_reset:									;
		popa										;
		pusha										;
		mov ah, 0									;Reset disk
		int 0x13									;
	diskrchs_start:									;
		popa										;In case disk reset modified registers
		pusha										;
		mov ah, 0x2 								;Sector read
		int 0x13									;Disk interrupt
		jnc diskrchs_end							;If carry flag is not set (no error, quit)
		inc word [diskrchs_cnt]						;Increment error counter
		cmp word [diskrchs_cnt], disk_err_threshold	;Check if error count is below threshold
		jbe diskrchs_reset							;If so, try again
		call diskerr								;Else, call disk error handler
	diskrchs_err:									;Quit wit CF set - error
	popa											;
	popf											;
	stc												;
	ret												;
	diskrchs_end:									;Clean exit - no CF set
	popa
	popf
	clc
	ret
	diskrchs_cnt: dw 0				;Disk error counter

%include "diskutils/diskerr.asm"
%endif
