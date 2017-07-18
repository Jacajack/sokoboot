[org 0x2900]
[map all sokoban.map]

;Get boot drive number
pop dx
mov [boot_drive], dl

;Move stack to upper parts of the memory - normally it would collide with loaded level data
mov dx, 0x8fc0
mov ss, dx
mov bp, 0xffff
mov sp, bp

;Load level (ugly!)
lvlprompt:
	call gotext
	call cls
	mov cx, 80
	mov al, '-'
	call repchr
	mov si, mesg_levelnum_prompt
	call puts
	mov si, lvlprompt_buf
	mov di, lvlprompt_buf + 32
	call gets
	call atoi
	jc lvlprompt
	mov cx, ax
	call lvlinfoload
	test al, al
	jnz lvlbad
	mov ax, cx
	call lvldataload
	test al, al
	jnz lvlbad
	jmp lvlok
	lvlbad:
	mov si, mesg_lvlerr
	call puts
	call puthexb
	mov si, mesg_keyretry
	call puts
	call getc
	jmp lvlprompt
mesg_levelnum_prompt: db "Please specify level location on disk: ", 13, 10, "-> ", 0
mesg_lvlerr: db  13, 10, "Error: ", 0
mesg_keyretry: db 13, 10, "Press any key to retry", 13, 10, 0
lvlprompt_buf: times 32 db 0
lvlok:

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
	mov bx, 0									;Clear counter
	kbaction_ascii_search:						;
		cmp bx, kbaction_ascii_count * 4		;Compare with limit
		jae kbaction_ascii_done					;Quit when exceeded
		cmp [kbaction_ascii + bx], al			;Check if current ascci code matched the one from list
		jne kbaction_ascii_search_bad			;If not, continue
		mov dx, [kbaction_ascii + bx + 2]		;Get address of function that should be called
		call dx									;Call the keypress function
		kbaction_ascii_search_bad:				;
		add bx, 4								;Increment counter (one entry has 3b)
		jmp kbaction_ascii_search				;Loop
	kbaction_ascii_done:						;
	mov bx, 0									;Clear counter
	kbaction_scancode_search:					;
		cmp bx, kbaction_scancode_count * 4		;Compare with limit
		jae kbaction_scancode_done				;Quit when exceeded
		cmp [kbaction_scancode + bx], ah		;Check if current scan code matched the one from list
		jne kbaction_scancode_search_bad		;If not, continue
		mov dx, [kbaction_scancode + bx + 2]	;Get address of function that should be called
		call dx									;Call the keypress function
		kbaction_scancode_search_bad:			;
		add bx, 4								;Increment counter (one entry has 3b)
		jmp kbaction_scancode_search			;Loop
	kbaction_scancode_done:
	kbaction_end:
	popa
	popf
	ret
	kbaction_ascii: ;The array of supported keys
		dw 'a', kbaction_player_movel
		dw 'd', kbaction_player_mover
		dw 'w', kbaction_player_moveu
		dw 's', kbaction_player_moved
		dw 'A', kbaction_player_movel
		dw 'D', kbaction_player_mover
		dw 'W', kbaction_player_moveu
		dw 'S', kbaction_player_moved
		dw 0x1b, kbaction_reload_level
		kbaction_ascii_count equ 9
	kbaction_scancode: ;And some additional scancodes list
		dw 0x4b, kbaction_player_movel
		dw 0x4d, kbaction_player_mover
		dw 0x48, kbaction_player_moveu
		dw 0x50, kbaction_player_moved
		kbaction_scancode_count equ 4

