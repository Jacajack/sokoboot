[bits 16]
[org 0x7c00]

;Store boot drive
mov [BOOT_DRIVE], dl

;Stack init
mov bp, 0xffff
mov sp, bp

mov ah, 0
mov al, 3
int 0x10

;Display greeting
mov si, greeting_s
call puts

;Display boot message
mov si, bootdrive_s
call puts
mov al, [BOOT_DRIVE]
call puthex
mov ah, 0xe
mov al, 10
int 0x10
mov al, 13
int 0x10

;Load 16 sectors from disk
mov dl, [BOOT_DRIVE]
call diskreset
mov dl, [BOOT_DRIVE]
mov cl, 2
mov al, 0x10
mov bx, 0x500
call diskload
mov si, diskload_success_s
call puts

;Run loaded instructions
jmp 0x500
jmp $

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%include "puts.asm"
%include "puthex.asm"
%include "diskutils.asm"

BOOT_DRIVE: db 0

greeting_s:
	db 'BOOT PROCESS ENGAGED:', 10, 13
	db ' -> LOADING FULL BOOTLOADER', 10, 13, 0

bootdrive_s:
	db ' -> BOOT DRIVE NO. 0x', 0

diskload_success_s:
	db ' -> LOADING FROM DISK SUCCESSFULL', 10, 13, 0

nl_s:
	db 10, 13, 0

;Padding and magic number
times 510 - ( $ - $$ ) db 0
dw 0xaa55
