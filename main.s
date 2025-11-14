main:
    ; --- 初始化 PIT 60Hz ---
    mov al, 36h       ; 控制字节
    out 43h, al
    mov ax, 4DBEh     ; 1193180/60 ≈ 0x4DBE
    out 40h, al
    mov al, ah
    out 40h, al

    ; --- 保存原 IRQ0 向量 ---
    cli
    mov ax, 0
    mov es, ax
    mov bx, 8*4
    mov dx, [es:bx]
    mov [old_irq0_offset], dx
    mov dx, [es:bx+2]
    mov [old_irq0_segment], dx

    ; --- 设置新 IRQ0 向量 ---
    mov word [es:bx], irq0_handler
    mov word [es:bx+2], cs
    sti
    call clean_scr
    mov si, startup_msg ;加载正确提示
    call print_string 
    call wait_key ;等待任意键
    call wait_key_up ;等待任意键松开
    mov si, config_msg1
    call print_string  ; 输出第一个配置询问
    mov bx, [color_paddle]
    call get_color
    mov [color_paddle], bx
    mov si, config_msg2
    call print_string  ; 输出第二个配置询问
    mov bx, [color_enemy]
    call get_color
    mov [color_enemy], bx
    mov si, config_msg3
    call print_string  ; 输出第三个配置询问
    mov bx, [color_ball]
    call get_color
    mov [color_ball], bx
    mov si, config_msg4
    call print_string  ; 输出第三个配置询问
    mov bx, [color_background]
    call get_color
    mov [color_background], bx
    mov si, done_msg ;准备开始游戏
    call print_string 
    call wait_key ;等待任意键
    mov ah, 0x00   ; 设置视频模式
    mov al, 13h 
    int 10h
    ; 设置视频模式
    mov ah, 0x00
    mov al, 13h
    int 10h
    mov word [speed_up_counter], 12000
    ; 初始化帧计数器
    mov word [frame_counter], 0 
main_loop:
    cmp word [frame_counter], 0
    je main_loop        ; 等待下一帧
    mov word [frame_counter], 0  ; 清零计数器
    ; --- 游戏逻辑 ---
    call clean_img
    call draw_score
    call draw_paddle
    call draw_enemy
    call draw_ball
    call get_key
    mov ax, [speed_up_counter]
    cmp ax, 0
    je .speed_up
    dec ax
    jmp .speed_up_end
.speed_up:
    inc word [speed_ball]
    mov word [speed_up_counter], 12000
.speed_up_end:
    call get_key
    cmp al, 11h
    je .move_up
    cmp al, 1Fh
    je .move_down
    jmp .end_input
.move_up:
    mov ax, [paddle_y]
    dec ax
    mov [paddle_y], ax
    jmp .end_input
.move_down:
    mov ax, [paddle_y]
    inc ax
    mov [paddle_y], ax
.end_input:
    call get_key
    cmp al, 48h
    je .move_up_enemy
    cmp al, 50h
    je .move_down_enemy
    jmp .end_enemy
.move_up_enemy:
    mov ax, [enemy_y]
    dec ax
    mov [enemy_y], ax
    jmp .end_enemy
.move_down_enemy:
    mov ax, [enemy_y]
    inc ax
    mov [enemy_y], ax
.end_enemy:
    call update_sound
    call update_ball
.end_loop:
    jmp main_loop
draw_score:
    mov word [draw_square_x], 0
    mov word [draw_square_y], 0
    mov word [draw_square_w], 5
    mov word [draw_square_h], 5
    mov cx, [score]
    call draw_square
    ret 
draw_ball:
    mov word [draw_square_w], 5
    mov word [draw_square_h], 5
    mov ax, [ball_x]
    mov [draw_square_x], ax
    mov ax, [ball_y]
    mov [draw_square_y], ax
    mov ax, [color_ball]
    mov cx, [color_ball]
    call draw_square
    ret
draw_paddle:
    mov word [draw_square_w], 5
    mov word [draw_square_h], 50
    mov word [draw_square_x], 0
    mov ax, [paddle_y]
    mov [draw_square_y], ax
    mov cx, [color_paddle]
    call draw_square
    ret
