fat1:
    db 0xF0, 0xFF, 0xFF   ; cluster 0,1
    db 0xFF, 0x0F          ; cluster 2 = FFF
    times (9*512 - ($ - fat1)) db 0

; =============================
; FAT2 (完全拷贝 FAT1)
; =============================
fat2:
    db 0xF0, 0xFF, 0xFF
    db 0xFF, 0x0F
    times (9*512 - ($ - fat2)) db 0

; =============================
; 根目录区 (14 sectors)
; =============================

rootdir:
; 目录项结构：
; [0-7] 文件名
; [8-10] 扩展名
; [11] 属性
; [26-27] 起始簇
; [28-31] 文件大小
    db 'PONG    '      ; 文件名
    db 'EXE'           ; 扩展名
    db 0x20            ; 普通文件
    db 0               ; 保留
    db 0,0,0,0,0,0,0,0,0,0  ; 时间日期等
    dw 2               ; 起始簇号
    dd FILE - FILE_end  ; 文件大小

    times 32*223 db 0  ; 剩余目录项清零
times 14*512 - ($ - rootdir) db 0