%include "keyactions.asm"

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
;ax - x tile position
;cx - y tile position
drawtile:
	pushf
	pusha
	push fs					;Setup segment register - we want to access whole 65536 byte long map as one segment
	mov bx, [lvldata_camx]	;Load camera position into bx and dx
	mov dx, [lvldata_camy]	;
	cmp ax, bx				;Compare tile x position with camera (left)
	jb drawtile_end			;Abort when below
	cmp cx, dx				;Compare tile y position with camera (up)
	jb drawtile_end			;Abort when below
	add bx, viewport_width	;Add viewport dimensions to camera location
	add dx, viewport_height	;
	cmp ax, bx				;Compare tile x position with viewport boundary (right)
	jae drawtile_end		;Abort when exceeds
	cmp cx, dx				;Compare tile y position with viewport boundary (down)
	jae drawtile_end		;Abort when exceeds
	mov bx, lvldata_map		;
	shr bx, 4				;
	mov fs, bx				;
	push ax					;Store ax (will be used for mul)
	mov ax, [lvldata_width]	;Multiply level width with y position
	mul cx					;
	mov bx, ax				;Move multiplication result to bx
	pop ax					;Restore x position
	add bx, ax				;Add collumn number
	mov bh, [fs:bx]			;Fetch map tile (to upper higher part)
	mov bl, 0				;This is used insted of multiplication with 256
	add bx, sprites			;Add calculated offset to sprites array base
	sub ax, [lvldata_camx]
	sub cx, [lvldata_camy]
	shl ax, 4				;Multiply coordinates with 16 to get sprite position
	shl cx, 4				;
	mov dx, cx				;Get sprite position to other registers (needs fix)
	mov cx, ax				;
	call drawsprite			;Draw sprite
	drawtile_end:
	pop fs
	popa
	popf
	ret

;Draw visible part of map on screen
drawmap:
	pushf
	pusha
	mov ax, [lvldata_camx]			;Get camera x
	mov bx, ax						;
	add bx, viewport_width			;And add viewport width to it
	mov cx, [lvldata_camy]			;Get camera y
	mov dx, cx						;
	add dx, viewport_height			;And add viewport height to it
	drawmap_l1:						;Vertical loop
		mov cx, [lvldata_camy]		;Reset horizontal counter
		drawmap_l2: 				;Horizontal loop
			call drawtile			;Draw map tile
			inc cx					;Increment counter
			cmp cx, dx				;Loop boundary
			jl drawmap_l2			;Loop
		inc ax						;Increment counter
		cmp ax, bx					;Loop boundary
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
	shl bx, 2						;Multiply the counter with 4 (single frame size)
	mov [drawstack_bp + bx + 0], ax	;Push new coordinate to stack
	mov [drawstack_bp + bx + 2], cx	;Push new coordinate to stack
	inc word [drawstack_sc]			;Update stack pointer
	popa
	popf
	ret

;Draws map tiles pushed with drawstack_push
drawstack_draw:
	pushf
	pusha
	drawstack_draw_l1:					;Main loop
		cmp word [drawstack_sc], 0		;Is stack counter 0 yet?
		je drawstack_draw_end			;If yes - return from loop
		dec word [drawstack_sc]			;Decrement stack pointer
		mov bx, [drawstack_sc]			;Get stack counter value
		shl bx, 2						;Multiply the counter with 4 (single frame size)
		mov ax, [drawstack_bp + bx + 0]	;Get data from stack into ax and cx
		mov cx, [drawstack_bp + bx + 2]	;
		call drawtile					;Draw tile at coordinates read from stack
		jmp drawstack_draw_l1			;Loop
	drawstack_draw_end:					;
	mov word [drawstack_sc], 0			;Reset stack pointer
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
	mov ax, 0								;Reset horizontal counter
	findplayer_l1:							;Horizontal loop
		mov cx, 0							;Reset vertical counter
		findplayer_l2:						;Vertical loop
			call getmapaddr					;Get current map address
			mov dl, byte [fs:bx]			;Get current field content
			cmp dl, tile_player				;Check if it's player
			je findplayer_found				;If so, jump to match routine
			cmp dl, tile_socketplayer		;Check if it;s player on socket
			je findplayer_found				;If so, jump to match routine
			inc cx							;Increment vertical counter
			cmp cx, [lvldata_height]		;Vertical loop limit
			jb findplayer_l2				;Vertical loop jump
		inc ax								;Increment horizontal loop counter
		cmp ax, [lvldata_width]				;Horizontal loop limit
		jb findplayer_l1					;Horizontal loop jump
	jmp findplayer_end						;If no match, go to the end
	findplayer_found:						;Match subroutine
	mov [lvldata_playerx], ax				;Move counters value into lvldata_playerpos
	mov [lvldata_playery], cx				;Move counters value into lvldata_playerpos
	findplayer_end:							;The end
	pop fs									;
	popa									;Pop all registers
	popf
	ret