draw_enemy:
    mov word [draw_square_w], 5
    mov word [draw_square_h], 50
    mov word [draw_square_x], 315
    mov ax, [enemy_y]
    mov word [draw_square_y], ax
    mov cx, [color_enemy]
    call draw_square
    ret
draw_square:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di, 0          ; 水平循环计数
.loop2:                ; 绘制宽度 3
    mov dx, 0          ; 垂直循环计数
.loop1:                ; 绘制高度 50
    push ax
    push bx
    mov ax, di         ; x偏移
    add ax, [draw_square_x]
    mov bx, dx
    add bx, [draw_square_y] ; y偏移
    call draw_pixel
    pop bx
    pop ax

    inc dx
    cmp dx, [draw_square_h]
    jl .loop1

    inc di
    cmp di, [draw_square_w]
    jl .loop2
    mov word [draw_square_x], 0
    mov word [draw_square_y], 0
    mov word [draw_square_w], 0
    mov word [draw_square_h], 0
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

update_ball:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, [ball_x]       ; 当前球坐标 X
    mov bx, [ball_y]       ; 当前球坐标 Y
    mov cx, [speed_ball]   ; 球速度
    mov dl, [dir_ball]     ; 球方向

    ; --- 根据方向更新 X 坐标 ---
    cmp dl, 0
    je .left
    cmp dl, 1
    je .right
    cmp dl, 2
    je .left
    cmp dl, 3
    je .right

.left:
    sub ax, cx            ; 有符号减
    jmp .y_update
.right:
    add ax, cx            ; 有符号加
    jmp .y_update

.y_update:
    cmp dl, 0
    je .up
    cmp dl, 1
    je .up
    cmp dl, 2
    je .down
    cmp dl, 3
    je .down

.up:
    sub bx, cx            ; 有符号减
    jmp .done
.down:
    add bx, cx            ; 有符号加
    jmp .done

.done:
    mov [ball_x], ax
    mov [ball_y], bx

    ; --- Y 边界检查（有符号） ---
    mov ax, [ball_y]
    cmp ax, 4
    jl .ball_y_at_0       ; 小于 4，顶部反弹
    cmp ax, 195
    jg .ball_y_at_bottom  ; 大于 195，底部反弹
    jmp .end_bouncey_check_no_sound

.ball_y_at_0:
    add word [dir_ball], 2   ; 改变方向
    jmp .end_bouncey_check
.ball_y_at_bottom:
    sub word [dir_ball], 2
.end_bouncey_check:
    mov word [sound_delay], 10
    mov word [sound_tune], 2000
.end_bouncey_check_no_sound:
    ; --- 碰撞球拍 ---
    mov ax, [ball_y]
    cmp ax, [paddle_y]
    jl .check_enemy       ; 球在球拍上方 -> 不碰撞

    mov bx, [paddle_y]
    add bx, 50
    cmp ax, bx
    jg .check_enemy       ; 球在球拍下方 -> 不碰撞

    ; Y 在球拍范围内，检查 X
.left_paddle_x_check:
    mov ax, [ball_x]
    cmp ax, 5
    jg .check_enemy       ; 球还没到球拍

.left_paddle_collide:
    add word [dir_ball], 1      ; 碰撞，改变方向
    mov word [sound_tune], 1000
    jmp .end_bouncex_check
.check_enemy:
    mov ax, [ball_x]
    cmp ax, 305
    jl .end_bouncex_check
    mov ax, [ball_y]
    mov bx, [enemy_y]
    cmp ax, bx
    jl .end_bouncex_check
    add bx, 50
    cmp ax, bx
    jg .end_bouncex_check
.right_paddle_collide:
    sub word [dir_ball], 1      ; 碰撞，改变方向
    mov word [sound_delay], 10
    mov word [sound_tune], 1000
