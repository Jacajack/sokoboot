%ifndef DISKUTILS_DISKRLBA
%define DISKUTILS_DISKRLBA

;Reads data from disk
;ax - LBA
;dl - drive number
;dh - sector count
;es:bx - data addresses
;df - if set, errors aren't critical
;return cf - set on error
diskrlba:
	pushf
	pusha
	push dx							;Store dx value
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_s				;Divide LBA by sector per track count
	div cx							;
	inc dx							;Increment reminder
	mov [diskrlba_s], dx			;Save reminder as sector number
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_h				;Divide LBA by heads per cylinder count
	div cx							;
	mov [diskrlba_h], dx			;Reminder is head number
	mov [diskrlba_c], ax			;Quotient is cylinder number
	pop dx							;Restore dx
	mov al, dh						;Load sectors amount into al
	mov cl, [diskrlba_s]			;Load CHS
	mov ch, [diskrlba_c]			;
	mov dh, [diskrlba_h]			;
	call diskrchs					;
	jc diskrlba_err					;Exit either normally or with CF set
	diskrlba_end:					;Normal exit
	popa							;
	popf							;
	clc								;
	ret								;
	diskrlba_err:					;Exit with error
	popa							;
	popf							;
	stc								;
	ret								;
	diskrlba_s: dw 0			;Sector number
	diskrlba_h: dw 0			;Head number
	diskrlba_c: dw 0			;Cylinder number

%include "diskutils/diskrchs.asm"
%include "diskutils/diskgeom.asm"
%endif
