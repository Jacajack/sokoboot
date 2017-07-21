[org 0x500]

;Get boot drive ID passed by bootloader
mov [boot_drive], dl
push dx

;Enter 13h graphics mode to draw splash screen
mov al, 0x13
mov ah, 0x0
int 0x10

;Load splash screen
call palsetup
call splashload

;Wait for a keypress
mov al, 0x00
mov ah, 0x00
int 0x16

;Menu is currently in game, so let's just load everything
mov bx, ds
mov es, bx
mov ax, 162
mov bx, 0x2900
mov dl, [boot_drive]
mov dh, 18
mov byte [diskerr_handle], 1
call diskrlba
mov ax, 162 + 18
mov bx, 0x2900 + 18 * 512
call diskrlba
jmp 0x2900

jmp $

splashload:
	pushf
	pusha
	push ds
	push es
	mov byte [diskerr_handle], 0			;Ignore disk errors - there may be holes in the image
	mov ax, splash_sector					;Sector counter
	mov cx, 0								;Address counter
	splashload_l:							;
		mov dl, [boot_drive]				;Set drive number
		mov dh, splash_sector_portion		;Read 1 sector each time
		mov bx, splash_memseg				;Setup buffer segment
		mov es, bx							;
		mov bx, splash_memaddr				;Buffer address
		call diskrlba						;Load data from disk
		mov dx, splash_memseg				;Setup source segment (buffer)
		mov ds, dx							;
		mov si, splash_memaddr				;Setup source address
		mov dx, 0xA000						;Setup destination segment (video memory)
		mov es, dx							;
		push cx								;Store address counter value
		mov di, cx							;Setup destination address
		mov cx, splash_len					;Check how many sectors are left
		sub cx, ax							;If less than one portion, then copy data partially
		cmp cx, splash_sector_portion - 1	;
		splashload_full:					;Full copy
		mov cx, 512	* splash_sector_portion	;Copy 512b * data portion size
		jmp splashload_memcpy				;
		splashload_rest:					;Partial copy
		shl cx, 9							;Multilply number of left sectors with 512
		splashload_memcpy:					;Copy data
		cld									;Clear direction flag (growing addresses)
		rep movsb							;Repeat byte copy operation
		pop cx								;Restore address counter
		add cx, 512 * splash_sector_portion	;Increment address counter
		add ax, splash_sector_portion		;Increment sector counter
		cmp ax, splash_sector+splash_len	;Check loop condition
		jbe splashload_l					;Loop
	pop es
	pop ds
	popa
	popf
	ret
	splash_sector_portion equ 18
	splash_sector equ 18
	splash_len equ 125
	splash_memaddr equ 0x4000
	splash_memseg equ 0x0000

%if splash_sector % 18 != 0
%error "Splash data has to be located at the beginig of the track!"
%endif

boot_drive: db 0

%include "diskutils.asm"
%include "gfxutils.asm"

;Pad out to whole track (-boot sector)
times (17 * 512) - ($ - $$) db 0
incbin "../resources/splash.bin"