;Moves player around the map

;dl - x delta (0-1-2)
;dh - y delta (0-1-2)
movplayer:
	pushf
	pusha
	mov ax, [lvldata_playerx]		;Get current player position
	mov cx, [lvldata_playery]		;
	mov [movplayer_delta], dx		;Store delta
	mov dh, 0						;Add x delta
	add ax, dx						;
	jc movplayer_end				;Abort on position overflow
	mov dx, [movplayer_delta]		;Restore delta
	mov dl, dh						;Add y delta
	mov dh, 0						;
	add cx, dx						;
	jc movplayer_end				;Abort on position overflow
	sub ax, 1						;
	jc movplayer_end				;Abort on position underflow
	sub cx, 1						;
	jc movplayer_end				;Abort on position underflow
	mov dx, [movplayer_delta]		;Restore delta
	call movtile					;Move the player destination tile using the same delta
	mov ax, [lvldata_playerx]		;Get player position
	mov cx, [lvldata_playery]		;
	call movtile					;And finally, move the player
	mov byte [movplayer_cam_dx], 01	;Don't move camera by default
	mov byte [movplayer_cam_dy], 01	;
	mov ax, [lvldata_playerx]		;Get player position
	mov cx, [lvldata_playery]		;
	mov bx, [lvldata_camx]			;And camera position
	mov dx, [lvldata_camy]			;
	add bx, 1						;Add 1 to both x and y camera position
	jc movplayer_end				;On carry - abort
	add dx, 1						;
	jc movplayer_end				;On carry - abort
	movplayer_cam_ckl:				;
	sub ax, bx						;Check if player is standing on the edge of viewport
	jnz movplayer_cam_cku			;If so, move camera, else continue checking
	mov byte [movplayer_cam_dx], 0	;
	movplayer_cam_cku:				;
	sub cx, dx						;Check if player is standing on the edge of viewport
	jnz movplayer_cam_ckr			;If so, move camera, else continue checking
	mov byte [movplayer_cam_dy], 0	;
	movplayer_cam_ckr:				;
	mov ax, [lvldata_playerx]		;Get player position
	mov cx, [lvldata_playery]		;
	mov bx, [lvldata_camx]			;And camera position
	mov dx, [lvldata_camy]			;
	add bx, viewport_width - 2		;Add viewport size - 2 to camer position
	jo movplayer_end				;Cancel on overflow
	add dx, viewport_height - 2		;
	jo movplayer_end				;
	sub bx, ax						;Check if player is standing on the edge of viewport
	jnz movplayer_cam_ckd			;If so, move camera, else continue checking
	mov byte [movplayer_cam_dx], 2	;
	movplayer_cam_ckd:				;
	sub dx, cx						;Check if player is standing on the edge of viewport
	jnz movplayer_cam_mov			;If so, move camera, else continue checking
	mov byte [movplayer_cam_dy], 2	;
	movplayer_cam_mov:				;
	mov dx, [movplayer_cam_dx]		;Get camera delta from memory
	call movcam						;Move camera
	test al, al						;Check if it could be moved
	jz movplayer_end				;If not, quit
	call drawmap					;Else, redraw map
	movplayer_end:
	popa
	popf
	ret
	movplayer_delta: dw 0
	movplayer_cam_dx: db 0
	movplayer_cam_dy: db 0

