delay:
	pushf
	pusha
	mov dx, ax
	delay1:
	add ax, 1
	mov bx, 0
	delay2:
		add bx, 1
		cmp bx, dx
		jne delay2
	cmp ax, 0
	jne delay1
	popa
	popf
	ret
