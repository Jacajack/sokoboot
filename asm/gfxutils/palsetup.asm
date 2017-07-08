%ifndef GFXUTILS_PALSETUP
%define GFXUTILS_PALSETUP

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

%endif
