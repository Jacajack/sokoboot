%ifndef GFXTEXT_GFXPUTC
%define GFXTEXT_GFXPUTC

%ifndef GFXTEXT_VBUF_OFFSET
%warning Location of video buffer not specified!
%define GFXTEXT_VBUF_OFFSET 0xa000
%endif

;al - character
;bl - fore color
;bh - bg color
;cx - x position
;dx - y position
gfxputc:
	pushf
	pusha
	push es
	push fs
	mov [gfxputc_fg], bl			;Store colors in memory
	mov [gfxputc_bg], bh			;
	mov bx, GFXTEXT_VBUF_OFFSET		;Load video buffer offset into ES
	mov es, bx						;
	mov bx, gfxtext_font			;Load font buffer offset into FS
	shr bx, 4						;
	mov fs, bx						;
	mov bx, dx						;Load pixel displacement into BX
	shl dx, 6						;
	shl bx, 8						;
	add bx, dx						;
	add bx, cx						;
	movzx cx, al					;Load font character displacement into CX
	shl cx, 3						;
	mov al, 0						;Reset row counter
	gfxputc_row:					;
		cmp al, 8					;We will draw 8 rows
		jae gfxputc_end				;
		push bx						;Store inital position
		mov ah, 0					;Reset column counter
		mov dl, 1					;Reset bit mask
		gfxputc_col:				;
			cmp ah, 8				;We will draw 8 collumns
			jae gfxputc_col_end		;
			push cx					;Store font char offset
			push bx					;Store position
			mov bx, cx				;
			test byte [fs:bx], dl	;Get one pixel from font
			setz cl					;Depending on its value, set cl
			xor ch, ch				;
			add cx, gfxputc_fg		;Add foreground color address to cx
			mov bx, cx				;
			mov cl, [bx]			;Get dsired color into cl
			pop bx					;
			mov [es:bx], cl			;Write cl into video memory
			pop cx					;
			shl dl, 1				;Shift bit mask
			add bx, 1				;Increment bx (one pixel to the right)
			jc gfxputc_col_end		;Overflow protection
			inc ah					;Increment col counter
			jmp gfxputc_col			;Loop
		gfxputc_col_end:			;Loop end
		pop bx						;Restore position
		add bx, 320					;Add 320 to it (next pixel line)
		jc gfxputc_end				;Overflow protection
		inc cx						;Next font data byte
		inc al						;Increment row counter
		jmp gfxputc_row				;Loop
	gfxputc_end:					;End
	pop fs
	pop es
	popa
	popf
	ret
	gfxputc_fg: db 0
	gfxputc_bg: db 0

%endif
