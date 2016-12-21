[org 0x700]

;First of all, enter 13h graphics mode
mov al, 0x13
mov ah, 0x0
int 0x10

;Find player on the map
call findplayer

;Draw map for the first time
mov cl, 0
mov ch, 32
mov dl, 0
mov dh, 20
call drawmap

;Gameloop
gameloop:
call getc
call kbaction
jmp gameloop
jmp $

;Manage ingame key actions
;ax - ASCII code and scancode
kbaction:
	pushf
	pusha
	cmp al, 'a'						;Player - move left
	mov cl, -1						;
	mov ch, 0						;
	je kbaction_match				;
	cmp al, 'd'						;Player - move right
	mov cl, 1						;
	mov ch, 0						;
	je kbaction_match				;
	cmp al, 'w'						;Player - move up
	mov cl, 0						;
	mov ch, -1						;
	je kbaction_match				;
	cmp al, 's'						;Player - move down
	mov cl, 0						;
	mov ch, 1						;
	je kbaction_match
	kbaction_match:
	call movplayer
	mov cl, 0
	mov ch, 32
	mov dl, 0
	mov dh, 20
	call drawmap
	popa
	popf
	ret

;Fetch keystroke (wait)
;return al - ASCII code
;return ah - BIOS scancode
getc:
	pushf							;Push registers
	pusha							;
	mov al, 0x00					;Get character
	mov ah, 0x00					;
	int 0x16						;Call interrupt
	mov [getc_key], ax				;Store key in memory
	popa							;Pop registers
	popf							;
	mov ax, [getc_key]				;Get key into register
	ret
	getc_key: dw 0

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

;Finds player on map and stores position in player_pos
findplayer:
	pushf									;Pusha all registers
	pusha									;
	mov cl, 0								;Reset horizontal counter
	findplayer_l1:							;Horizontal loop
		mov ch, 0							;Reset vertical counter
		findplayer_l2:						;Vertical loop
			call getmapaddr					;Get current map address
			mov al, byte [bx]				;Get current field content
			cmp al, tile_player				;Is the field player
			je findplayer_found				;If so, jump to match routine
			cmp al, tile_socketplayer		;Is the field socketplayer
			je findplayer_found				;If so, jump to match routine
			inc ch							;Increment vertical counter
			cmp ch, 20						;Vertical loop limit
			jle findplayer_l2				;Vertical loop jump
		inc cl								;Increment horizontal loop counter
		cmp cl, 32							;Horizontal loop limit
		jle findplayer_l1					;Horizontal loop jump
	jmp findplayer_end						;If no match, go to the end
	findplayer_found:						;Match subroutine
	mov [player_pos], cx					;Move counters value into player_pos
	findplayer_end:							;The end
	popa									;Pop all registers
	popf
	ret

