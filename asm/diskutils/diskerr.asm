%ifndef DISKUTILS_DISKERR
%define DISKUTILS_DISKERR

;Disk error handler
;dl - disk number
diskerr:
	pushf
	pusha
	call gotext
	mov si, diskerr_mesg	;Load message address into si
	call puts				;Display the message
	mov ah, 1				;Get status of last operation
	int 0x13				;Run interrupt
	mov al, ah				;Display error code
	call puthexb			;
	mov si, diskerr_mesg_nl	;Print new line
	call puts				;
	jmp $					;Endless loop
	popa
	popf
	ret
	diskerr_mesg: db "disk fault - errno: ", 0
	diskerr_mesg_nl: db 10, 13, 0

%include "stdio/puthexb.asm"
%include "stdio/puts.asm"
%include "stdio/gotext.asm"
%endif
