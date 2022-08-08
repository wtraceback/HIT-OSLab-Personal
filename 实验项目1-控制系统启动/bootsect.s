SETUPLEN = 2            ! 要读取的扇区数
SETUPSEG = 0x07e0       ! setup 读入内存后的起始地址，这里 bootsect 没有将自己挪动到 0x90000 处，所以setup=0x07e00

entry _start
_start:
    mov ah, #0x03       ! 第 0x10 号中断例程中的 0x03 号子程序，功能为获取光标位置
    xor bh, bh
    int 0x10

    mov cx, #23         ! 显示字符串的长度
    mov bx, #0x0002     ! bh=第 0 页，bl=文字颜色属性 2
    mov bp, #msg1
    mov ax, #0x07c0
    mov es, ax          ! es:bp 是将要显示的字符串的地址
    mov ax, #0x1301     ! ah=13h 写字符串，al=01 移动光标
    int 0x10


load_setup:
    mov dx, #0x0000                 ! dh=磁头号或面号 dl=驱动器号，软驱从0开始，硬盘从80h开始
    mov cx, #0x0002                 ! ch=磁道号 cl=扇区号
    mov bx, #0x0200                 ! es:bx 指向接收从扇区读入数据的内存区
    mov ax, #0x0200 + SETUPLEN      ! ah=int 13h 的功能号(2 表示读扇区) al=读取的扇区数
    int 0x13                        ! int 13h 是 BIOS 提供的访问磁盘的中断例程

    jnc ok_load_setup               ! 读入成功则跳转
    mov dx, #0x0000
    mov ax, #0x0000                 ! 软驱、硬盘有问题时，会复位软驱
    int 0x13
    jmp load_setup                  ! 重新循环，再次尝试读取

ok_load_setup:
    jmpi 0, SETUPSEG                ! 段间跳转指令 ip=0, cs=SETUPSEG


msg1:                   ! len = 3换行 + 3回车 + 字符串长度
    .byte 13, 10        ! 换行 + 回车
    .ascii "WHZ is booting..."
    .byte 13, 10, 13, 10


.org 510
boot_flag:
    .word 0xAA55        ! 设置引导扇区标记 0xAA55
