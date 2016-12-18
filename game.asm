[org 0x700]

;First of all, enter 13h graphics mode
mov al, 0x13
mov ah, 0x0
int 0x10

;TEST
;mov bx, sprite_box
;mov cx, 10
;mov dx, 10
call drawmap

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
	mov [drawsprite_x], cx ;Store offset
	mov [drawsprite_y], dx ;Store offset
	mov dx, 0 ;Vertical (slower) loop
	drawsprite_l1:
		mov cx, 0
		drawsprite_l2: 		;Horizontal (faster loop)
			add cx, 1		;Increment horizontal counter
			mov ax, [bx] 	;Increment sprite pointer
			push cx			;Store counter value
			push dx			;Store counter value
			add cx, [drawsprite_x] ;Add offset
			add dx, [drawsprite_y] ;Add offset
			call putpixel 	;Draw pixel
			pop dx			;Restore counter value
			pop cx			;Restore counter value
			add bx, 1		;Increment pixel counter
			cmp cx, 8		;Horizontal loop boundary
			jne drawsprite_l2
		add dx, 1			;Increment vertical counter
		cmp dx, 8			;Vertical loop boundary
		jne drawsprite_l1
	popa
	popf
	ret
	drawsprite_x: dw 0
	drawsprite_y: dw 0

;Draws whole map on screen
drawmap:
	pushf
	pusha
	mov dx, 0 	;Vertical loop
	drawmap_l1:
		mov cx, 0
		drawmap_l2: ;Horizontal loop
			mov bx, dx		;Get row number
			mov ax, 10		;Multiply row number * 10
			mul bl			;
			mov bx, ax		;
			add bx, cx		;Add collumn number
			add bx, map 	;Add tile number to map pointer
			mov bx, [bx]	;Fetch map tile
			mov ax, 64		;Multiply map tile id * 64
			mul bl			;
			mov bx, ax		;
			add bx, sprites	;Add calculated offset to sprites array
			push cx			;Store coutners
			push dx
			shl cx, 3		;Multiply counter values * 8
			shl dx, 3
			call drawsprite
			mov al, 7
			pop dx			;Restore counters
			pop cx
			inc cx
			cmp cx, 10
			jl drawmap_l2
		inc dx
		cmp dx, 10
		jl drawmap_l1
	popa
	popf
	ret


playerx: db 0
playery: db 0
map:
	db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 2, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 3, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

%include "sprites.asm"
