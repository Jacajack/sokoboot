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
	mov ax, splash_start_track			;Loading has to start from 1st track
	splash_l1:
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
		pop ax							;Restore counter

		push ax							;Save counter value
		mov al, [splash_draw_lock]		;Check if render lock is set
		cmp al, 1						;
		je splash_draw_lockset			;If so, consider job done
		mov bx, 0						;Else, reset byte counter
		splash_draw_l1:					;Main render loop
			cmp bx, 9216				;Byte counter should run 9216 times
			jge splash_draw_track_end	;If counter value is higher, finish drawing track
			mov dx, 0					;Get ready for division
			mov ax, bx					;
			add ax, [splash_draw_cnt]	;Add global counter value to the current track counter
			mov cx, 320					;Divide counter value by 340
			div cx						;
			mov cx, dx					;Get the reminder as X position
			mov dx, ax					;Get the quotient as Y position
			push bx						;Store counter value
			add bx, splash_addr			;Add splash address to counter value
			mov al, byte [bx]			;Get splash pixel value
			mov ah, 0xC					;Put pixel function
			int 0x10					;Graphics interrupt call
			pop bx						;Restore counter value
			inc bx						;Increment counter
			cmp cx, 319					;Check if last X pixel is being drawn
			jne splash_draw_l1			;If no, continue execution
			cmp dx, 199					;Check if last Y pixel is being drawn
			jne splash_draw_l1			;If no, continue execution
			jmp splash_draw_lockset		;Else, consider job done
		splash_draw_track_end:			;
		mov bx, 9216					;Increment global counter by 9216 (track size)
		add [splash_draw_cnt], bx		;
		jmp splash_draw_end				;Jump to the end
		splash_draw_lockset:			;Set up render lock
		mov al, 1						;
		mov [splash_draw_lock], al		;
		splash_draw_end:				;
		pop ax							;Restore track counter

		inc ax							;Increment loop counter
		cmp ax, splash_end_track		;Loop boundary (read 8 tracks)
		jle splash_l1					;Loop conditional jump
	popa
	popf
	ret
	splash_draw_cnt: dw 0
	splash_draw_lock: db 0
	splash_addr equ 0x2900
	splash_start_track equ 1
	splash_end_track equ 8


boot_drive: db 0

%include "diskutils.asm"

;Pad out to whole track (-boot sector)
times (17 * 512) - ($ - $$) db 0
