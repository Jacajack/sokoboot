[org 0x2900]
[map all sokoban.map]

;Get boot drive number
pop dx
mov [boot_drive], dl

mov ax, 324
call lvlload
test al, al
jz xxx
call gotext
call puthexb
jmp $
xxx:

; mov ax, 5
; mov cx, 0x13
; call getmapaddr
; call debug
; dec cx
; call getmapaddr
; call debug
; jmp $

;First of all, enter 13h graphics mode
mov al, 0x13
mov ah, 0x0
int 0x10

;Setup color palette
call palsetup

;Find player on the map
call findplayer

;Draw whole map for the first time
call drawmap

;mov ax, 0
;mov cx, 0
;call drawtile

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
	mov dl, 0						;
	mov dh, 1						;
	je kbaction_match				;
	cmp al, 'd'						;Player - move right
	mov dl, 2						;
	mov dh, 1						;
	je kbaction_match				;
	cmp al, 'w'						;Player - move up
	mov dl, 1						;
	mov dh, 0						;
	je kbaction_match				;
	cmp al, 's'						;Player - move down
	mov dl, 1						;
	mov dh, 2						;
	je kbaction_match				;
	jmp kbaction_end				;No match
	kbaction_match:					;
	mov ax, [lvldata_playerx]
	mov cx, [lvldata_playery]
	call movplayer					;Move player
	;call findplayer
	call drawstack_draw				;Redraw only necessary tiles
	;call drawmap
	kbaction_end:
	popa
	popf
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

;Draw sprite on screen (still can be optimized)
;bx - sprite address
;cx - x position
;dx - y position
drawsprite:
	pushf
	pusha
	push es
	mov [drawsprite_x], cx 			;Store offset
	mov [drawsprite_y], dx 			;Store offset
	mov ax, 0xA000					;Setup extra segment register
	mov es, ax						;
	mov dx, 0 						;Vertical (slower) loop
	drawsprite_l1:					;
		mov cx, 0					;
		drawsprite_l2: 				;Horizontal (faster loop)
			push cx					;Store counter value
			push dx					;Store counter value
			add cx, [drawsprite_x] 	;Add offset
			add dx, [drawsprite_y] 	;Add offset
			mov ax, [bx] 			;Fetch color
			push bx					;Save source address register
			mov bx, dx				;Calculate offset in video memory
			shl bx, 6				;
			shl dx, 8				;
			add bx, dx				;
			add bx, cx				;
			mov [es:bx], al			;Write directly to video memory
			pop bx					;Restore source address register
			pop dx					;Restore counter value
			pop cx					;Restore counter value
			inc bx					;Increment pixel counter
			inc cx					;Increment horizontal counter
			cmp cx, sprite_width	;Horizontal loop boundary
			jne drawsprite_l2		;
		inc dx						;Increment vertical counter
		cmp dx, sprite_height		;Vertical loop boundary
		jne drawsprite_l1			;
	pop es							;Restore extra segment register
	popa
	popf
	ret
	drawsprite_x: dw 0
	drawsprite_y: dw 0
	sprite_width equ 16
	sprite_height equ 16

;Draws map tile on screen
;ax - x position
;cx - y position
drawtile:
	pushf
	pusha
	push fs					;Setup segment register - we want to access whole 65536 byte long map as one segment
	mov bx, lvldata_map		;
	shr bx, 4				;
	mov fs, bx				;

	push ax
	mov ax, [lvldata_width]
	mul cx
	mov bx, ax
	pop ax
	add bx, ax				;Add collumn number

	push ax
	mov bh, [fs:bx]			;Fetch map tile
	mov bl, 0
	add bx, sprites			;Add calculated offset to sprites array base
	pop ax

	shl ax, 4
	shl cx, 4
	mov dx, cx
	mov cx, ax
	call drawsprite			;Draw sprite
	drawtile_end:
	pop fs
	popa
	popf
	ret

;Draws part of map on screen:
drawmap:
	pushf
	pusha
	mov ax, 0
	drawmap_l1:						;Vertical loop
		mov cx, 0					;Reset horizontal counter
		drawmap_l2: 				;Horizontal loop
			call drawtile			;Draw map tile
			inc cx					;Increment counter
			cmp cx, viewport_h		;Loop boundary
			jl drawmap_l2			;Loop
		inc ax						;Increment counter
		cmp ax, viewport_w			;Loop boundary
		jl drawmap_l1				;Loop
	popa
	popf
	ret

;Draw stack
drawstack_sc: dw 0				;Stack counter
drawstack_bp: times 640 dw 0, 0	;Stack base pointer

;Push map field address to be drawn
;ax - x position
;cx - y position
drawstack_push:
	pushf
	pusha
	mov bx, [drawstack_sc]			;Get stack counter
	shl bx, 2
	mov [drawstack_bp + bx + 0], ax	;Push new coordinate to stack
	mov [drawstack_bp + bx + 2], cx	;Push new coordinate to stack
	inc word [drawstack_sc]		;Update stack pointer
	popa
	popf
	ret

