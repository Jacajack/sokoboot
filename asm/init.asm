[org 0x500]

;Get boot drive ID passed by bootloader
mov [boot_drive], dl

;Enter 13h graphics mode to draw splash screen
mov al, 0x13
mov ah, 0x0
int 0x10

;Load splash screen
call splashload

;Wait for a keypress
mov al, 0x00
mov ah, 0x00
int 0x16


;SOME MENU HERE
;FOR NOW, JUST LOAD THE GAME
mov dh, 1
mov ch, 4
mov cl, 1
mov al, 18
mov dl, [boot_drive]
mov bx, 0x2900
call diskrchs
jmp 0x2900

jmp $

splashload:
	pushf
	pusha
	push ds
	push es
	mov ax, splash_sector			;Sector counter
	mov cx, 0						;Address counter
	splash_l:
		mov dl, [boot_drive]		;Set drive number
		mov dh, 1					;Read 1 sector each time
		mov bx, splash_memseg		;Setup buffer segment
		mov es, bx					;
		mov bx, splash_memaddr		;Buffer address
		call diskrlba				;Load data from disk
		mov dx, splash_memseg		;Setup source segment (buffer)
		mov ds, dx					;
		mov si, splash_memaddr		;Setup source address
		mov dx, 0xA000				;Setup destination segment (video memory)
		mov es, dx					;
		mov di, cx					;Setup destination address
		push cx						;Store address counter value
		mov cx, 512					;Copy 512b
		cld							;Clear direction flag (growing addresses)
		rep movsb					;Repeat byte copy operation
		pop cx						;Restore address counter
		add cx, 512					;Increment address counter
		inc ax						;Increment sector counter
		cmp ax, splash_sector+splash_len	;Check loop condition
		jbe splash_l				;Loop
	pop es
	pop ds
	popa
	popf
	ret
	splash_sector equ 18
	splash_len equ 125
	splash_memaddr equ 0xf000
	splash_memseg equ 0x5000

boot_drive: db 0

%include "diskutils.asm"

;Pad out to whole track (-boot sector)
times (17 * 512) - ($ - $$) db 0
