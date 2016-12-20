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

mov cl, 1
mov ch, 1
call putplayer
mov cl, 1
mov ch, -1
call movplayer

myloop:
mov al, 0						;Get character
mov ah, 0x00					;
int 0x16

;call puthex

;jmp myloop

;mov cl, 1
;mov ch, 0
;call movplayer
;jmp myloop

push ax
cmp al, 'a'
mov cl, -1
mov ch, 0
je ok

cmp al, 'd'
mov cl, 1
mov ch, 0
je ok

cmp al, 'w'
mov cl, 0
mov ch, -1
je ok

cmp al, 's'
mov cl, 0
mov ch, 1
je ok

mov cx, 0


ok:
pop ax

call movplayer

mov cl, 0
mov ch, 32
mov dl, 0
mov dh, 20
call drawmap

jmp myloop
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

;Draws part of map on screenmyloop:
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
	mov [player_pos], cx			;Store player position
	call getmapaddr					;Get address of field where player should be put
	mov byte [bx], 5				;Put 5 (player) on map
	popa
	popf
	ret

;Moves player around the map
;cl - x movement
;ch - y movement
movplayer:
	pushf
	pusha

	mov [movplayer_delta], cx
	mov dx, [player_pos]
	add dl, cl
	add dh, ch
	mov [movplayer_dest], dx

	;Bound check
	cmp dl, 32
	jge movplayer_end
	cmp dh, 20
	jge movplayer_end

	;Get dest field content
	push cx
	mov cx, dx
	call getmapaddr
	pop cx


	;wall
	cmp byte [bx], 1
	je movplayer_end

	;box
	cmp byte [bx], 2
	je movplayer_box
	cmp byte [bx], tile_socketbox
	je movplayer_box
	jmp movplayer_move
	movplayer_box:
		pusha									;Store all registers
		mov cx, [movplayer_delta]				;Get player movement direction
		mov dx, [movplayer_box_position]		;Get box position
		mov ax, dx								;Add another delta to box position to get box destination
		add al, cl								;
		add ah, ch								;
		mov [movplayer_box_dest], ax			;Store box destination

		cmp al, 32
		jge movplayer_box_abort
		cmp ah, 20
		jge movplayer_box_abort





		mov cx, [movplayer_box_dest]			;Get box destination
		call getmapaddr
		mov dl, byte [bx]
		mov [movplayer_box_tile], dl

		cmp byte [bx], tile_socket				;Check if destination is socket
		je movplayer_box_socket					;Jump to socket code
		cmp byte [bx], tile_air
		je movplayer_box_air
		jmp movplayer_box_abort

		movplayer_box_socket:					;Destination tile is socket
		mov byte [bx], tile_socketbox			;Place a socketbox
		jmp movplayer_box_grab					;Proceed to destroy old box

		movplayer_box_air:						;Destination tile is air
		mov byte [bx], tile_box					;Place a box
		jmp movplayer_box_grab


		movplayer_box_grab:
		mov cx, [movplayer_dest]		;Get current box position
		call getmapaddr							;Get current box address to bx

		mov dl, [movplayer_box_tile]
		;cmp dl, tile_socket
		;je movplayer_box_grab_socketbox
		jmp movplayer_box_grab_box

		movplayer_box_grab_socketbox:
		mov byte [bx], tile_socket
		jmp movplayer_box_ok

		movplayer_box_grab_box:
		mov byte [bx], tile_socket
		jmp movplayer_box_ok


		movplayer_box_abort:
		popa
		jmp movplayer_end

		movplayer_box_ok:
		popa
		jmp movplayer_move



	;Check current tile
	movplayer_move:
	mov cx, [player_pos]
	call getmapaddr
	cmp byte [bx], 6
	je movplayer_move_socket
	cmp byte [bx], 2
	jmp movplayer_move_air

	movplayer_move_air:
	mov byte [bx], 0
	jmp movplayer_move_place
	movplayer_move_socket:
	mov byte [bx], 3
	jmp movplayer_move_place

	movplayer_move_place:
	mov [player_pos], dx
	mov cx, dx
	call getmapaddr
	cmp byte [bx], 3
	je movplayer_move_place_socket
	jmp movplayer_move_place_air

	movplayer_move_place_air:
	mov byte [bx], 5
	jmp movplayer_end
	movplayer_move_place_socket:
	mov byte [bx], 6
	jmp movplayer_end

	movplayer_end:
	popa
	popf
	ret
	movplayer_delta: dw 0
	movplayer_box_position:
	movplayer_dest: dw 0
	movplayer_box_dest: dw 0
	movplayer_box_tile: db 0

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

player_pos: dw 0 	;Player x position

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
	db 1, 0, 0, 0, 3, 1, 0, 0, 0, 2, 3, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
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
