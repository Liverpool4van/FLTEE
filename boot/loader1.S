%include "boot.inc"
SECTION loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start
;构建GDT及其内部的描述符
    GDT_BASE:       dd 0x00000000                       ;低32位  刚开始的段选择子0不能使用 故用两个双字 来填充
                    dd 0x00000000                       ;高32位

    CODE_DESC:      dd 0x0000FFFF
                    dd DESC_CODE_HIGH4

    STACK_DATA_DESC:
                    dd 0x0000FFFF
                    dd DESC_DATA_HIGH4

    VIDEO_DESC:     dd 0x80000007                       ;limit = (0xbffff-0xb8000) / 4K = 7 低16位表示段界限 高16位表示段基址
                    dd DESC_VIDEO_HIGH4                 ;此处段基址应为0xb8000
                     
    GDT_SIZE        equ $ - GDT_BASE      
    GDT_LIMIT       equ GDT_SIZE - 1

    times 60 dq 0
                                                        ;预留60个四字空间 四字等于64位
    SELECTOR_CODE   equ (0x0001 << 3) + TI_GDT + RPL0   ;这里是选择子
    SELECTOR_DATA   equ (0x0002 << 3) + TI_GDT + RPL0   ;三个部分组成 段描述符索引 + 是否为GDT + 请求优先级
    SELECTOR_VIDEO  equ (0x0003 << 3) + TI_GDT + RPL0

;gdt指针 2字gdt界限放在前面 4字gdt地址放在后面 lgdt 48位格式 低位16位界限 高位32位起始地址
    gdt_ptr         dw  GDT_LIMIT
                    dd  GDT_BASE

    loadermsg       db  '2 loader in real!'

;打印字符串   用中断int 0x10
    loader_start:
        mov sp,LOADER_STACK_TOP
        mov bp,loadermsg                                ;es:bp 指向字符串
        mov cx,17                                       ;cx是字符串的长度
        mov ax,1301
        mov bx,0x001f
        mov dx,0x1800
        int 0x10   

;设置进入保护模式
;1:打开A20
;2:加载gdt
;3:将cr0的pe置1
        in al,0x92                  ;端口号0x92 中 第1位变成1即可
        or al,0000_0010b
        out 0x92,al
   
        lgdt [gdt_ptr]              ;加载gdt指针
    
        mov eax,cr0                 ;cr0寄存器第0位设置位1
        or  eax,0x00000001              
        mov cr0,eax
;刷新流水线
        jmp dword SELECTOR_CODE:p_mode_start 



[bits 32]
    p_mode_start: 
        mov ax,SELECTOR_DATA
        mov ds,ax
        mov es,ax
        mov ss,ax
        mov esp,LOADER_STACK_TOP
        mov ax,SELECTOR_VIDEO
        mov gs,ax
        mov byte [gs:160],'P'


        jmp $        
