%ifndef VBUF
%define VBUF

vbuf_addr equ 0x7000
vbuf_len equ 0xf000

;Clear video buffer
vbufcl:
	pushf
	pusha
	push es					
	mov ax, vbuf_addr		;Setup es to point video buffer
	mov es, ax				;
	mov ax, 0				;We are clearing with 0s
	mov di, 0				;Start point
	mov cx, vbuf_len / 2	;Clear length/2 words
	cld						;Clear direction flag
	rep stosw				;Memset
	pop es
	popa
	popf
	ret

;Flush video buffer to video memory
vbufflush:
	pushf
	pusha
	push ds
	push es
	mov ax, vbuf_addr		;Setup ds to point video buffer
	mov ds, ax				;
	mov ax, 0xa000			;Setup es to point video memory
	mov es, ax				;
	mov si, 0				;Start points
	mov di, 0				;
	mov cx, vbuf_len / 2	;Copy length/2 words
	cld						;Clear direction flag
	rep movsw				;Copy data
	pop es
	pop ds
	popa
	popf
	ret

%endif
