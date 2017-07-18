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
;df - if set, errors aren't critical
;return cf - set on error
diskwchs:
	pushf
	pusha
	mov word [diskwchs_cnt], 0						;Clear error counter
	jmp diskwchs_start								;
	diskwchs_reset:									;
		popa										;
		pusha										;
		mov ah, 0									;Reset disk
		int 0x13									;
	diskwchs_start:									;
		popa										;In case disk reset modified registers
		pusha										;
		mov ah, 0x3 								;Sector write
		int 0x13									;Disk interrupt
		jnc diskwchs_end							;If carry flag is not set (no error, quit)
		inc word [diskwchs_cnt]						;
		cmp word [diskwchs_cnt], disk_err_threshold	;Check if error count is below threshold
		jbe diskwchs_reset							;If so, try again
		call diskerr								;Else, call disk error handler
	diskwchs_err:									;Quit with CF set - error
	popa											;
	popf											;
	stc												;
	ret												;
	diskwchs_end:									;Clean exit - no CF set
	popa
	popf
	clc
	ret
	diskwchs_cnt: dw 0				;Disk error counter

%include "diskutils/diskerr.asm"
%endif
