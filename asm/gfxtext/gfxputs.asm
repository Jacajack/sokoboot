%ifndef GFXTEXT_PUTS
%define GFXTEXT_PUTS

;si - string
;bl - fore color
;bh - background color
;cx - x position
;dx - y position
gfxputs:
	pushf
	pusha
	gfxputs_loop:
		cmp byte [si], 0	;Check special cases - NUL
		je gfxputs_end		;
		cmp byte [si], 13	;CR
		je gfxputs_cr		;
		cmp byte [si], 10	;LF
		je gfxputs_lf		;
		cmp byte [si], 8	;BP
		je gfxputs_bp		;
		cmp byte [si], 9	;TAB
		je gfxputs_tab		;
		mov al, [si]		;Normal case - get character into al
		call gfxputc		;Print it
		add cx, 8			;Move 8 pixels to the right
		inc si				;Increment counter
		jmp gfxputs_loop	;
		gfxputs_bp:			;BP
		sub cx, 8			;Move 8 pixels to the left
		inc si				;
		jmp gfxputs_loop	;
		gfxputs_tab:		;TAB
		add cx, 8 * 4		;Move 32 pixels to the right
		inc si				;
		jmp gfxputs_loop	;
		gfxputs_lf:			;LF
		add dx, 8			;Move 8 pixels and right down
		add cx, 8			;
		inc si				;
		jmp gfxputs_loop	;
		gfxputs_cr:			;CR
		mov cx, 0			;Move to the left screen edge
		inc si				;
		jmp gfxputs_loop	;
	gfxputs_end:	
	popa
	popf
	ret

%include "gfxtext/gfxputc.asm"
%endif