.end_bouncex_check:
    ; --- 得分处理（允许负数） ---
    mov ax, [ball_x]
    cmp ax, 0
    jl .sub_score               ; X < 0，玩家失分
    cmp ax, 315
    jg .add_score               ; X > 315，玩家加分
    jmp .not_reset_ball

.sub_score:
    mov ax, [score]
    sub ax, 1                   ; 有符号减
    mov [score], ax
    jmp .reset_ball

.add_score:
    mov ax, [score]
    add ax, 1                   ; 有符号加
    mov [score], ax
    jmp .reset_ball

.reset_ball:
    mov word [ball_x], 160
    mov word [ball_y], 100
    mov word [dir_ball], 0
.not_reset_ball:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
; -------------------------------
; sound_tune  DW 频率 (Hz)
; sound_delay DW 持续时间循环计数
; -------------------------------
update_sound:
play_sound:
    push ax
    push bx
    push cx
    push dx

    mov bx, [sound_tune]     ; 目标频率
    cmp bx, 0
    je .no_sound             ; 频率为0则不发声

    ; 计算 PIT divisor
    mov dx, 0x12      ; 高 16 位
    mov ax, 0x34DC    ; 低 16 位
    ; mov ax, 1193180          ; PIT 时钟频率
    cwd                      ; 扩展到 DX:AX
    idiv bx                  ; AX = 1193180 / frequency

    ; 设置 PIT 通道 2
    mov dx, 0x43
    mov al, 0xB6             ; 通道2, 方波模式3, 低字节/高字节
    out dx, al

    mov dx, 0x42             ; 通道2数据端口
    mov al, al               ; AX低字节
    out dx, al
    mov al, ah               ; AX高字节
    out dx, al

    ; 延迟播放
    mov cx, [sound_delay]
.delay_loop:
    loop .delay_loop

.no_sound:
    ; 停止声音
    mov dx, 0x43
    mov al, 0xB0             ; 通道2, 模式0, 禁止方波
    out dx, al

    pop dx
    pop cx
    pop bx
    pop ax
    ret


irq0_handler:
    push ax
    push bx
    push cx

    ; 增加帧计数器
    inc word [frame_counter]

    ; 发送 EOI 给 PIC
    mov al, 20h
    out 20h, al

    pop cx
    pop bx
    pop ax
    iret

get_color:
.loop1:
    ; 计算偏移量
    mov si, bx
    shl si, 1              ; 每个指针 2 字节
    mov si, [color_ptr_list + si]
    call print_string      ; 输出当前颜色

    call wait_key          ; 等待按键
    cmp ah, 1Ch            ; 回车键
    je .done
    cmp ah, 72             ; 上箭头
    je .prev_color
    cmp ah, 80             ; 下箭头
    je .next_color
    jmp .loop1             ; 其他键忽略

.prev_color:
    cmp bx, 0
    je .loop1              ; 防止越界
    dec bx
    jmp .loop1

.next_color:
    cmp bx, 15              ; color_ptr_list 有16个元素 0~15
    je .loop1              ; 防止越界
    inc bx
    jmp .loop1
.done:
    ret
clean_img:
    mov ax, 0xA000
    mov es, ax
    xor di, di          ; DI = 0
    mov al, [color_background]           ; 清屏颜色（0 = 黑色）
    mov cx, 320*200
    rep stosb           ; 用 AL 填充 ES:[DI] 共 CX 次
    ret

clean_scr:
    mov ah, 0x00     ; 设置视频模式
    mov al, 0x03     ; 80x25 彩色文本模式
    int 0x10         ; 调用 BIOS 视频中断
    ret



wait_key:
    mov ah, 0x00
    int 0x16         ; 等待用户按键
    ret
wait_key_up:
.loop1:
    mov ah, 0x01
    int 0x16
    jnz .loop1        ; 如果 ZF=1 → 没有键按下
    ret
get_key:
    ; mov ah, 01h       ; 检查键盘缓冲区
    ; int 16h
    ; jz .no_key        ; ZF=1 → 没有按键
    in al, 60h         ; 读取扫描码
    ret
.no_key:
    xor ax, ax        ; AL=0, AH=0
    ret


