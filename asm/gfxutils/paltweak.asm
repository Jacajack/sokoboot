%ifndef GFXUTILS_PALTWEAK
%define GFXUTILS_PALTWEAK

;Tweak color palette (bbgggrrr)
;al - R channel tweak
;ah - G channel tweak
;bl - B channel tweak
paltweak:
	pushf
	pusha
	mov [paltweak_rt], al		;Store tweak values
	mov [paltweak_gt], ah		;
	mov [paltweak_bt], bl		;
	mov ax, 0					;Output 0 to 0x03c8 - overwrite whole palette
	mov dx, 0x03c8				;
	out dx, al					;
	mov dx, 0x03c9				;Color data will be sent to 0x03c9
	mov cx, 0					;Reset color counter
	paltweak_l1:				;
		mov ax, cx				;Get counter value
		and al, 0x07			;Get 3 youngest bits
		shl al, 3				;Shift them 3 bits to the left
		add al, [paltweak_rt]	;Add tweak to channel value
		cmp al, 0				;If below zero, round up to 0
		jl paltweak_rdn			;
		cmp al, 64				;If above 63
		jge paltweak_rup		;Round down to 63
		jmp paltweak_rok 		;Else, everything ok
		paltweak_rup:			;
		mov al, 63				;
		jmp paltweak_rok		;
		paltweak_rdn:			;
		mov al, 0				;
		paltweak_rok:			;
		out dx, al				;Output red channel value
		mov ax, cx				;Get counter value
		and al, 0x38			;Get bits 3, 4, 5
		add al, [paltweak_gt]	;Add green channel tweak
		cmp al, 0				;If below 0, round up to 0
		jl paltweak_gdn			;
		cmp al, 64				;If above 63, round down to 63
		jge paltweak_gup		;
		jmp paltweak_gok 		;
		paltweak_gup:			;
		mov al, 63				;
		jmp paltweak_gok		;
		paltweak_gdn:			;
		mov al, 0				;
		paltweak_gok:			;
		out dx, al				;Output green channel value
		mov ax, cx				;Get counter value
		and al, 0xC0			;Get 2 oldest bits
		shr al, 2				;Shift 'em 2 bits to the right
		add al, [paltweak_bt]	;Add blue channel tweak
		cmp al, 0				;If below 0, round up to 0
		jl paltweak_bdn			;
		cmp al, 64				;If above 63, round down to 63
		jge paltweak_bup		;
		jmp paltweak_bok 		;Everything is ok
		paltweak_bup:			;
		mov al, 63				;
		jmp paltweak_bok		;
		paltweak_bdn:			;
		mov al, 0				;
		paltweak_bok:			;
		out dx, al				;Output blue channel value
		inc cx					;Increment color counter
		cmp cx, 256				;Palette has 256 colors
		jb paltweak_l1			;Loop
	popa
	popf
	ret
	paltweak_rt: db 0
	paltweak_gt: db 0
	paltweak_bt: db 0

%endif
