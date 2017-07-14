lvldata:
	lvldata_magic: db "soko lvl"
	lvldata_id: dw 0
	lvldata_name: times 80 db 0
	lvldata_desc: times 320 db 0
	lvldata_playerx: dw 0
	lvldata_playery: dw 0
	lvldata_width: dw 255
	lvldata_height: dw 256
	lvldata_camx: dw 0
	lvldata_camy: dw 0
	lvldata_flags: dw 0, 0
	lvldata_next: dw 0
	lvldata_reserved: times 1024 - ( $ - lvldata ) db 0
	lvldata_map:

	map:db 5
	 times 65535 db 0, 3




	;times 65536 - ( $ - lvldata_map ) db 0
