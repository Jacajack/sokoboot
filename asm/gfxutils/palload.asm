%ifndef GFXUTILS_PALLOAD
%define GFXUTILS_PALLOAD

;Load color palette (bbgggrrr)
;al - R tweak
;ah - G tweak
;bl - B tweak
;es - data segment
;si - palette address
palload:
	pushf
	pusha
	mov [palload_rt], al			;Save tweaks in memory
	mov [palload_gt], ah			;
	mov [palload_bt], bl			;
	mov ax, 0						;Output 0 to 0x03c8 - overwrite whole palette
	mov dx, 0x03c8					;
	out dx, al						;
	mov dx, 0x03c9					;Color data will be sent to 0x03c9
	mov cx, 768						;768 bytes of palette will be sent
	mov bx, 0						;
	palload_loop:					;Main loop
		or cx, cx					;Check if cx is 0
		jz palload_end				;
		cmp bx, 3					;If bx is 3, set it to 0
		jl palload_chan				;
		xor bx, bx					;
		palload_chan:				;
		mov al, [es:si]				;Load data byte
		add al, [palload_rt + bx]	;Add tweak to channel value
		cmp al, 0					;If below zero, round up to 0
		jl palload_dn				;
		cmp al, 64					;If above 63
		jge palload_up				;Round down to 63
		jmp palload_ok 				;Else, everything ok
		palload_up:					;
		mov al, 63					;
		jmp palload_ok				;
		palload_dn:					;
		mov al, 0					;
		palload_ok:					;
		out dx, al					;Output channel value
		inc bx						;Increment channel number
		inc si						;Increment memory pointer
		dec cx						;Decrement number of bytes left
		jmp	palload_loop 			;Loop
	palload_end:
	popa
	popf
	ret
	palload_rt: db 0
	palload_gt: db 0
	palload_bt: db 0

%endif