;Draws map tiles pushed with drawstack_push
drawstack_draw:
	pushf
	pusha
	drawstack_draw_l1:				;Main loop
		cmp word [drawstack_sc], 0	;Is stack counter 0 yet?
		je drawstack_draw_end		;If yes - return from loop
		dec word [drawstack_sc]		;Decrement stack pointer
		mov bx, [drawstack_sc]		;Get stack counter value
		shl bx, 2
		mov ax, [drawstack_bp + bx + 0]
		mov cx, [drawstack_bp + bx + 2]
		call drawtile				;Draw tile at coordinates read from stack
		jmp drawstack_draw_l1		;Loop
	drawstack_draw_end:				;
	mov word [drawstack_sc], 0		;Reset stack pointer
	popa
	popf
	ret

;Finds player on map and stores position in lvldata_playerpos
findplayer:
	pushf									;Pusha all registers
	pusha									;
	push fs									;
	mov ax, lvldata_map						;
	shr ax, 4								;
	mov fs, ax								;

;call gotext
	mov ax, 0								;Reset horizontal counter
	findplayer_l1:							;Horizontal loop
		mov cx, 0							;Reset vertical counter
		findplayer_l2:						;Vertical loop
			call getmapaddr					;Get current map address
			mov dl, byte [fs:bx]	;Get current field content
		;	push ax
			;mov al, dl
			;call puthexb
			;pop ax

			cmp dl, tile_player
			je findplayer_found				;If so, jump to match routine
			cmp dl, tile_socketplayer
			je findplayer_found				;If so, jump to match routine

			;call puthexw
			inc cx							;Increment vertical counter
			cmp cx, [lvldata_height]		;Vertical loop limit
			jb findplayer_l2				;Vertical loop jump

		inc ax								;Increment horizontal loop counter
		cmp ax, [lvldata_width]				;Horizontal loop limit
		jb findplayer_l1					;Horizontal loop jump
	jmp findplayer_end						;If no match, go to the end



	findplayer_found:						;Match subroutine
	;call gotext
	;call puthexw
	;jmp $
	mov [lvldata_playerx], ax				;Move counters value into lvldata_playerpos
	mov [lvldata_playery], cx				;Move counters value into lvldata_playerpos
	findplayer_end:							;The end
	;jmp $
	pop fs
	popa									;Pop all registers
	popf
	ret


debug:
	pushf
	pusha
	call gotext

	mov si, debug_nl
	push ax
	mov al, 'a'
	call putc
	pop ax
	call puthexw
	call puts

	mov al, 'b'
	call putc
	mov ax, bx
	call puthexw
	call puts

	mov al, 'c'
	call putc
	mov ax, cx
	call puthexw
	call puts

	mov al, 'd'
	call putc
	mov ax, dx
	call puthexw
	call puts

	popa
	popf
	ret
	debug_nl: db 10, 13, 0


;Moves player around the map
;ax - x position
;cx - y position
;dl - x delta (0-1-2)
;dh - y delta (0-1-2)
movplayer:
	pushf
	pusha

	push ax
	push cx
	push dx
	push dx
	mov dh, 0
	add ax, dx
	pop dx
	mov dl, dh
	mov dh, 0
	add cx, dx
	dec ax
	dec cx
	pop dx
	call movtile
	pop cx
	pop ax
	call movtile

	popa
	popf
	ret


;Moves tiles around the map
;ax - x position
;cx - y position
;dl - x delta (0-1-2)
;dh - y delta (0-1-2)
movtile:
	pushf
	pusha
	push fs
	mov bx, lvldata_map
	shr bx, 4
	mov fs, bx
	mov bx, 0

	;call gotext
	;call puthexw

	;mov dx, 0x0100

	mov [movtile_srcx], ax
	mov [movtile_srcy], cx

	call getmapaddr
	mov bl, [fs:bx]
	;call debug
	mov [movtile_src], bl

	push dx
	mov dh, 0
	add ax, dx
	jc movtile_end
	pop dx

	mov dl, dh
	mov dh, 0
	add cx, dx
	jc movtile_end

	sub cx, 1
	jc movtile_end

	sub ax, 1
	jc movtile_end

	cmp ax, [lvldata_width]
	jae movtile_end
	cmp cx, [lvldata_height]
	jae movtile_end



	mov [movtile_destx], ax
	mov [movtile_desty], cx
	call getmapaddr
	;call debug
	mov bl, [fs:bx]
	mov [movtile_dest], bl


	mov al, [movtile_src]
	mov ah, [movtile_dest]

	;call puthexw

	;call gotext
	;call puthexw

	mov bx, 0
	movtile_l:
		cmp bx, movtile_allowed_cnt * 4
		jae movtile_end

		; push ax
		; ;mov ax, [bx + movtile_allowed]
		; call puthexw
		; mov al, 10
		; call putc
		; pop ax

		cmp ax, [bx + movtile_allowed]
		je movtile_move

		add bx, 4
		jmp movtile_l

	movtile_move:
	mov dx, [bx + movtile_allowed + 2]
	mov ax, [movtile_srcx]
	mov cx, [movtile_srcy]
	call drawstack_push
	call getmapaddr
	mov [fs:bx], byte dl
	mov ax, [movtile_destx]
	mov cx, [movtile_desty]
	call drawstack_push
	call getmapaddr
	mov [fs:bx], dh

	cmp byte [movtile_src], tile_player
	je movtile_update_player
	cmp byte [movtile_src], tile_socketplayer
	je movtile_update_player
	jmp movtile_end

	movtile_update_player:
	mov ax, [movtile_destx]
	mov [lvldata_playerx], ax
	mov ax, [movtile_desty]
	mov [lvldata_playery], ax

	movtile_end:


	pop fs
	popa
	popf
	ret
	movtile_src: db 0
	movtile_dest: db 0
	movtile_srcx: dw 0
	movtile_srcy: dw 0
	movtile_destx: dw 0
	movtile_desty: dw 0

	movtile_allowed:
		db tile_player, tile_socket
			db tile_air, tile_socketplayer
		db tile_player, tile_air
			db tile_air, tile_player
		db tile_socketplayer, tile_air
			db tile_socket, tile_player
		db tile_socketplayer, tile_socket
			db tile_socket, tile_socketplayer
		db tile_box, tile_air
			db tile_air, tile_box
		db tile_box, tile_socket
			db tile_air, tile_socketbox
		db tile_socketbox, tile_air
			db tile_socket, tile_box
		db tile_socketbox, tile_socket
			db tile_socket, tile_socketbox
	movtile_allowed_cnt equ 8


