%ifndef VBUF
%define VBUF

%ifndef VBUF_OFFSET
%error Video buffer offset not specified!
%endif

%ifndef VBUF_LEN
%error Video buffer length not specified!
%endif

%if VBUF_LEN % 2 == 1
%error Video buffer length has to be even number!
%endif

;Clear video buffer
vbufcl:
	pushf
	pusha
	push es					
	mov ax, VBUF_OFFSET		;Setup es to point video buffer
	mov es, ax				;
	mov ax, 0				;We are clearing with 0s
	mov di, 0				;Start point
	mov cx, VBUF_LEN / 2	;Clear length/2 words
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
	mov ax, VBUF_OFFSET		;Setup ds to point video buffer
	mov ds, ax				;
	mov ax, 0xa000			;Setup es to point video memory
	mov es, ax				;
	mov si, 0				;Start points
	mov di, 0				;
	mov cx, VBUF_LEN / 2	;Copy length/2 words
	cld						;Clear direction flag
	rep movsw				;Copy data
	pop es
	pop ds
	popa
	popf
	ret

%endif
