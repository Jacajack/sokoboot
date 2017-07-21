%ifndef STDIO_GETS
%define STDIO_GETS

;Reads string typed on keyboard into buffer pointed by si
;User can quit by pressing return key
;Terminating 0 byte is automatically added
;Output string doesn't containg CRLF
;si - buffer pointer
;di - buffer end
;return ax - bytes read (including NUL)
gets:
	pushf
	pusha
	mov [gets_buf], si				;Store starting address
	dec di							;Decrement di (we need space for NUL)
	cmp si, di						;Compare starting and ending address
	jae gets_addnul					;If begining address exceeds or is equal to end - quit
	gets_l:							;Main loop
		mov ax, 0					;Read key from keyboard
		int 0x16					;
		cmp al, 08					;If key is backspace, execute special handler
		je gets_bp					;
		cmp al, 27					;Quit on CR, LF
		je gets_skipchr				;
		cmp al, 10					;
		je gets_addnul				;
		cmp al, 13					;
		je gets_addnul				;
		cmp byte [gets_digits], 0	;Depending on 'digits' flag, accepts only numbers
		je gets_skipdigitsck		;
		mov bx, ax					;
		sub al, '0'					;
		jc gets_skipchr				;
		cmp al, 9					;
		ja gets_skipchr				;
		mov ax, bx					;
		gets_skipdigitsck:			;
		cmp al, 9					;Skip tabs
		je gets_skipchr				;
		cmp si, di					;Check buffer bounds
		jae gets_skipchr			;
		mov ah, 0x0E				;Echo out typed in character
		int 0x10					;
		mov [si], al				;Store character in the buffer
		inc si						;Increment the counter
		gets_skipchr:				;
		jmp gets_l					;Loop
		gets_bp:					;Backspace handler
		cmp si, [gets_buf]			;Check if we can go backwards
		jbe gets_l					;If no, loop again
		dec si						;Else, decrement buffer pointer
		mov ah, 0x0E				;Print out
		mov al, 0x08				;Backspace
		int 0x10					;
		mov al, 0x20				;Space
		int 0x10					;
		mov al, 0x08				;Backspace again
		int 0x10					;
		jmp gets_l					;Loop again
	gets_addnul:					;
	mov byte [si], 0				;Add terminating NUL
	mov [gets_last], si				;Store end address
	gets_end:						;
	popa							;
	mov ax, [gets_last]				;Get address of last byte written
	sub ax, [gets_buf]				;Substract start address from it
	popf
	ret
	gets_buf: dw 0
	gets_last: dw 0
	gets_digits: db 0

%endif
