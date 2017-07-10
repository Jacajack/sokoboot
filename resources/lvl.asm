lvldata:
	lvldata_magic: db "soko lvl"
	lvldata_id: dw 0
	lvldata_name: times 80 db 0
	lvldata_desc: times 320 db 0
	lvldata_playerpos: dw 0, 0
	lvldata_size: dw 32, 20
	lvldata_flags: dw 0, 0
	lvldata_next: dw 0
	lvldata_reserved: times 1024 - ( $ - lvldata ) db 0
	lvldata_map: 
	
	times 40 db 0
	db 5, 0, 0, 1, 2, 0, 0, 3, 
	
	times 65536 - ( $ - lvldata ) db 0
