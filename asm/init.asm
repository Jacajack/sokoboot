[org 0x500]

;Get boot drive ID passed by bootloader
mov [boot_drive], dl

;Enter 13h graphics mode to draw splash screen
mov al, 0x13
mov ah, 0x0
int 0x10

;Load splash screen
pusha
push es					;Store extra segment register
mov bx, 0xA000			;Load es through bx
mov es, bx				;
mov al, 125				;We're going to read 125 sectors (320x240/512)
mov bx, 0				;Reset memory pointer
mov ch, 0				;Cylinder - 0
mov dh, 1				;Head - 1
mov cl, 1				;Sector - 1
mov dl, [boot_drive]	;Set drive number
call diskload			;Load data from disk
pop es					;Restore segment register	
popa

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

boot_drive: db 0

%include "diskutils.asm"

;Pad out to whole track (-boot sector)
times (17 * 512) - ($ - $$) db 0