; AX = x, BX = y, CX = color (0~255)
draw_pixel:
    push di          ; 保护 DI  stack[0] = di
    push dx          ; 保护 DX  stack[1] = dx
    push ax          ; stack[2] = AX = x
    mov di, ax
    mov ax, 0xA000
    mov es, ax       ; ES = VGA 显存段
    mov ax, bx       ; AX = BX = y
    mov dx, 320
    mul dx           ; AX = y*320，DX 高位可以忽略
    add ax, di       ; AX = y*320 + x
    mov di, ax       ; DI = 偏移

    mov ax, cx       ; AL = 颜色
    stosb            ; ES:[DI] = AL

    pop ax
    pop dx
    pop di
    ret
print_string:
    mov ah, 0x0E        ; BIOS TTY 输出功能
.print_loop:
    lodsb               ; 从 [SI] 取出下一个字符 → AL
    or al, al           ; 检查是否到字符串结尾（0）
    jz .done
    int 0x10            ; 输出 AL
    jmp .print_loop
.done:
    ret
startup_msg db "Config you pong now!", 10, 13, "Press any key to continue", 10, 13, 10, 13,0
config_msg1 db "What color do you want for your paddle?", 10, 13, 0
config_msg2 db 10, 13, 10, 13,"What color do you want for the other paddle?", 10, 13,0
config_msg3 db 10, 13, 10, 13,"What color do you want for the ball?", 10, 13,0
config_msg4 db 10, 13, 10, 13,"What color do you want for the background?", 10, 13,0
quit_msg    db "Do you really want to quit the game?", 10, 13, "All your progress will lose!", 10, 13, "Press ENTER to shut down", 10, 13, "Press OTHER key to continue gaming", 0
APM_msg    db "Close your PC now", 0
done_msg db 10, 13, 10, 13, "All done!", 10, 13,"Press any key to start your game!", 10, 13,0
color_ptr_list dw color0, color1, color2, color3
               dw color4, color5, color6, color7
               dw color8, color9, colorA, colorB
               dw colorC, colorD, colorE, colorF
color0       db 14 dup(8)
color0_text  db "Black        ", 0
color1       db 14 dup(8)
color1_text  db "Blue         ", 0
color2       db 14 dup(8)
color2_text  db "Green        ", 0
color3       db 14 dup(8)
color3_text  db "Cyan         ", 0
color4       db 14 dup(8)
color4_text  db "Red          ", 0
color5       db 14 dup(8)
color5_text  db "Magenta      ", 0
color6       db 14 dup(8)
color6_text  db "Brown        ", 0
color7       db 14 dup(8)
color7_text  db "Light Gray   ", 0
color8       db 14 dup(8)
color8_text  db "Dark Gray    ", 0
color9       db 14 dup(8)
color9_text  db "Light Blue   ", 0
colorA       db 14 dup(8)
colorA_text  db "Light Green  ", 0
colorB       db 14 dup(8)
colorB_text  db "Light Cyan   ", 0
colorC       db 14 dup(8)
colorC_text  db "Light Red    ", 0
colorD       db 14 dup(8)
colorD_text  db "Light Magenta", 0
colorE       db 14 dup(8)
colorE_text  db "Yellow       ", 0
colorF       db 14 dup(8)
colorF_text  db "White        ", 0
next_line    db 10, 13, 0
;变量
temp dw 0
frame_counter dw 0
speed_up_counter dw 0
old_irq0_offset dw 0
old_irq0_segment dw 0
ball_x   dw 160
ball_y   dw 100
paddle_y   dw 75
enemy_y   dw 75
speed_ball dw 1
dir_ball dw 0
color_paddle dw 0x0F
color_enemy  dw 0x0F
color_ball   dw 0x0F
color_background   dw 0x00
draw_square_w dw 00
draw_square_h dw 00
draw_square_x dw 00
draw_square_y dw 00
score dw 00
sound_delay dw 00
sound_tune dw 9121, 00
buffer dw 320*200 dup(0)
main_end: