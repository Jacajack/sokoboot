[org 0x500]

;Get boot drive ID passed by bootloader
mov [boot_drive], dl

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


;SOME MENU HERE
;FOR NOW, JUST LOAD THE GAME
mov dh, 1
mov ch, 4
mov cl, 1
mov al, 18
mov dl, [boot_drive]
mov bx, 0x2900
call diskrchs
jmp 0x2900

jmp $

;Setup color palette (bbgggrrr)
palsetup:
	pushf
	pusha
	mov ax, 0			;Output 0 to 0x03c8 - overwrite whole palette
	mov dx, 0x03c8		;
	out dx, al			;
	mov dx, 0x03c9		;Color data will be sent to 0x03c9
	mov cx, 0			;Reset color counter
	palsetup_l1:		;
		mov ax, cx		;Get counter value
		and al, 0x07	;Get 3 youngest bits
		shl al, 3		;Shift them 3 bits to the left
		out dx, al		;Output red channel value
		mov ax, cx		;Get counter value
		and al, 0x38	;Get bits 3, 4, 5
		out dx, al		;Output green channel value
		mov ax, cx		;Get counter value
		and al, 0xC0	;Get 2 oldest bits
		shr al, 2		;Shift 'em 2 bits to the right
		out dx, al		;Output blue channel value
		inc cx			;Increment color counter
		cmp cx, 256		;Palette has 256 colors
		jb palsetup_l1	;Loop
	popa
	popf
	ret


splashload:
	pushf
	pusha
	push ds
	push es
	mov ax, splash_sector			;Sector counter
	mov cx, 0						;Address counter
	splash_l:
		mov dl, [boot_drive]		;Set drive number
		mov dh, 1					;Read 1 sector each time
		mov bx, splash_memseg		;Setup buffer segment
		mov es, bx					;
		mov bx, splash_memaddr		;Buffer address
		call diskrlba				;Load data from disk
		mov dx, splash_memseg		;Setup source segment (buffer)
		mov ds, dx					;
		mov si, splash_memaddr		;Setup source address
		mov dx, 0xA000				;Setup destination segment (video memory)
		mov es, dx					;
		mov di, cx					;Setup destination address
		push cx						;Store address counter value
		mov cx, 512					;Copy 512b
		cld							;Clear direction flag (growing addresses)
		rep movsb					;Repeat byte copy operation
		pop cx						;Restore address counter
		add cx, 512					;Increment address counter
		inc ax						;Increment sector counter
		cmp ax, splash_sector+splash_len	;Check loop condition
		jbe splash_l				;Loop
	pop es
	pop ds
	popa
	popf
	ret
	splash_sector equ 18
	splash_len equ 125
	splash_memaddr equ 0xf000
	splash_memseg equ 0x0000

boot_drive: db 0

%include "diskutils.asm"

;Pad out to whole track (-boot sector)
times (17 * 512) - ($ - $$) db 0