;Moves tiles around the map
;ax - x position
;cx - y position
;dl - x delta (0-1-2)
;dh - y delta (0-1-2)
movtile:
	pushf
	pusha
	push fs										;Setup fs segment register in order to access whole map as one segment
	mov bx, lvldata_map							;
	shr bx, 4									;
	mov fs, bx									;
	mov bx, 0									;Clear bx
	mov [movtile_srcx], ax						;Store source position in memory
	mov [movtile_srcy], cx						;
	call getmapaddr								;Get source tile
	mov bl, [fs:bx]								;
	mov [movtile_src], bl						;Store it in memory
	push dx										;Add delta to source position
	mov dh, 0									;
	add ax, dx									;
	jc movtile_end								;Abort if destination exceeds range
	pop dx										;
	mov dl, dh									;
	mov dh, 0									;
	add cx, dx									;
	jc movtile_end								;Abort if destination exceeds range
	sub cx, 1									;
	jc movtile_end								;Abort on address underroll
	sub ax, 1									;
	jc movtile_end								;Abort on address underroll
	cmp ax, [lvldata_width]						;Compare destination address with map bounds
	jae movtile_end								;Abort when it exceeds map boundaries
	cmp cx, [lvldata_height]					;
	jae movtile_end								;Abort when it exceeds map boundaries
	mov [movtile_destx], ax						;Store destination in memory
	mov [movtile_desty], cx						;
	call getmapaddr								;Get destination tile
	mov bl, [fs:bx]								;
	mov [movtile_dest], bl						;And also store it in memory
	mov al, [movtile_src]						;Read both destination and source tiles into ax
	mov ah, [movtile_dest]						;
	mov bx, 0									;Reset loop counter
	movtile_l:									;
		cmp bx, movtile_allowed_cnt * 4			;Bondary is number of allowed combinations * 4 bytes each
		jae movtile_end							;Abort if proper combination hasn't been found
		cmp ax, [bx + movtile_allowed]			;If current situation matches one of predefined cases
		je movtile_move							;Move, yay!
		add bx, 4								;Go 4 bytes forward
		jmp movtile_l							;Loop
	movtile_move:								;This part actually moves the tiles
	mov dx, [bx + movtile_allowed + 2]			;Get new tile values that should be loaded
	mov ax, [movtile_srcx]						;Get source tile coordinates
	mov cx, [movtile_srcy]						;
	call drawstack_push							;Queue it for redrawing
	call getmapaddr								;Get source tile address
	mov [fs:bx], dl								;Load new tile value
	mov ax, [movtile_destx]						;Get destination tile coordinates
	mov cx, [movtile_desty]						;
	call drawstack_push							;Queue it for redrawing
	call getmapaddr								;Get its address
	mov [fs:bx], dh								;Load new tile value
	cmp byte [movtile_src], tile_player			;Check if moved tile was player
	je movtile_update_player					;Update player position
	cmp byte [movtile_src], tile_socketplayer	;Or socketplayer
	je movtile_update_player					;Update player position
	jmp movtile_end								;We are done if it was neither of them
	movtile_update_player:						;Update player position
	mov ax, [movtile_destx]						;
	mov [lvldata_playerx], ax					;
	mov ax, [movtile_desty]						;
	mov [lvldata_playery], ax					;
	movtile_end:								;The end
	pop fs
	popa
	popf
	ret
	movtile_src: db 0		;Source tile value
	movtile_srcx: dw 0		;Source position
	movtile_srcy: dw 0		;
	movtile_dest: db 0		;Destination tile value
	movtile_destx: dw 0		;Destination position
	movtile_desty: dw 0		;
	movtile_allowed:		;Allowed movement combinations (src, dest -> new src, new dest)
		db tile_player, tile_air, 			tile_air, tile_player
		db tile_player, tile_socket, 		tile_air, tile_socketplayer
		db tile_socketplayer, tile_air, 	tile_socket, tile_player
		db tile_socketplayer, tile_socket, 	tile_socket, tile_socketplayer
		db tile_box, tile_air, 				tile_air, tile_box
		db tile_box, tile_socket, 			tile_air, tile_socketbox
		db tile_socketbox, tile_air, 		tile_socket, tile_box
		db tile_socketbox, tile_socket, 	tile_socket, tile_socketbox
	movtile_allowed_cnt equ 8

