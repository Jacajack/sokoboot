%ifndef STDIO_STRFETCH
%define STDIO_STRFETCH

;Searches to nth string after si pointer
;al - string number
;si - first string
strfetch:
	pushf
	push ax						;Only stote ax
	strfetch_l1:				;
		cmp ax, 0				;Seek till ax is 0
		je strfetch_end			;At last, quit
		strfetch_l2:			;
			cmp byte [si], 0	;Check if we are at NUL char
			je strfetch_nul		;If so, we found another string
			inc si				;Else seek char by char
			jmp strfetch_l2		;Loop
		strfetch_nul:			;
		dec al					;Decrement ax
		jmp strfetch_l1			;Fetch another string
	strfetch_end:				;
	inc si						;Set si to point begining of next string
	pop ax						;Only pop ax
	popf
	ret

%endif
