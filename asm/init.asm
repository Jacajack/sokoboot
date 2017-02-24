[org 0x500]

;Get boot drive ID passed by bootloader
mov [boot_drive], dl

;Enter 13h graphics mode to draw splash screen
mov al, 0x13
mov ah, 0x0
int 0x10


splashloader:
	splashloader_getsec:
		mov dl, [boot_drive]	;Set drive number
		call diskreset
		mov cl, [splashloader_sector]
		mov dh, [splashloader_head]
		mov ch, [splashloader_track]
		mov al, 1
		mov bx, splash_dump	;Set destination
		call diskload

		cmp cl, 18
		jge splashload_sector_roll
		inc cl
		jmp splashloader_sector_next
		splashloader_sector_roll:
		mov cl, 1
		cmp dh, 1
		je splashload_head_roll

		splashloader_sector_next:



mov bx, 0
l1:
	push bx
	mov cx, bx
	mov ax, [bx+splash_dump]
	mov dx, 5
	call putpixel
	pop bx
	inc bx
	cmp bx, 320
	jl l1



jmp $

splashloader_sector: db 1
splashloader_head: db 1
splashloader_track: db 0

;Plots a single pixel
;al - color
;cx - x position
;cy - y position
putpixel:
	pushf
	pusha
	mov ah, 0xc						;Put pixel function
	int 0x10						;Graphics interrupt call
	popa
	popf
	ret


boot_drive: db 0
splash_dump: times 512 db 0

%include "diskutils.asm"

;Pad out to whole track (-boot sector)
times (17 * 512) - ($ - $$) db 0
