%ifndef DISKUTILS_DISKWLBA
%define DISKUTILS_DISKWLBA

;Writes data to disk
;ax - LBA
;dl - drive number
;dh - sector count
;es:bx - data addresses
;df - if set, errors aren't critical
;return cf - set on error
diskwlba:
	pushf
	pusha
	push dx							;Store dx value
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_s				;Divide LBA by sector per track count
	div cx							;
	inc dx							;Increment reminder
	mov [diskwlba_s], dx			;Save reminder as sector number
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_h				;Divide LBA by heads per cylinder count
	div cx							;
	mov [diskwlba_h], dx			;Reminder is head number
	mov [diskwlba_c], ax			;Quotient is cylinder number
	pop dx							;Restore dx
	mov al, dh						;Load sectors amount into al
	mov cl, [diskwlba_s]			;Load CHS
	mov ch, [diskwlba_c]			;
	mov dh, [diskwlba_h]			;
	call diskwchs					;
	jc diskwlba_err					;Exit either normally or with CF set
	diskwlba_end:					;Normal exit
	popa							;
	popf							;
	clc								;
	ret								;
	diskwlba_err:					;Exit with error
	popa							;
	popf							;
	stc								;
	ret								;
	diskwlba_s: dw 0			;Sector number
	diskwlba_h: dw 0			;Head number
	diskwlba_c: dw 0			;Cylinder number

%include "diskutils/diskwchs.asm"
%include "diskutils/diskgeom.asm"
%endif