;Return requested map field address
;ax - x position
;cx - y position
;return bx - address
getmapaddr:
	pushf
	pusha
	mov bx, cx						;Insert y position
	push ax
	mov dx, 0
	mov ax, [lvldata_width]
	mul bx
	mov bx, ax
	;jo $
	pop ax
	add bx, ax						;Add x position
	mov [getmapaddr_addr], bx		;Temporarily store address in memory
	popa							;
	popf							;
	mov bx, [getmapaddr_addr]		;Get address back from memory
	ret
	getmapaddr_addr: dw 0

;ax - level LBA address on disk
;return cf - set if bad level
lvlload:
	pushf
	pusha
	push es
	mov [lvlload_lba], ax

	mov bx, ds
	mov es, bx
	mov bx, lvldata
	mov dh, 2
	mov dl, [boot_drive]
	call diskrlba
	jc lvlload_end

	;Magic number check
	mov si, lvlload_magic
	mov di, lvldata_magic
	mov cx, 8
	rep cmpsb
	mov byte [lvlload_error], lvlload_error_magic
	jnz lvlload_end

	;Check level size
	mov ax, [lvldata_width]
	mov cx, [lvldata_height]
	mul cx
	mov byte [lvlload_error], lvlload_error_size
	jo lvlload_end

	;Calculate needed sectors amount
	shr ax, 9
	inc ax
	add ax, [lvlload_lba]
	add ax, 2
	mov [lvlload_endsector], ax
	mov bx, lvldata_map
	shr bx, 4
	mov es, bx
	mov bx, 0
	mov dl, [boot_drive]
	mov dh, 1
	mov ax, [lvlload_lba]
	add ax, 2

	lvlload_loop:
	call diskrlba
	add bx, 512
	inc ax
	cmp ax, [lvlload_endsector]
	jbe lvlload_loop

	mov byte [lvlload_error], lvlload_error_disk
	jc lvlload_end

	mov byte [lvlload_error], lvlload_error_none
	lvlload_end:
	pop es
	popa
	popf
	mov al, [lvlload_error]
	ret
	lvlload_lba: dw 0
	lvlload_error: db 0
	lvlload_magic: db "soko lvl"
	lvlload_endsector: dw 0
	lvlload_error_none equ 0
	lvlload_error_disk equ 1
	lvlload_error_magic equ 2
	lvlload_error_sector equ 3
	lvlload_error_size equ 4

boot_drive: db 0

%include "gfxutils.asm"
%include "diskutils.asm"
%include "stdio.asm"

tile_air equ 0
tile_wall equ 1
tile_box equ 2
tile_socket equ 3
tile_socketbox equ 4
tile_player equ 5
tile_socketplayer equ 6

viewport_w equ 20
viewport_h equ 12

sprites: incbin "../resources/sprites.bin"

;Pad out to full track
times 1 * 18 * 512 - ( $ - $$ ) db 0

;Level data can take up to 72KB (8 tracks)
;Also, make sure that lvldata is located at address divisible by 16
times 16 - ( ( $ - $$ ) % 16 ) db 0
lvldata:
	lvldata_magic: db "soko lvl"
	lvldata_id: dw 0
	lvldata_name: times 80 db 0
	lvldata_desc: times 320 db 0
	lvldata_playerx: dw 0
	lvldata_playery: dw 0
	lvldata_width: dw 0
	lvldata_height: dw 0
	lvldata_camx: dw 0
	lvldata_camy: dw 0
	lvldata_flags: dw 0, 0
	lvldata_next: dw 0
	lvldata_reserved: times 1024 - ( $ - lvldata ) db 0
	lvldata_map: times 65536 - ( $ - lvldata ) db 1

;Pad out to 9 tracks
times 9 * 18 * 512 - ( $ - $$ ) db 0
