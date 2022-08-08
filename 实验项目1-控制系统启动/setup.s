INITSEG = 0x9000        ! setup.s 将获得的硬件参数放在内存的 0x90000 处

entry _start
_start:
! 显示字符串 "Now we are in SETUP"
    mov ah, #0x03       ! 第 0x10 号中断例程中的 0x03 号子程序，功能为获取光标位置
    xor bh, bh
    int 0x10

    mov cx, #25         ! 显示字符串的长度
    mov bx, #0x0002     ! bh=第 0 页，bl=文字颜色属性 2
    mov bp, #msg2
    mov ax, cs
    mov es, ax          ! es:bp 是将要显示的字符串的地址
    mov ax, #0x1301     ! ah=13h 写字符串，al=01 移动光标
    int 0x10


! 获取基本硬件参数
    mov ax, #INITSEG
    mov ds, ax          ! 设置 ds = 0x9000

    ! 读取光标的位置并写入 0x90000 处
    mov ah, #0x03       ! 读入光标位置
    xor bh, bh
    int 0x10
    mov [0], dx         ! 将获取的光标位置写入 ds:[0]=0x90000 处

    ! 读取内存大小并写入内存中
    mov ah, #0x88
    int 0x15
    mov [2], ax         ! 将内存大小写入 ds:[2]=0x90002 处

    ! 从 0x41 处拷贝 16 个字节（磁盘参数表）
    ! 在 PC 机中 BIOS 设定的中断向量表中 int 0x41 的中断向量位置(4*0x41 = 0x0000:0x0104)存放的并不是中断程序的地址，而是第一个硬盘的基本参数表。
    mov ax, #0x0000
    mov ds, ax
    lds si, [4 * 0x41]
    mov ax, #INITSEG
    mov es, ax
    mov di, #0x0004
    mov cx, #0x10       ! 重复 16 次，因为每个硬盘参数表有 16 个字节大小。
    rep
    movsb


! 准备打印参数
    mov ax, cs
    mov es, ax
    mov ax, #INITSEG
    mov ds, ax
    mov ss, ax
    mov sp, #0xFF00

    ! 打印光标的位置
    mov ah, #0x03
    xor bh, bh
    int 0x10
    mov cx, #18
    mov bx, #0x0002
    mov bp, #msg_cursor
    mov ax, #0x1301
    int 0x10
    mov dx, [0]
    call print_hex      ! 调用 print_hex 显示信息

    ! 打印内存大小
    mov ah, #0x03
    xor bh, bh
    int 0x10
    mov cx, #14
    mov bx, #0x0002
    mov bp, #msg_memory
    mov ax, #0x1301
    int 0x10
    mov dx, [2]
    call print_hex      ! 调用 print_hex 显示信息
    ! 添加内存单位 KB
    mov ah, #0x03
    xor bh, bh
    int 0x10
    mov cx, #2
    mov bx, #0x0002
    mov bp, #msg_kb
    mov ax, #0x1301
    int 0x10

    ! 打印柱面数
    mov ah, #0x03
    xor bh, bh
    int 0x10
    mov cx, #7
    mov bx, #0x0002
    mov bp, #msg_cyles
    mov ax, #0x1301
    int 0x10
    mov dx, [0x4 + 0x0]
    call print_hex      ! 调用 print_hex 显示信息

    ! 打印磁头数
    mov ah, #0x03
    xor bh, bh
    int 0x10
    mov cx, #8
    mov bx, #0x0002
    mov bp, #msg_heads
    mov ax, #0x1301
    int 0x10
    mov dx, [0x4 + 0x2]
    call print_hex      ! 调用 print_hex 显示信息

    ! 打印扇区
    mov ah, #0x03
    xor bh, bh
    int 0x10
    mov cx, #10
    mov bx, #0x0002
    mov bp, #msg_sectors
    mov ax, #0x1301
    int 0x10
    mov dx, [0x4 + 0x0e]
    call print_hex      ! 调用 print_hex 显示信息
    call print_nl       ! 打印换行回车

inf_loop:
    jmp inf_loop        ! 设置一个无限循环


! 以 16 进制方式打印栈顶的 16 位数
print_hex:
    mov cx, #4          ! 循环的次数，一个 dx 寄存器有 16 位，每 4 位显示一个 ASCII 字符，因此需要循环 4 次
print_digit:
    rol dx, #4          ! 循环左移，将 dx 的高 4 位移到低 4 位处
    mov ax, #0xe0f      ! ah=0x0e为int 0x10的子程序0x0e（显示一个字符串） al=要显示字符的 ASCII 码
    and al, dl          ! 取 dl 的低 4 位，通过与运算放入 al 中
    add al, #0x30       ! 数字 + 0x30 == 对应的 ASCII 码
    cmp al, #0x3a       ! 比较指令，仅对标志寄存器位有影响
    jl outp             ! jl 小于跳转
    add al, #0x07       ! a~f 是 字符 + 0x37 == 对应的 ASCII 码
outp:
    mov bx, #0x0002
    int 0x10
    loop print_digit
    ret
print_nl:
    mov ax, #0xe0d
    int 0x10            ! 打印回车
    mov al, #0xa
    int 0x10            ! 打印换行
    ret


! 提示信息
msg2:                   ! len = 3换行 + 3回车 + 字符串长度
    .byte 13, 10        ! 换行 + 回车
    .ascii "Now we are in SETUP"
    .byte 13, 10, 13, 10
msg_cursor:
    .byte 13, 10
    .ascii "Cursor position:"
msg_memory:
    .byte 13,10
    .ascii "Memory Size:"
msg_kb:
    .ascii "KB"
msg_cyles:
    .byte 13,10
    .ascii "Cyls:"
msg_heads:
    .byte 13,10
    .ascii "Heads:"
msg_sectors:
    .byte 13,10
    .ascii "Sectors:"


.org 510
boot_flag:
    .word 0xAA55