;dl - detla x (0-1-2)
;dh - delta y (0-1-2)
;return al - 1 if moved, 0 otherwise
movcam:
	pushf
	pusha
	mov bx, dx					;Move delta into bx
	mov byte [movcam_moved], 0	;Assume camera didn't move
	mov cx, [lvldata_camx]		;Load current camera position
	mov dx, [lvldata_camy]		;
	movcam_xck:					;Check x position
	mov ax, [lvldata_width]		;Load level width into ax
	sub ax, viewport_width		;Substract viewport width
	jo movcam_yck				;If this causes overflow level is smaller than viewport - no need to move
	push bx						;Store delta
	mov bh, 0					;Clear upper part
	add cx, bx					;Add delta to bx
	pop bx						;Restore delta
	cmp bl, 1					;If no movement was requested - abort
	je movcam_yck				;
	sub cx, 1					;Substract 1 from x position
	js movcam_yck				;If result is negative - abort
	cmp cx, ax					;Now compare reult with max camera x allowed
	ja movcam_yck				;If exceeds - abort
	mov [lvldata_camx], cx		;If've got here - everything's fine
	mov byte [movcam_moved], 1	;Set 'moved' flag
	movcam_yck:					;Check y position
	mov ax, [lvldata_height]	;Load level height
	sub ax, viewport_height		;Substract viewport height
	jo movcam_end				;If this causes overflow level is smaller than viewport - no need to move
	push bx						;Store delta
	xchg bl, bh					;Exchange deltas
	mov bh, 0					;Clear upper part
	add dx, bx					;Add delta to cam position
	pop bx						;Restore delta
	cmp bh, 1					;If no movement was requested - abort
	je movcam_end				;
	sub dx, 1					;Substract 1
	js movcam_end				;If result is negative - abort
	cmp dx, ax					;Now compare with max camera y allowed
	ja movcam_end				;If exceeds - abort
	mov [lvldata_camy], dx		;If've got here - everything's fine
	mov byte [movcam_moved], 1	;Set 'moved' flag
	movcam_end:
	popa						;
	mov al, [movcam_moved]		;Return value
	popf
	ret
	movcam_moved: db 0



;Return requested map field address (relative to lvldata_map)
;ax - x position
;cx - y position
;return bx - address
getmapaddr:
	pushf
	pusha
	mov bx, cx						;Insert y position
	push ax							;Store ax (used for mul)
	mov ax, [lvldata_width]			;Multiply level width with y position
	mul bx							;
	mov bx, ax						;Get result to bx
	;jo $							;Game exception should be thrown here
	pop ax							;Restore bx
	add bx, ax						;Add x position to the result
	mov [getmapaddr_addr], bx		;Temporarily store address in memory
	popa							;
	popf							;
	mov bx, [getmapaddr_addr]		;Get address back from memory
	ret
	getmapaddr_addr: dw 0

;ax - level LBA address on disk
;return al - error code
lvlinfoload:
	pushf
	pusha
	push es
	mov [lvlinfoload_lba], ax							;Store level's disk LBA address
	mov bx, ds											;Make es have value of ds
	mov es, bx											;
	mov bx, lvldata										;
	mov dh, 1											;Read two sectors of header
	mov dl, [boot_drive]								;We are reading from booy drive
	mov byte [lvlinfoload_error], lvlload_error_disk	;Get the error number ready
	call diskrlba										;Read 1st sector from disk
	;jc lvlload_end										;Abort on error
	inc ax												;Increment sector number
	add bx, 512											;Increment output address
	call diskrlba										;Read second sector
	;jc lvlinfoload_end									;Abort on error
	mov si, lvlinfoload_magic							;Validate magic string
	mov di, lvldata_magic								;
	mov cx, 8											;We will be comparing 8 bytes
	rep cmpsb											;
	mov byte [lvlinfoload_error], lvlload_error_magic	;Get error number ready
	jnz lvlinfoload_end									;Abort if doesn't match
	mov ax, [lvldata_width]								;Check level size
	mov cx, [lvldata_height]							;
	mul cx												;Multiply width and height
	mov byte [lvlinfoload_error], lvlload_error_size	;Get error ready
	jo lvlinfoload_end									;Error on overflow (level can be up to 65536 bytes long)
	jz lvlinfoload_end									;Also, jump when there's no data
	mov byte [lvlinfoload_error], lvlload_error_none	;Exit without error
	lvlinfoload_end:
	pop es	
	popa
	mov al, [lvlinfoload_error]
	popf
	ret
	lvlinfoload_lba: dw 0
	lvlinfoload_error: db 0
	lvlinfoload_magic: db "soko lvl"	;Proper magic string