;Moves player around the map
;cl - x movement
;ch - y movement
movplayer:
	pushf
	pusha
	mov [movplayer_delta], cx					;Store delta
	mov dx, [player_pos]						;Calculate destination
	add dl, cl									;
	add dh, ch									;
	mov [movplayer_dest], dx					;Store destination (dx)
	cmp dl, 32									;Check destination bounds
	jge movplayer_end							;
	cmp dl, 0									;
	jl movplayer_end							;
	cmp dh, 20									;
	jge movplayer_end							;
	cmp dh, 0									;
	jl movplayer_end							;

	push cx										;Get player destination field address
	mov cx, dx									;
	call getmapaddr								;
	pop cx										;

	cmp byte [bx], tile_wall					;Check if destination is a wall
	je movplayer_end							;If so, do not allow move
	cmp byte [bx], tile_box						;Check if destination is a box
	je movplayer_box							;If so, move box first
	cmp byte [bx], tile_socketbox				;Check if destination is a socketbox
	je movplayer_box							;If so, move box first
	jmp movplayer_move

	movplayer_box:								;The box moving routine - Ha, ha, charade you aaareee!
		pusha									;Store all registers
		mov cx, [movplayer_delta]				;Get player movement direction
		mov dx, [movplayer_box_position]		;Get box position
		mov ax, dx								;Add delta to box position to get box destination
		add al, cl								;
		add ah, ch								;
		mov [movplayer_box_dest], ax			;Store box destination
		cmp al, 32								;Check box destination bounds
		jge movplayer_box_abort					;If it exceeds bounds, abort
		cmp al, 0								;
		jl movplayer_box_abort					;
		cmp ah, 20								;
		jge movplayer_box_abort					;
		cmp ah, 0								;
		jl movplayer_box_abort					;

		mov cx, [movplayer_box_dest]			;Get box destination field address
		call getmapaddr							;
		cmp byte [bx], tile_socket				;Check if destination is a socket
		je movplayer_box_socket					;If so, jump to socketbox placing routine
		cmp byte [bx], tile_air					;Check if destination is a wall
		je movplayer_box_air					;If so, jump to box placing routine
		jmp movplayer_box_abort					;If destination isn't one of these, abort move
		movplayer_box_socket:					;Destination tile is socket
		mov byte [bx], tile_socketbox			;Place a socketbox
		jmp movplayer_box_grab					;Proceed to destroy old box
		movplayer_box_air:						;Destination tile is air
		mov byte [bx], tile_box					;Place a box
		jmp movplayer_box_grab					;Proceed to destroy old box

		movplayer_box_grab:						;Replace old box with something different
		mov cx, [movplayer_box_position]		;Get current box position
		call getmapaddr							;Get current box field address
		mov dl, byte [bx]						;Check what current box looks like
		cmp dl, tile_socketbox					;If it's a socketbox, leave a socket
		je movplayer_box_leave_socket			;
		jmp movplayer_box_leave_air				;Otherwise, leave air
		movplayer_box_leave_socket:				;Leave socket
		mov byte [bx], tile_socket				;Place socket on old box position
		jmp movplayer_box_ok					;Box movement is successfull
		movplayer_box_leave_air:				;Leave air
		mov byte [bx], tile_air					;Place air on old box position
		jmp movplayer_box_ok					;Box movement is successfull
		movplayer_box_abort:					;Movement insuccessfull
		popa									;Restore all registers
		jmp movplayer_end						;Jump to the end of player movement routine
		movplayer_box_ok:						;Movement successfull
		popa									;Restore all registers
		jmp movplayer_move						;Return to player movement routine

	movplayer_move:								;Check how plauer look right now
	mov cx, [player_pos]						;Get player position
	call getmapaddr								;Get current player field address
	cmp byte [bx], tile_socketplayer			;If player stands on socket, call socketplayer move routine
	je movplayer_move_socket					;
	jmp movplayer_move_air						;Else, call normal player move routine
	movplayer_move_air:							;Player stands on normal field
	mov byte [bx], tile_air						;Replace player with air
	jmp movplayer_move_place					;Go to place routine
	movplayer_move_socket:						;Player stands on socket
	mov byte [bx], tile_socket					;Replace player with socket
	jmp movplayer_move_place					;Go to place routine

	movplayer_move_place:						;Place a new player tile on destination field
	mov [player_pos], dx						;Update player position
	mov cx, dx									;
	call getmapaddr								;Get destination field address
	cmp byte [bx], tile_socket					;If destination tile is socket
	je movplayer_move_place_socket				;Place a socketplayer
	jmp movplayer_move_place_air				;Else place a normal player
	movplayer_move_place_air:					;Place air
	mov byte [bx], tile_player					;
	jmp movplayer_end							;Go to the end of movement routine
	movplayer_move_place_socket:				;Place socketplayer
	mov byte [bx], tile_socketplayer			;
	jmp movplayer_end							;Go to the end of movement routine
	movplayer_end:								;The end
	popa
	popf
	ret
	movplayer_delta: dw 0						;The requested delta
	movplayer_box_position:						;Current box position
	movplayer_dest: dw 0						;Player destination
	movplayer_box_dest: dw 0					;Box destination

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
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 5, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 2, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 1, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 3, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 4, 2, 2, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

%include "sprites.asm"
%include "puthex.asm"

;Pad out to 16 sectors
times (16 * 512) - ($ - $$) db 0
