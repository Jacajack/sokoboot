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
;cf - if set, only cx words are cleared
;cx - word count
vbufcl:
	pushf
	pusha
	push es					
	mov ax, VBUF_OFFSET		;Setup es to point video buffer
	mov es, ax				;
	mov ax, 0				;We are clearing with 0s
	mov di, 0				;Start point
	jc vbufcl_clear			;If carry flag is set, do not update cx
	mov cx, VBUF_LEN / 2	;Clear length/2 words
	vbufcl_clear:			;
	cld						;Clear direction flag
	rep stosw				;Memset
	pop es
	popa
	popf
	ret

;Flush video buffer to video memory
;cf - if set, only cx words are flushed
;cx - word count
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
	jc vbufflush_flush		;If cf is set, do not update cx
	mov cx, VBUF_LEN / 2	;Copy length/2 words
	vbufflush_flush:		;
	cld						;Clear direction flag
	rep movsw				;Copy data
	pop es
	pop ds
	popa
	popf
	ret

%endif
