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
call diskload
jmp 0x2900

jmp $

splashload:
	pushf
	pusha
	push es									;Store extra segment register
	mov dl, [boot_drive]					;Set drive number
	mov dh, 1								;Read 1 sector each time
	mov bx, 0xA000							;Load es through bx
	mov es, bx								;Setup segment register to point video memory
	mov bx, 0								;Reset offset register
	mov ax, splash_sector					;We start reading at sector 18
	splash_l:								;Loop
		call diskloadlba					;Load data from disk
		add bx, 512							;Increment memory pointer
		inc ax								;Increment sector pointer
		cmp ax, splash_sector+splash_len	;We want to read 125 sectors
		jbe splash_l						;Loop
	pop es									;Restore segment register
	popa
	popf
	ret
	splash_sector equ 18
	splash_len equ 125

boot_drive: db 0

%include "diskutils.asm"

;Pad out to whole track (-boot sector)
times (17 * 512) - ($ - $$) db 0
