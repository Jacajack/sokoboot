;Move player right and redraw drawstack contents
kbaction_player_mover:
	pushf
	pusha
	mov dl, 2
	mov dh, 1
	call movplayer
	call drawstack_draw
	popa
	popf
	ret

;Move player up and redraw drawstack contents
kbaction_player_moveu:
	pushf
	pusha
	mov dl, 1
	mov dh, 0
	call movplayer
	call drawstack_draw
	popa
	popf
	ret

;Move player down and redraw drawstack contents
kbaction_player_moved:
	pushf
	pusha
	mov dl, 1
	mov dh, 2
	call movplayer
	call drawstack_draw
	popa
	popf
	ret

;Move player left and redraw drawstack contents
kbaction_player_movel:
	pushf
	pusha
	mov dl, 0
	mov dh, 1
	call movplayer
	call drawstack_draw
	popa
	popf
	ret

;Abandon game
kbaction_quit:
	pushf
	pusha
	mov byte [game_quitrq], 1
	popa
	popf
	ret
