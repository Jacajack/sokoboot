[org 0x500]

;Get boot drive ID passed by bootloader
mov [boot_drive], dl

;Enter 13h graphics mode to draw splash screen
mov al, 0x13
mov ah, 0x0
int 0x10

;Load splash screen
pusha
push es
mov bx, 0xA000
mov es, bx
mov al, 125
mov bx, 0
mov cl, 1
mov ch, 0
mov dh, 1
mov dl, [boot_drive]
call diskload
pop es
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