;ax - level LBA address on disk
;return al - error code
lvldataload:
	pushf
	pusha
	push es	
	mov [lvldataload_lba], ax							;Store level's disk LBA address
	mov bx, ds											;Make es have value of ds
	mov ax, [lvldata_width]								;Check level size
	mov cx, [lvldata_height]							;
	mul cx												;Multiply width and height
	mov byte [lvldataload_error], lvlload_error_size	;Get error ready
	jo lvldataload_end									;Error on overflow (level can be up to 65536 bytes long)
	jz lvldataload_end									;Also, jump when there's no data
	dec ax												;Decrement size in bytes
	shr ax, 9											;Divide level size (in bytes) by 512
	inc ax												;Increment by 1 (at least one sector has to be read)
	add ax, [lvldataload_lba]							;Add sector amount to initial level LBA
	add ax, 2											;And don't forget to skip two bytes of header
	mov [lvldataload_endsector], ax						;Store end sector in memory
	mov bx, ds											;Setup es to be able to address map data as one segment
	mov es, bx											;
	mov bx, lvldataload_buf								;
	mov di, 0											;Reset destination counter
	mov dl, [boot_drive]								;We are reading from boot drive
	mov dh, 1											;We are reading one sector at a time
	mov ax, [lvldataload_lba]							;Load initial LBA
	add ax, 2											;Skip header
	mov byte [lvldataload_error], lvlload_error_disk	;Get the error code ready
	lvldataload_loop:									;
		call diskrlba									;Read data from disk to buffer
		;jc lvlload_end									;Abort on disk error
		inc ax											;Increment sector counter
		push es											;Store es (used for both mcmpy and disk loader)
		mov cx, lvldata_map								;Load map data address into cx and turn it into offset
		shr cx, 4										;
		mov es, cx										;
		mov cx, 512										;We will be copying 512 bytes
		mov si, lvldataload_buf							;From the data buffer
		cld												;Clear direction flag
		rep movsb										;Copy data
		pop es											;Restore es
		cmp ax, [lvldataload_endsector]					;Compare current sector with endsector value
		jb lvldataload_loop								;Loop when less or equal
	mov byte [lvldataload_error], lvlload_error_none	;Exit without error
	lvldataload_end:									;
	pop es
	popa
	mov al, [lvldataload_error]
	popf
	ret
	lvldataload_lba: dw 0				;Initial LBA
	lvldataload_endsector: dw 0			;Sector ending the read
	lvldataload_error: db 0				;Error returned on exit
	lvldataload_buf: times 512 db 0		;Data buffer
	lvlload_error_none equ 0		;No error
	lvlload_error_disk equ 1		;Disk operation error
	lvlload_error_magic equ 2		;Bad magic string
	lvlload_error_size equ 4		;Bad level size

boot_drive: db 0

%include "gfxutils.asm"
%include "diskutils.asm"
%include "stdio.asm"

mesg_nl: db 13, 10, 0

tile_air equ 0
tile_wall equ 1
tile_box equ 2
tile_socket equ 3
tile_socketbox equ 4
tile_player equ 5
tile_socketplayer equ 6
viewport_width equ 20
viewport_height equ 12

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
	lvldata_last: db 0
	lvldata_nextjmp: db 0
	lvldata_reserved: times 1024 - ( $ - lvldata ) db 0
	lvldata_map: times 65536 - ( $ - lvldata ) db 0

;Pad out to 9 tracks
times 9 * 18 * 512 - ( $ - $$ ) db 0
