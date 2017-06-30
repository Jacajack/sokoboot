disk_n_s equ 18				;Sectors per track
disk_n_h equ 2				;Heads per cylinder
disk_err_threshold equ 5	;Error threshold

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

;Reads data from disk
;ax - LBA
;dl - drive number
;dh - sector count
;es:bx - data addresses
diskrlba:
	pushf
	pusha
	push dx							;Store dx value
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_s				;Divide LBA by sector per track count
	div cx							;
	inc dx							;Increment reminder
	mov [diskrlba_s], dx			;Save reminder as sector number
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_h				;Divide LBA by heads per cylinder count
	div cx							;
	mov [diskrlba_h], dx			;Reminder is head number
	mov [diskrlba_c], ax			;Quotient is cylinder number
	pop dx							;Restore dx
	mov al, dh						;Load sectors amount into al
	mov cl, [diskrlba_s]			;Load CHS
	mov ch, [diskrlba_c]			;
	mov dh, [diskrlba_h]			;
	call diskrchs
	popa
	popf
	ret
	diskrlba_s: dw 0			;Sector number
	diskrlba_h: dw 0			;Head number
	diskrlba_c: dw 0			;Cylinder number

;Writes data to disk
;al - sector count
;es:bx - data address
;cl - sector number
;ch - cylinder number
;dl - drive number
;dh - head number
;es:bx - data addresses
diskwchs:
	pushf
	pusha
	jmp diskwchs_start
	diskwchs_reset:
		popa
		pusha
		mov ah, 0					;Reset disk
		int 0x13					;
	diskwchs_start:
		popa						;In case disk reset modified registers
		pusha						;
		mov ah, 0x3 				;Sector write
		int 0x13					;Disk interrupt
		jnc diskwchs_end			;If carry flag is not set (no error, quit)
		mov cx, [diskwchs_cnt]		;Increment error counter
		inc cx						;
		mov [diskwchs_cnt], cx		;
		cmp cx, disk_err_threshold	;Check if error count is below threshold
		jle diskwchs_reset			;If so, try again
		call diskerr				;Else, call disk error handler
	diskwchs_end:					;
	mov cx, 0						;Clear error counter
	mov [diskwchs_cnt], cx			;
	popa
	popf
	ret
	diskwchs_cnt: dw 0				;Disk error counter


;Writes data to disk
;ax - LBA
;dl - drive number
;dh - sector count
;es:bx - data addresses
diskwlba:
	pushf
	pusha
	push dx							;Store dx value
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_s				;Divide LBA by sector per track count
	div cx							;
	inc dx							;Increment reminder
	mov [diskwlba_s], dx			;Save reminder as sector number
	mov dx, 0						;Clear reminder register
	mov cx, disk_n_h				;Divide LBA by heads per cylinder count
	div cx							;
	mov [diskwlba_h], dx			;Reminder is head number
	mov [diskwlba_c], ax			;Quotient is cylinder number
	pop dx							;Restore dx
	mov al, dh						;Load sectors amount into al
	mov cl, [diskwlba_s]			;Load CHS
	mov ch, [diskwlba_c]			;
	mov dh, [diskwlba_h]			;
	call diskwchs
	popa
	popf
	ret
	diskwlba_s: dw 0			;Sector number
	diskwlba_h: dw 0			;Head number
	diskwlba_c: dw 0			;Cylinder number

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
