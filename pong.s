; 第一扇区 0x7C00
org 0x7C00

start_up:
    jmp load_disk
    nop
OEM     db "MSDOS5.0"            ; 8 bytes

BytesPerSec  dw 512              ; bytes per sector
SecPerClus   db 1                ; sectors per cluster
ReservedSecs dw 1                ; reserved sectors (boot)
NumFATs      db 2                ; number of FATs
RootEnts     dw 224              ; root dir entries
TotSectors16 dw 2880             ; total sectors (for 1.44MB)
Media        db 0xF0             ; media descriptor
SecsPerFAT   dw 9                ; sectors per FAT
SecsPerTrack dw 18               ; sectors per track
NumHeads     dw 2                ; heads
HiddenSecs   dd 0                ; hidden sectors
TotSectors32 dd 0                ; large total sectors (not used)
; Extended BPB / Boot sector info
DriveNum     db 0                ; drive number (filled by BIOS)
Reserved     db 0
BootSig      db 0x29
VolumeID     dd 0x12345678
VolumeLabel  db "PONG GAME  "
FileSysType  db "FAT12   "
load_disk:
    mov si, load_msg
    call print_string_startup
    ; ... 你原来的磁盘加载和配置逻辑 ...
    mov ah, 2h    ; int13h 号2功能
    mov al, [TotSectors16]     ; 读取全部
    mov ch, 0     ; 从柱面号0读取
    mov cl, 2     ; 扇区号2 - 第二扇区 (从1开始, 并非0)
    mov dh, 0     ; 磁头1
    xor bx, bx    
    mov es, bx    ; es应为0
    mov bx, 7E00h ; 加载到7E00
    int 13h
    
    jnc .disk_success       ; 如果 CF = 1，表示读盘错误
    mov si, dsk_err_msg
    call print_string_startup
    jmp $
.disk_success:
    jmp end
print_string_startup:
    mov ah, 0x0E        ; BIOS TTY 输出功能
.print_loop:
    lodsb               ; 从 [SI] 取出下一个字符 → AL
    or al, al           ; 检查是否到字符串结尾（0）
    jz .done
    int 0x10            ; 输出 AL
    jmp .print_loop
.done:
    ret
; ---------------- ISR ----------------
load_msg db "Loading", 10, 13, 0
dsk_err_msg db "DISK ERROR", 0
times 510-($-$$) db 0xFF   ; 填充到 510 字节
dw 0xAA55 
%include"fat.s"
end:
%include"main.s"
FILE:
incbin "pong.com"
FILE_end:
times (2880*512)-($-$$) db 0   ; 填充到 4096 字节, 8个扇区
