gfxtest:
	pushf
	pusha
	mov al, 0x13
	mov ah, 0
	mov bx, 0
	int 0x10
	mov cx, 0
	gfxtest_l1:
		mov dx, 0
		gfxtest_l2:
			mov ax, cx
			shr ax, 4
			add al, 50
			push ax
			mov ah, 0xc
			int 0x10
			pop ax
			add bx, 1
			add dx, 1
			cmp dx, 200
			jl gfxtest_l2
		add cx, 1
		cmp cx, 320
		jl gfxtest_l1
	mov ax, 0
	gfxtest_wait1:
		add ax, 1
		mov bx, 0
		gfxtest_wait2:
			add bx, 1
			cmp bx, 2000
			jne gfxtest_wait2
		cmp ax, 0
		jne gfxtest_wait1
	mov al, 0x03
	mov ah, 0
	int 0x10
	popa
	popf
	ret
