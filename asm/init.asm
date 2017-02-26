[org 0x500]

;Get boot drive ID passed by bootloader
mov [boot_drive], dl

;Enter 13h graphics mode to draw splash screen
mov al, 0x13
mov ah, 0x0
int 0x10

call splash

;Wait for a keypress
mov al, 0x00
mov ah, 0x00
int 0x16


;SOME MENU HERE
;FOR NOW, JUST LOAD THE GAME
mov dh, 1
mov ch, 4
mov cl, 1
mov al, 18
mov dl, [boot_drive]
mov bx, 0x2900
call diskload
jmp 0x2900

jmp $

;Load splash sreen and display it
splash:
	pushf
	pusha
	mov ax, splash_start_track			;Load first track number
	splash_l1:							;
		push ax							;Save counter
		shl ax, 7						;Shift track number 7 bits to the left
		shr al, 7						;Get youngest bit
		mov dh, al						;Head number is now the youngest bit value
		mov ch, ah						;Cylinder number is now 7 other bits
		mov cl, 1						;Start sector = 1
		mov al, 18						;Read 18 sectors each time (whole track)
		mov dl, [boot_drive]			;Read from boot drive
		mov bx, splash_addr				;Read to address pointed by "splash_addr"
		call diskload					;Call diskload
		push es							;Push extra segment register
		mov ax, 0xA000					;Setup extra segment register (to point video memory)
		mov es, ax						;
		mov bx, 0						;Reset render counter
		splash_draw_l1:					;Main render loop
			mov ax, bx					;Move bx to ax (to left it untouched)
			add ax, [splash_draw_cnt]	;Calculate video memory offset
			cmp ax, 64000				;If whole screen has been drawn, skip one run
			jae splash_draw_done		;
			push bx						;Store counter value
			mov ax, [bx+splash_addr]	;Get splash byte
			add bx, [splash_draw_cnt]	;Get total video memory offset
			mov [es:bx], al				;Write data loaded from floppy directly to video memory
			pop bx						;Restore counter value
			inc bx						;Increment render counter
			cmp bx, 9216				;Render counter should run 9216 each track
			jbe splash_draw_l1			;
		mov dx, 9216					;Update base video memory offset
		add [splash_draw_cnt], dx		;
		jmp splash_draw_end				;Go to the end of rendering part
		splash_draw_done:				;Only executed when whole screen is drawn
		mov ax, bx						;Get video memory base offset to point end of it
		add ax, [splash_draw_cnt]		;
		mov [splash_draw_cnt], ax		;
		splash_draw_end:				;Rendering ends here
		pop es							;Restore extra segment register
		pop ax							;Restore track counter
		inc ax							;Increment loop counter
		cmp ax, splash_end_track		;Loop boundary
		jbe splash_l1					;Loop conditional jump
	popa
	popf
	ret
	splash_draw_cnt: dw 0
	splash_addr equ 0x2900
	splash_start_track equ 1
	splash_end_track equ 8


boot_drive: db 0

%include "diskutils.asm"

;Pad out to whole track (-boot sector)
times (17 * 512) - ($ - $$) db 0
