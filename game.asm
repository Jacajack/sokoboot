[org 0x700]

;First of all, enter graphics mode
mov al, 'D'
mov ah, 0xe
int 0x10

jmp $

;Plots a single pixel
putpixel:
	;al - color
	;cx - x position
	;dx - y position
	pushf
	pusha
	mov ah, 0xc
	int 0x10
	popa
	popf
	ret

;Draw sprite on screen
drawsprite:
	;bx - sprite
	;cx - x position
	;dx - y position
	pushf
	pusha
	mov [drawsprite_sprite], bx
	mov [drawsprite_x], cx
	mov [drawsprite_y], dx

	mov cx, 0
	drawsprite_l1:
		mov dx, 0
		;TODO

	popa
	popf
	ret
	drawsprite_sprite: dw 0
	drawsprite_x: dw 0
	drawsprite_y: dw 0


playerx: db 0
playery: db 0
map:
	db 0, 0, 0, 0, 0, 0, 0, 1
	db 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0

%include "sprites.asm"
