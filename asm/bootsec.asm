[bits 16]
[org 0x7c00]

;Store boot drive
mov [boot_drive], dl

;Stack init
mov bp, 0xffff
mov sp, bp

;Load first track
mov dl, [boot_drive]	;Set drive number
call diskreset
mov al, 17				;Sector count = 17
mov cl, 2				;First sector = 2
mov ch, 0				;Track = 0
mov dh, 0				;Head = 0
mov bx, 0x500			;Set destination
call diskload

;Boot drive ID is left behind in dl
mov dl, [boot_drive]

;Jump to loaded instructions
jmp 0x500
jmp $

boot_drive: db 0

%include "diskutils.asm"

;Padding and magic number
times 510 - ( $ - $$ ) db 0
dw 0xaa55
