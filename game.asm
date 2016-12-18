[org 0x700]

;First of all, enter 13h graphics mode
mov al, 0x13
mov ah, 0x0
int 0x10

;TODO HERE:
;Check inputs
;Game logics
;Render

call drawmap

jmp $

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

;Draw sprite on screen
;bx - sprite address
;cx - x position
;dx - y position
drawsprite:
	pushf
	pusha
	mov [drawsprite_x], cx 			;Store offset
	mov [drawsprite_y], dx 			;Store offset
	mov dx, 0 						;Vertical (slower) loop
	drawsprite_l1:					;
		mov cx, 0					;
		drawsprite_l2: 				;Horizontal (faster loop)
			add cx, 2				;Increment horizontal counter
			push cx					;Store counter value
			push dx					;Store counter value
			add cx, [drawsprite_x] 	;Add offset
			add dx, [drawsprite_y] 	;Add offset
			mov ax, [bx] 			;Fetch color
			call putpixel			;Draw 4 pixels
			inc cx					;
			call putpixel			;
			inc dx					;
			call putpixel			;
			dec cx					;
			call putpixel			;
			pop dx					;Restore counter value
			pop cx					;Restore counter valu
			add bx, 1				;Increment pixel counter
			cmp cx, 16				;Horizontal loop boundary
			jne drawsprite_l2		;
		add dx, 2					;Increment vertical counter
		cmp dx, 16					;Vertical loop boundary
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
	mov dx, 0 						;Vertical loop
	drawmap_l1:						;
		mov cx, 0					;
		drawmap_l2: 				;Horizontal loop
			mov bx, dx				;Get row number
			mov ax, 14				;Multiply row number * 10
			mul bl					;
			mov bx, ax				;
			add bx, cx				;Add collumn number
			add bx, map 			;Add tile number to map pointer
			mov bx, [bx]			;Fetch map tile
			mov ax, 64				;Multiply map tile id * 64
			mul bl					;
			mov bx, ax				;
			add bx, sprites			;Add calculated offset to sprites array
			push cx					;Store coutners
			push dx					;
			shl cx, 4				;Multiply counter values * 16
			shl dx, 4				;
			add cx, [drawmap_padx] 	;Add padding
			add dx, [drawmap_pady]	;
			call drawsprite			;Draw sprite
			pop dx					;Restore counters
			pop cx					;
			inc cx					;Increment counter
			cmp cx, 14				;Loop boundary
			jl drawmap_l2			;
		inc dx						;Increment counter
		cmp dx, 12					;Loop boundary
		jl drawmap_l1
	popa
	popf
	ret
	drawmap_padx: db ( 320 - 14 * 16 ) / 2
	drawmap_pady: db ( 200 - 10 * 16 ) / 2

playerx: db 0 	;Player x position
playery: db 0 	;Player y position
map:			;Map data
	db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

%include "sprites.asm"
