%ifndef DISKUTILS_DISKRESET
%define DISKUTILS_DISKRESET

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

%endif
