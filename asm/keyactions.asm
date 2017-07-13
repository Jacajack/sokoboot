;Move player right and redraw drawstack contents
kbaction_player_mover:
	pusha
	pushf
	mov dl, 2
	mov dh, 1
	call movplayer
	call drawstack_draw
	popf
	popa
	ret

;Move player up and redraw drawstack contents
kbaction_player_moveu:
	pusha
	pushf
	mov dl, 1
	mov dh, 0
	call movplayer
	call drawstack_draw
	popf
	popa
	ret

;Move player down and redraw drawstack contents
kbaction_player_moved:
	pusha
	pushf
	mov dl, 1
	mov dh, 2
	call movplayer
	call drawstack_draw
	popf
	popa
	ret

;Move player left and redraw drawstack contents
kbaction_player_movel:
	pusha
	pushf
	mov dl, 0
	mov dh, 1
	call movplayer
	call drawstack_draw
	popf
	popa
	ret

kbaction_reload_level:
	pop bx
	mov bx, 0
	jmp lvlprompt
