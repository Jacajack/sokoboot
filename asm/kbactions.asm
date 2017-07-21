;Move player right
kbaction_player_mover:
	pushf
	pusha
	mov dl, 2
	mov dh, 1
	call movplayer
	xor bh, bh
	sub [game_stepleft], bx
	popa
	popf
	ret

;Move player up
kbaction_player_moveu:
	pushf
	pusha
	mov dl, 1
	mov dh, 0
	call movplayer
	xor bh, bh
	sub [game_stepleft], bx
	popa
	popf
	ret

;Move player down
kbaction_player_moved:
	pushf
	pusha
	mov dl, 1
	mov dh, 2
	call movplayer
	xor bh, bh
	sub [game_stepleft], bx
	popa
	popf
	ret

;Move player left
kbaction_player_movel:
	pushf
	pusha
	mov dl, 0
	mov dh, 1
	call movplayer
	xor bh, bh
	sub [game_stepleft], bx
	popa
	popf
	ret

;Free camera and move it to the right
kbaction_cam_mover:
	pushf
	pusha
	call freecam
	mov dl, 2
	mov dh, 1
	call movcam
	popa
	popf
	ret

;Free camera and move it up
kbaction_cam_moveu:
	pushf
	pusha
	call freecam
	mov dl, 1
	mov dh, 0
	call movcam
	popa
	popf
	ret

;Free camera and move it down
kbaction_cam_moved:
	pushf
	pusha
	call freecam
	mov dl, 1
	mov dh, 2
	call movcam
	popa
	popf
	ret

;Free camera and move it to the left
kbaction_cam_movel:
	pushf
	pusha
	call freecam
	mov dl, 0
	mov dh, 1
	call movcam
	popa
	popf
	ret
	
;Make camera follow player again
kbaction_cam_follow:
	pushf
	pusha
	call followcam
	call drawmap
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
