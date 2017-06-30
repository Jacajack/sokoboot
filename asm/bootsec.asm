[bits 16]
[org 0x7c00]

;Store boot drive
mov [boot_drive], dl

;Stack init
mov ax, 0x8fc0
mov ss, ax
mov bp, 0xffff
mov sp, bp

;Load first track
mov dl, [boot_drive]	;Set drive number
call diskreset
mov al, 17				;Sector count = 17
mov cl, 2				;First sector = 2
mov ch, 0				;Track = 0
mov dh, 0				;Head = 0
mov bx, 0x500			;Set destination
call diskrchs

;Boot drive ID is left behind in dl
mov dl, [boot_drive]

;Jump to loaded instructions
jmp 0x500

jmp $

disk_n_s equ 18				;Sectors per track
disk_n_h equ 2				;Heads per cylinder
disk_err_threshold equ 5	;Error threshold
boot_drive: db 0

;Reads data from disk
;al - sector count
;es:bx - data address
;cl - sector number
;ch - cylinder number
;dl - drive number
;dh - head number
;es:bx - data addresses
diskrchs:
	pushf
	pusha
	jmp diskrchs_start
	diskrchs_reset:
		popa
		pusha
		mov ah, 0					;Reset disk
		int 0x13					;
	diskrchs_start:
		popa						;In case disk reset modified registers
		pusha						;
		mov ah, 0x2 				;Sector read
		int 0x13					;Disk interrupt
		jnc diskrchs_end			;If carry flag is not set (no error, quit)
		mov cx, [diskrchs_cnt]		;Increment error counter
		inc cx						;
		mov [diskrchs_cnt], cx		;
		cmp cx, disk_err_threshold	;Check if error count is below threshold
		jle diskrchs_reset			;If so, try again
		call diskerr				;Else, call disk error handler
	diskrchs_end:					;
	mov cx, 0						;Clear error counter
	mov [diskrchs_cnt], cx			;
	popa
	popf
	ret
	diskrchs_cnt: dw 0				;Disk error counter


;Resets chosen disk
;dl - drive number
diskreset:
	pushf
	pusha
	mov ah, 0 						;Reset disk
	int 0x13						;BIOS drive interrupt
	popa
	popf
	ret

;Disk error handler
diskerr:
	pushf
	pusha
	mov si, diskerr_mesg	;Load message address into si
	mov ah, 0xE				;Setup ah for interrupt
	diskerr_l1:				;Puts loop
		mov al, [si]		;Load into al
		cmp al, 0			;Compare character with 0
		je diskerr_end		;If equal, end run
		int 0x10			;Run interrupt
		inc si				;Increment counter
		jmp diskerr_l1		;Loop
	diskerr_end:
	jmp $
	popa
	popf
	ret
	diskerr_mesg:
		db "[critical] disk fault!", 10, 13
		db 0

;Padding and magic number
times 510 - ( $ - $$ ) db 0
dw 0xaa55
