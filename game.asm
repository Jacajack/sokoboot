[org 0x700]

;DEBUG
;asd:
;call kbget
;call kbhandle
;call puthex
;mov al, ah
;call puthex
;jmp asd
;dsa:

;First of all, enter 13h graphics mode
mov al, 0x13
mov ah, 0x0
int 0x10

;TODO HERE:
;Check inputs
;Game logics
;Render

mov cl, 2
mov ch, 1
call putplayer

mov cl, 0
mov ch, 32
mov dl, 0
mov dh, 20
call drawmap

jmp $

;Fetch keystroke
;return al - ASCII code
;return ah - BIOS keycode
kbget:
	mov al, 0						;Check if there's any character in buffer
	mov ah, 0x01					;
	int 0x16						;
	jnz kbget_abort					;If not, abort
	mov al, 0						;Get character
	mov ah, 0x00					;
	int 0x16						;
	ret
	kbget_abort:
	mov ax, 0
	ret

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
			;inc cx					;Increment horizontal counter
			push cx					;Store counter value
			push dx					;Store counter value
			add cx, [drawsprite_x] 	;Add offset
			add dx, [drawsprite_y] 	;Add offset
			mov ax, [bx] 			;Fetch color
			call putpixel			;Draw pixel
			pop dx					;Restore counter value
			pop cx					;Restore counter value
			inc bx					;Increment pixel counter
			inc cx					;Increment horizontal counter
			cmp cx, 10				;Horizontal loop boundary
			jne drawsprite_l2		;
		inc dx						;Increment vertical counter
		cmp dx, 10					;Vertical loop boundary
		jne drawsprite_l1
	popa
	popf
	ret
	drawsprite_x: dw 0
	drawsprite_y: dw 0

;Draws part of map on screen
;cl - start x position
;ch - width
;dl - start y position
;dh - height
drawmap:
	pushf
	pusha
	mov [drawmap_xstart], cl
	add ch, cl
	add dh, dl
	drawmap_l1:						;Vertical loop
		mov cl, [drawmap_xstart]	;Get starting x position
		drawmap_l2: 				;Horizontal loop
			mov bx, 0				;Clear pointer
			mov bl, dl				;Get row number
			shl bx, 5				;Multiply row number * 32
			push cx					;Store counter
			mov ch, 0				;Get only lower half
			add bx, cx				;Add collumn number
			pop cx					;Restore counter
			add bx, map 			;Add tile number to map pointer
			mov bx, [bx]			;Fetch map tile
			mov ax, 100				;Multiply map tile id * 100
			mul bl					;
			mov bx, ax				;
			add bx, sprites			;Add calculated offset to sprites array
			push cx					;Store coutners
			push dx					;
			mov ch, 0				;Get only lower half
			mov dh, 0				;
			mov al, 10				;Multiply counters * 10
			mul cl					;
			mov cx, ax				;
			mov al, 10				;
			mul dl					;
			mov dx, ax				;
			call drawsprite			;Draw sprite
			pop dx					;Restore counters
			pop cx					;
			inc cl					;Increment counter
			cmp cl, ch				;Loop boundary
			jl drawmap_l2			;
		inc dl						;Increment counter
		cmp dl, dh					;Loop boundary
		jl drawmap_l1
	popa
	popf
	ret
	drawmap_xstart: db 0

;Inserts player on map
;cl - x position
;ch - y position
putplayer:
	pushf
	pusha
	mov [player_x], cl				;Store player position
	mov [player_y], ch				;
	call getmapaddr					;Get address of field where player should be put
	mov byte [bx], 5				;Put 5 (player) on map
	popa
	popf
	ret


;Return requested map field address
;cl - x position
;ch - y position
;return bx - address
getmapaddr:
	pushf
	pusha
	mov bx, 0						;Clear address register
	mov bl, ch						;Insert y position
	shl bx, 5						;Multiply y position * 32
	mov ch, 0						;
	add bx, cx						;Add x position
	add bx, map						;Add map base address
	mov [getmapaddr_addr], bx		;Temporarily store address in memory
	popa							;
	popf							;
	mov bx, [getmapaddr_addr]		;Get address back from memory
	ret
	getmapaddr_addr: dw 0

player_x: db 0 	;Player x position
player_y: db 0 	;Player y position

map:			;Map data
	db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

%include "sprites.asm"
%include "puthex.asm"
