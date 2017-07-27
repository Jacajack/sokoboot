%ifndef GFXUTILS_PALGEN
%define GFXUTILS_PALGEN

;Tweak generated color palette (bbgggrrr)
;al - R channel tweak
;ah - G channel tweak
;bl - B channel tweak
palgen:
	pushf
	pusha
	mov [palgen_rt], al			;Store tweak values
	mov [palgen_gt], ah			;
	mov [palgen_bt], bl			;
	mov ax, 0					;Output 0 to 0x03c8 - overwrite whole palette
	mov dx, 0x03c8				;
	out dx, al					;
	mov dx, 0x03c9				;Color data will be sent to 0x03c9
	mov cx, 0					;Reset color counter
	palgen_l1:					;
		mov ax, cx				;Get counter value
		and al, 0x07			;Get 3 youngest bits
		shl al, 3				;Shift them 3 bits to the left
		add al, [palgen_rt]		;Add tweak to channel value
		cmp al, 0				;If below zero, round up to 0
		jl palgen_rdn			;
		cmp al, 64				;If above 63
		jge palgen_rup			;Round down to 63
		jmp palgen_rok 			;Else, everything ok
		palgen_rup:				;
		mov al, 63				;
		jmp palgen_rok			;
		palgen_rdn:				;
		mov al, 0				;
		palgen_rok:				;
		out dx, al				;Output red channel value
		mov ax, cx				;Get counter value
		and al, 0x38			;Get bits 3, 4, 5
		add al, [palgen_gt]		;Add green channel tweak
		cmp al, 0				;If below 0, round up to 0
		jl palgen_gdn			;
		cmp al, 64				;If above 63, round down to 63
		jge palgen_gup			;
		jmp palgen_gok 			;
		palgen_gup:				;
		mov al, 63				;
		jmp palgen_gok			;
		palgen_gdn:				;
		mov al, 0				;
		palgen_gok:				;
		out dx, al				;Output green channel value
		mov ax, cx				;Get counter value
		and al, 0xC0			;Get 2 oldest bits
		shr al, 2				;Shift 'em 2 bits to the right
		add al, [palgen_bt]		;Add blue channel tweak
		cmp al, 0				;If below 0, round up to 0
		jl palgen_bdn			;
		cmp al, 64				;If above 63, round down to 63
		jge palgen_bup			;
		jmp palgen_bok 			;Everything is ok
		palgen_bup:				;
		mov al, 63				;
		jmp palgen_bok			;
		palgen_bdn:				;
		mov al, 0				;
		palgen_bok:				;
		out dx, al				;Output blue channel value
		inc cx					;Increment color counter
		cmp cx, 256				;Palette has 256 colors
		jb palgen_l1			;Loop
	popa
	popf
	ret
	palgen_rt: db 0
	palgen_gt: db 0
	palgen_bt: db 0

%endif
