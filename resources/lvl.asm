lvldata:
	lvldata_magic: db "soko lvl"
	lvldata_id: dw 0
	lvldata_sectors: dw 144
	lvldata_name: times 80 db 0
	lvldata_desc: times 320 db 0
	lvldata_playerpos: db 0, 0
	lvldata_size: db 32, 20
	lvldata_flags: dw 0, 0
	lvldata_next: dw 0
	lvldata_reserved: times 1024 - ( $ - lvldata ) db 0
	lvldata_map: times 65536 - ( $ - lvldata ) db 1
